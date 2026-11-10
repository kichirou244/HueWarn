import { AppConfig } from '../config/environment.js';
import { IHydroClient, RawHydroRecord } from '../clients/hydro.client.js';
import { IHistoricalRepository, IStateCacheRepository } from '../repositories/interfaces.js';
import { HydroDamData, HydroSummary, HydroTimelinePoint } from '../types/index.js';

export interface IHydroElectricService {
  getHydroSummary(requestedDate?: string): Promise<HydroSummary>;
}

export class HydroElectricService implements IHydroElectricService {
  private readonly prevCacheKey = 'HYDRO_PREV_DATA';

  constructor(
    private readonly hydroClient: IHydroClient,
    private readonly cacheRepository: IStateCacheRepository,
    private readonly historicalRepository: IHistoricalRepository,
    private readonly config: AppConfig
  ) {}

  public async getHydroSummary(requestedDate?: string): Promise<HydroSummary> {
    const isCustomDate = Boolean(requestedDate);
    let targetDateStr = this.normalizeDate(requestedDate);

    const cacheKey = isCustomDate
      ? `HYDRO_SUMMARY_${targetDateStr.replace(/\//g, '_')}`
      : 'LATEST_HYDRO_SUMMARY';

    const cached = await this.cacheRepository.get<HydroSummary>(cacheKey);
    if (cached) {
      return cached;
    }

    const prevCache = await this.cacheRepository.get<Record<string, number>>(this.prevCacheKey);
    const newCache: Record<string, number> = {};

    const dams: HydroDamData[] = [];
    let effectiveDate = targetDateStr;

    for (const station of this.config.hydro.stations) {
      let records = await this.hydroClient.fetchDamRecords(
        station.loaicongtrinh,
        station.tencongtrinh,
        targetDateStr,
        targetDateStr
      );

      if (!isCustomDate && (!records || records.length === 0)) {
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        const yesterdayStr = this.formatDateDDMMYYYY(yesterday);
        records = await this.hydroClient.fetchDamRecords(
          station.loaicongtrinh,
          station.tencongtrinh,
          yesterdayStr,
          yesterdayStr
        );
        if (records && records.length > 0) {
          effectiveDate = yesterdayStr;
        }
      }

      if (records && records.length > 0) {
        const timelineMap = new Map<string, HydroTimelinePoint>();
        for (const r of records) {
          const hour = r.gio ? r.gio.trim() : '';
          if (!hour) continue;
          const waterLevel = parseFloat(r.htl) || 0;
          const inFlow = parseFloat(r.qden) || 0;
          const outFlow = parseFloat(r.qdi) || 0;
          const date = r.ngaylaysolieu || targetDateStr;
          timelineMap.set(hour, {
            hour,
            date,
            timePoint: `${hour} ${date}`.trim(),
            waterLevel,
            inFlow,
            outFlow,
          });
        }

        const timeline = Array.from(timelineMap.values()).sort((a, b) =>
          a.hour.localeCompare(b.hour)
        );

        const latestRaw = this.selectLatestRecord(records);
        const latestFromTimeline = timeline.length > 0 ? timeline[timeline.length - 1] : null;

        const waterLevel = latestFromTimeline
          ? latestFromTimeline.waterLevel
          : parseFloat(latestRaw.htl) || 0;
        const inFlow = latestFromTimeline
          ? latestFromTimeline.inFlow
          : parseFloat(latestRaw.qden) || 0;
        const outFlow = latestFromTimeline
          ? latestFromTimeline.outFlow
          : parseFloat(latestRaw.qdi) || 0;

        const stationKey = `${station.loaicongtrinh}_${station.tencongtrinh}`;
        newCache[stationKey] = outFlow;

        let outFlowChange = 0;
        if (timeline.length >= 2) {
          outFlowChange = Math.round(
            timeline[timeline.length - 1].outFlow - timeline[timeline.length - 2].outFlow
          );
        } else {
          const prevOutFlow = prevCache ? prevCache[stationKey] : undefined;
          outFlowChange = prevOutFlow !== undefined ? Math.round(outFlow - prevOutFlow) : 0;
        }

        dams.push({
          id: latestRaw.id,
          loaicongtrinh: station.loaicongtrinh,
          tencongtrinh: station.tencongtrinh,
          name: latestRaw.tentencongtrinh || station.name,
          river: station.river,
          waterLevel,
          inFlow,
          outFlow,
          outFlowChange,
          recordedAt: latestFromTimeline
            ? latestFromTimeline.timePoint
            : `${latestRaw.gio || ''} ${latestRaw.ngaylaysolieu || ''}`.trim(),
          updatedAt: latestRaw.ngaycapnhat || new Date().toISOString(),
          timeline,
        });
      }
    }

    if (!isCustomDate && dams.length > 0) {
      await this.cacheRepository.set(this.prevCacheKey, newCache, 86400);
      await this.historicalRepository.saveHydroRecords(dams);
    }

    const summary: HydroSummary = {
      updatedAt: new Date().toISOString(),
      queryDate: effectiveDate,
      dams,
    };

    const ttl = isCustomDate ? 3600 : 300;
    await this.cacheRepository.set(cacheKey, summary, ttl);

    return summary;
  }

  private selectLatestRecord(records: RawHydroRecord[]): RawHydroRecord {
    return records.reduce((latest, current) => {
      const latestId = Number(latest.id) || 0;
      const currentId = Number(current.id) || 0;
      return currentId > latestId ? current : latest;
    }, records[0]);
  }

  private normalizeDate(requestedDate?: string): string {
    if (!requestedDate) {
      return this.formatDateDDMMYYYY(new Date());
    }
    const trimmed = requestedDate.trim();
    if (/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) {
      const [y, m, d] = trimmed.split('-');
      return `${d}/${m}/${y}`;
    }
    if (/^\d{1,2}\/\d{1,2}\/\d{4}$/.test(trimmed)) {
      const [d, m, y] = trimmed.split('/');
      return `${d.padStart(2, '0')}/${m.padStart(2, '0')}/${y}`;
    }
    return this.formatDateDDMMYYYY(new Date());
  }

  private formatDateDDMMYYYY(date: Date): string {
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();
    return `${day}/${month}/${year}`;
  }
}
