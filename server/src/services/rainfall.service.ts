import { AppConfig } from '../config/environment.js';
import { IVRainClient, RawVRainStationEntry } from '../clients/vrain.client.js';
import { IHistoricalRepository, IStateCacheRepository } from '../repositories/interfaces.js';
import { RainStationData, RainSummary } from '../types/index.js';

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
    const response = await this.vrainClient.fetchCityRain(this.config.vrain.cityId);

    if (!response || !response.entries || response.entries.length === 0) {
      const cached = await this.cacheRepository.get<RainSummary>('LATEST_RAIN_SUMMARY');
      if (cached) {
        return cached;
      }
      return {
        updatedAt: new Date().toISOString(),
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

    stations.sort((a, b) => b.sumDepth - a.sumDepth);

    await this.cacheRepository.set(this.cacheKey, newCache, 86400);

    let summaryText = 'Không có thay đổi về lượng mưa';
    if (significantCount > 0) {
      summaryText = `${significantCount} trạm có thay đổi lượng mưa đáng kể (≥${this.config.thresholds.rainChange}mm)`;
    } else if (totalChangeCount > 0) {
      summaryText = `${totalChangeCount} trạm có lượng mưa thay đổi nhẹ`;
    }

    const updatedAt = response.lastModified || new Date().toISOString();
    await this.historicalRepository.saveRainfallRecords(stations, updatedAt);

    const summary: RainSummary = {
      updatedAt,
      cityId: this.config.vrain.cityId,
      stations,
      hasSignificantChanges: significantCount > 0,
      summaryText,
    };

    await this.cacheRepository.set('LATEST_RAIN_SUMMARY', summary, 600);

    return summary;
  }
}
