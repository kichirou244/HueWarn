import { AppConfig } from '../config/environment.js';
import { IVWaterClient, RawVWaterStat } from '../clients/vwater.client.js';
import { IHistoricalRepository, IStateCacheRepository } from '../repositories/interfaces.js';
import { WaterLevelHistoryPoint, WaterLevelSummary, WaterStationData } from '../types/index.js';

export interface IWaterLevelService {
  getWaterLevelSummary(): Promise<WaterLevelSummary>;
}

export class WaterLevelService implements IWaterLevelService {
  constructor(
    private readonly vwaterClient: IVWaterClient,
    private readonly cacheRepository: IStateCacheRepository,
    private readonly historicalRepository: IHistoricalRepository,
    private readonly config: AppConfig
  ) {}

  public async getWaterLevelSummary(): Promise<WaterLevelSummary> {
    const todayStr = this.getFormattedDate(new Date());
    let todayData = await this.vwaterClient.fetchStats(todayStr);

    if (!todayData || !todayData.stats || todayData.stats.length === 0) {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayStr = this.getFormattedDate(yesterday);
      todayData = await this.vwaterClient.fetchStats(yesterdayStr);
    }

    if (!todayData || !todayData.stats || todayData.stats.length === 0) {
      const cached = await this.cacheRepository.get<WaterLevelSummary>('LATEST_WATER_LEVELS');
      if (cached) {
        return cached;
      }
      return {
        updatedAt: new Date().toISOString(),
        highestAlertLevel: 0,
        rapidIncreaseDetected: false,
        maxDepth: 0,
        stations: [],
        history: {},
      };
    }

    const stats = todayData.stats;
    const lastIndex = stats.length - 1;
    const lastStat = stats[lastIndex];

    const prev10mStat = lastIndex >= 1 ? stats[lastIndex - 1] : null;
    const prev1hStat = lastIndex >= 6 ? stats[lastIndex - 6] : null;
    const prev6hStat = lastIndex >= 36 ? stats[lastIndex - 36] : null;

    const prev10mMap = this.createMap(prev10mStat);
    const prev1hMap = this.createMap(prev1hStat);
    const prev6hMap = this.createMap(prev6hStat);

    let maxDepth = 0;
    let highestAlertLevel = 0;
    let rapidIncreaseDetected = false;
    const processedStations: WaterStationData[] = [];
    const historicalRecordsToSave = [];

    const targetSet = new Set(this.config.vwater.targetStationIds);

    for (const station of lastStat.stations) {
      const currentDepth = parseFloat(station.depth) || 0;
      const isTarget = targetSet.has(station.id);

      if (isTarget && currentDepth > maxDepth) {
        maxDepth = currentDepth;
      }

      const prev10m = prev10mMap.get(station.id);
      const prev1h = prev1hMap.get(station.id);
      const prev6h = prev6hMap.get(station.id);

      const change10m =
        prev10m !== undefined ? Math.round((currentDepth - prev10m) * 100) / 100 : null;
      const change1h =
        prev1h !== undefined ? Math.round((currentDepth - prev1h) * 100) / 100 : null;
      const change6h =
        prev6h !== undefined ? Math.round((currentDepth - prev6h) * 100) / 100 : null;

      if (isTarget && change1h !== null && change1h >= this.config.thresholds.rapidIncrease) {
        rapidIncreaseDetected = true;
      }

      const alertLevel = this.calculateStationAlertLevel(station.id, currentDepth);
      if (isTarget && alertLevel > highestAlertLevel) {
        highestAlertLevel = alertLevel;
      }

      processedStations.push({
        id: station.id,
        name: station.name,
        area: station.area || '',
        depth: currentDepth,
        change10m,
        change1h,
        change6h,
        isTarget,
        alertLevel,
      });

      historicalRecordsToSave.push({
        stationId: station.id,
        stationName: station.name,
        area: station.area || '',
        depth: currentDepth,
        change10m,
        change1h,
        change6h,
        alertLevel,
        timePoint: lastStat.timePoint,
        recordedAt: new Date().toISOString(),
      });
    }

    await this.historicalRepository.saveWaterLevelRecords(historicalRecordsToSave);

    processedStations.sort((a, b) => {
      if (a.isTarget && !b.isTarget) return -1;
      if (!a.isTarget && b.isTarget) return 1;
      return b.depth - a.depth;
    });

    const history: Record<string, WaterLevelHistoryPoint[]> = {};
    for (const targetId of this.config.vwater.targetStationIds) {
      const statPoints: WaterLevelHistoryPoint[] = [];
      const recentStats = stats.slice(-24);
      for (const stat of recentStats) {
        const found = stat.stations.find((s) => s.id === targetId);
        if (found) {
          statPoints.push({
            timePoint: stat.timePoint,
            depth: parseFloat(found.depth) || 0,
          });
        }
      }

      if (statPoints.length < 12) {
        const storedHistory = await this.historicalRepository.getWaterLevelHistory(targetId, 24);
        const map = new Map<string, number>();
        for (const p of storedHistory) {
          map.set(p.timePoint, p.depth);
        }
        for (const p of statPoints) {
          map.set(p.timePoint, p.depth);
        }
        history[targetId] = Array.from(map.entries()).map(([timePoint, depth]) => ({
          timePoint,
          depth,
        }));
      } else {
        history[targetId] = statPoints;
      }
    }

    const summary: WaterLevelSummary = {
      updatedAt: lastStat.timePoint,
      highestAlertLevel,
      rapidIncreaseDetected,
      maxDepth,
      stations: processedStations,
      history,
    };

    await this.cacheRepository.set('LATEST_WATER_LEVELS', summary, 600);

    return summary;
  }

  private calculateStationAlertLevel(stationId: string, depth: number): 0 | 1 | 2 | 3 {
    if (stationId === '841699255114') {
      if (depth >= 3.5) return 3;
      if (depth >= 2.0) return 2;
      if (depth >= 1.0) return 1;
      return 0;
    }

    if (stationId === '841699255097') {
      if (depth >= 4.5) return 3;
      if (depth >= 3.0) return 2;
      if (depth >= 1.5) return 1;
      return 0;
    }

    if (depth >= this.config.thresholds.critical) return 3;
    if (depth >= this.config.thresholds.danger) return 2;
    if (depth >= this.config.thresholds.warning) return 1;
    return 0;
  }

  private createMap(stat: RawVWaterStat | null): Map<string, number> {
    const map = new Map<string, number>();
    if (!stat) return map;
    for (const station of stat.stations) {
      map.set(station.id, parseFloat(station.depth) || 0);
    }
    return map;
  }

  private getFormattedDate(date: Date): string {
    const yyyy = date.getFullYear();
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const dd = String(date.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  }
}
