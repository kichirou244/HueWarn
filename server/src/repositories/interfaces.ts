import { AlertNotification, DeviceToken, HydroDamData, RainStationData, WaterLevelHistoryPoint } from '../types/index.js';

export interface IAlertRepository {
  saveAlert(alert: AlertNotification): Promise<void>;
  getRecentAlerts(limit?: number): Promise<AlertNotification[]>;
  clearAlerts(): Promise<void>;
}

export interface IDeviceTokenRepository {
  registerToken(token: string, platform: 'ios' | 'web'): Promise<void>;
  unregisterToken(token: string): Promise<void>;
  getAllTokens(): Promise<DeviceToken[]>;
}

export interface IStateCacheRepository {
  get<T>(key: string): Promise<T | null>;
  set<T>(key: string, value: T, ttlSeconds?: number): Promise<void>;
  delete(key: string): Promise<void>;
}

export interface HistoricalWaterRecord {
  stationId: string;
  stationName: string;
  area: string;
  depth: number;
  change10m: number | null;
  change1h: number | null;
  change6h: number | null;
  alertLevel: number;
  timePoint: string;
  recordedAt: string;
}

export interface IHistoricalRepository {
  saveWaterLevelRecords(records: HistoricalWaterRecord[]): Promise<void>;
  getWaterLevelHistory(stationId: string, limit?: number): Promise<WaterLevelHistoryPoint[]>;
  saveRainfallRecords(records: RainStationData[], updatedAt: string): Promise<void>;
  saveHydroRecords(records: HydroDamData[]): Promise<void>;
}
