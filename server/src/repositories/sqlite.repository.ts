import { SqliteDatabase } from '../database/sqlite.js';
import {
  AlertNotification,
  DeviceToken,
  HydroDamData,
  RainStationData,
  WaterLevelHistoryPoint,
} from '../types/index.js';
import {
  HistoricalWaterRecord,
  IAlertRepository,
  IDeviceTokenRepository,
  IHistoricalRepository,
  IStateCacheRepository,
} from './interfaces.js';

export class SqliteAlertRepository implements IAlertRepository {
  constructor(private readonly db: SqliteDatabase) {}

  public async saveAlert(alert: AlertNotification): Promise<void> {
    const stmt = this.db.connection.prepare(`
      INSERT OR REPLACE INTO alerts (id, title, message, severity, created_at)
      VALUES (?, ?, ?, ?, ?)
    `);
    stmt.run(alert.id, alert.title, alert.message, alert.severity, alert.createdAt);
  }

  public async getRecentAlerts(limit: number = 20): Promise<AlertNotification[]> {
    const stmt = this.db.connection.prepare(`
      SELECT id, title, message, severity, created_at as createdAt
      FROM alerts
      ORDER BY created_at DESC
      LIMIT ?
    `);
    const rows = stmt.all(limit) as unknown as Array<{
      id: string;
      title: string;
      message: string;
      severity: 'info' | 'warning' | 'danger' | 'critical';
      createdAt: string;
    }>;
    return rows;
  }

  public async clearAlerts(): Promise<void> {
    this.db.connection.exec('DELETE FROM alerts;');
  }
}

export class SqliteDeviceTokenRepository implements IDeviceTokenRepository {
  constructor(private readonly db: SqliteDatabase) {}

  public async registerToken(token: string, platform: 'ios' | 'web'): Promise<void> {
    const stmt = this.db.connection.prepare(`
      INSERT OR REPLACE INTO device_tokens (token, platform, registered_at)
      VALUES (?, ?, ?)
    `);
    stmt.run(token, platform, new Date().toISOString());
  }

  public async unregisterToken(token: string): Promise<void> {
    const stmt = this.db.connection.prepare(`
      DELETE FROM device_tokens WHERE token = ?
    `);
    stmt.run(token);
  }

  public async getAllTokens(): Promise<DeviceToken[]> {
    const stmt = this.db.connection.prepare(`
      SELECT token, platform, registered_at as registeredAt
      FROM device_tokens
    `);
    return stmt.all() as unknown as DeviceToken[];
  }
}

export class SqliteStateCacheRepository implements IStateCacheRepository {
  constructor(private readonly db: SqliteDatabase) {}

  public async get<T>(key: string): Promise<T | null> {
    const stmt = this.db.connection.prepare(`
      SELECT value, expires_at FROM state_cache WHERE key = ?
    `);
    const row = stmt.get(key) as { value: string; expires_at: number | null } | undefined;

    if (!row) {
      return null;
    }

    if (row.expires_at !== null && Date.now() > row.expires_at) {
      await this.delete(key);
      return null;
    }

    try {
      return JSON.parse(row.value) as T;
    } catch {
      return null;
    }
  }

  public async set<T>(key: string, value: T, ttlSeconds?: number): Promise<void> {
    const expiresAt = ttlSeconds ? Date.now() + ttlSeconds * 1000 : null;
    const jsonValue = JSON.stringify(value);
    const stmt = this.db.connection.prepare(`
      INSERT OR REPLACE INTO state_cache (key, value, expires_at)
      VALUES (?, ?, ?)
    `);
    stmt.run(key, jsonValue, expiresAt);
  }

  public async delete(key: string): Promise<void> {
    const stmt = this.db.connection.prepare(`
      DELETE FROM state_cache WHERE key = ?
    `);
    stmt.run(key);
  }
}

export class SqliteHistoricalRepository implements IHistoricalRepository {
  constructor(private readonly db: SqliteDatabase) {}

  public async saveWaterLevelRecords(records: HistoricalWaterRecord[]): Promise<void> {
    const stmt = this.db.connection.prepare(`
      INSERT OR IGNORE INTO water_level_history (
        station_id, station_name, area, depth, change_10m, change_1h, change_6h, alert_level, time_point, recorded_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    for (const r of records) {
      stmt.run(
        r.stationId,
        r.stationName,
        r.area,
        r.depth,
        r.change10m,
        r.change1h,
        r.change6h,
        r.alertLevel,
        r.timePoint,
        r.recordedAt
      );
    }
  }

  public async getWaterLevelHistory(
    stationId: string,
    limit: number = 24
  ): Promise<WaterLevelHistoryPoint[]> {
    const stmt = this.db.connection.prepare(`
      SELECT time_point as timePoint, depth
      FROM water_level_history
      WHERE station_id = ?
      ORDER BY id DESC
      LIMIT ?
    `);
    const rows = stmt.all(stationId, limit) as unknown as WaterLevelHistoryPoint[];
    return rows.reverse();
  }

  public async saveRainfallRecords(records: RainStationData[], updatedAt: string): Promise<void> {
    const recordedAt = new Date().toISOString();
    const stmt = this.db.connection.prepare(`
      INSERT INTO rainfall_history (
        station_id, station_name, area, sum_depth, level, difference, updated_at, recorded_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `);

    for (const r of records) {
      stmt.run(
        r.stationId,
        r.stationName,
        r.area,
        r.sumDepth,
        r.level,
        r.difference,
        updatedAt,
        recordedAt
      );
    }
  }

  public async saveHydroRecords(records: HydroDamData[]): Promise<void> {
    const savedAt = new Date().toISOString();
    const stmt = this.db.connection.prepare(`
      INSERT OR IGNORE INTO hydro_history (
        dam_id, loaicongtrinh, tencongtrinh, name, river, water_level, in_flow, out_flow, out_flow_change, recorded_at, updated_at, saved_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    for (const d of records) {
      stmt.run(
        d.id,
        d.loaicongtrinh,
        d.tencongtrinh,
        d.name,
        d.river,
        d.waterLevel,
        d.inFlow,
        d.outFlow,
        d.outFlowChange,
        d.recordedAt,
        d.updatedAt,
        savedAt
      );
    }
  }
}
