import { AppConfig } from '../config/environment.js';
import { IHydroClient, RawHydroRecord } from '../clients/hydro.client.js';
import { IHistoricalRepository, IStateCacheRepository } from '../repositories/interfaces.js';
import { HydroDamData, HydroSummary, HydroTimelinePoint } from '../types/index.js';
import { formatVietnamTime, normalizeUpdatedAt } from '../utils/datetime.js';

export interface IHydroElectricService {
  getHydroSummary(requestedDate?: string): Promise<HydroSummary>;
}

export class HydroElectricService implements IHydroElectricService {
  private readonly prevCacheKey = 'HYDRO_PREV_DATA';
  // Separate from the short-lived fresh cache: this one is only used as a
  // last-known-good fallback when a new day has no measurements yet.
  private readonly lastGoodCacheKey = 'LAST_GOOD_HYDRO_SUMMARY';

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

    const freshCache = await this.cacheRepository.get<HydroSummary>(cacheKey);
    if (freshCache) {
      return normalizeUpdatedAt(freshCache);
    }

    const cached = await this.cacheRepository.get<HydroSummary>(this.lastGoodCacheKey);

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

    // Day rollover: upstream often has no rows for the new day yet. Serve the
    // last complete snapshot rather than showing an empty hydro section.
    if (!isCustomDate && dams.length === 0 && cached && cached.dams.length > 0) {
      return normalizeUpdatedAt(cached);
    }

    if (!isCustomDate && dams.length > 0) {
      await this.cacheRepository.set(this.prevCacheKey, newCache, 86400);
      await this.historicalRepository.saveHydroRecords(dams);

      // Partial refresh: keep dams that have not reported new values yet.
      if (cached && cached.dams.length > dams.length) {
        const seen = new Set(
          dams.map((d) => `${d.loaicongtrinh}_${d.tencongtrinh}`)
        );
        for (const dam of cached.dams) {
          const key = `${dam.loaicongtrinh}_${dam.tencongtrinh}`;
          if (!seen.has(key)) {
            dams.push(dam);
          }
        }
      }

      await this.cacheRepository.set(
        this.lastGoodCacheKey,
        {
          updatedAt: formatVietnamTime(new Date()),
          queryDate: effectiveDate,
          dams,
        },
        12 * 60 * 60
      );
    }

    const summary: HydroSummary = {
      updatedAt: formatVietnamTime(new Date()),
      queryDate: effectiveDate,
      dams,
    };

    // An empty result must not be cached for the normal freshness window;
    // otherwise the app would keep showing "no data" after new rows arrive.
    const ttl = isCustomDate ? 3600 : dams.length > 0 ? 300 : 60;
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
