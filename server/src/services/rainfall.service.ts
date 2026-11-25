import { AppConfig } from '../config/environment.js';
import { IVRainClient, RawVRainStationEntry } from '../clients/vrain.client.js';
import { IHistoricalRepository, IStateCacheRepository } from '../repositories/interfaces.js';
import { RainStationData, RainSummary } from '../types/index.js';
import { formatVietnamTime, normalizeUpdatedAt } from '../utils/datetime.js';

export interface IRainfallService {
  getRainfallSummary(): Promise<RainSummary>;
}

export class RainfallService implements IRainfallService {
  private readonly cacheKey = 'PREVIOUS_RAIN_DATA';

  constructor(
    private readonly vrainClient: IVRainClient,
    private readonly cacheRepository: IStateCacheRepository,
    private readonly historicalRepository: IHistoricalRepository,
    private readonly config: AppConfig
  ) {}

  public async getRainfallSummary(): Promise<RainSummary> {
    // Last known good snapshot survives upstream outages / day rollovers.
    const cached = await this.cacheRepository.get<RainSummary>('LATEST_RAIN_SUMMARY');
    const response = await this.vrainClient.fetchCityRain(this.config.vrain.cityId);

    if (!response || !response.entries || response.entries.length === 0) {
      if (cached && cached.stations.length > 0) {
        return normalizeUpdatedAt(cached);
      }
      return {
        updatedAt: formatVietnamTime(new Date()),
        cityId: this.config.vrain.cityId,
        stations: [],
        hasSignificantChanges: false,
        summaryText: 'Không có dữ liệu lượng mưa',
      };
    }

    const prevCache = await this.cacheRepository.get<Record<string, number>>(this.cacheKey);
    const newCache: Record<string, number> = {};

    let significantCount = 0;
    let totalChangeCount = 0;

    const stations: RainStationData[] = response.entries.map((entry: RawVRainStationEntry) => {
      const uuid = entry.station.uuid;
      const sumDepth =
        typeof entry.sumDepth === 'number'
          ? entry.sumDepth
          : parseFloat(String(entry.sumDepth)) || 0;
      newCache[uuid] = sumDepth;

      const prevDepth = prevCache ? prevCache[uuid] : undefined;
      const difference =
        prevDepth !== undefined ? Math.round((sumDepth - prevDepth) * 10) / 10 : 0;

      if (Math.abs(difference) >= 0.1) {
        totalChangeCount++;
        if (Math.abs(difference) >= this.config.thresholds.rainChange) {
          significantCount++;
        }
      }

      return {
        stationId: uuid,
        stationName: entry.station.name,
        area: entry.station.area?.name || '',
        sumDepth,
        level: entry.level || 'Không mưa',
        difference,
      };
    });

    // If the source has only partially refreshed, keep stations from the last
    // good snapshot instead of showing an almost-empty rain section.
    if (cached && cached.stations.length > stations.length) {
      const seen = new Set(stations.map((s) => s.stationId));
      for (const station of cached.stations) {
        if (!seen.has(station.stationId)) {
          stations.push(station);
          newCache[station.stationId] = station.sumDepth;
        }
      }
    }

    stations.sort((a, b) => b.sumDepth - a.sumDepth);

    await this.cacheRepository.set(this.cacheKey, newCache, 86400);

    let summaryText = 'Không có thay đổi về lượng mưa';
    if (significantCount > 0) {
      summaryText = `${significantCount} trạm có thay đổi lượng mưa đáng kể (≥${this.config.thresholds.rainChange}mm)`;
    } else if (totalChangeCount > 0) {
      summaryText = `${totalChangeCount} trạm có lượng mưa thay đổi nhẹ`;
    }

    const updatedAt = formatVietnamTime(response.lastModified ?? new Date());
    await this.historicalRepository.saveRainfallRecords(stations, updatedAt);

    const summary: RainSummary = {
      updatedAt,
      cityId: this.config.vrain.cityId,
      stations,
      hasSignificantChanges: significantCount > 0,
      summaryText,
    };

    await this.cacheRepository.set('LATEST_RAIN_SUMMARY', summary, 12 * 60 * 60);

    return summary;
  }
}
