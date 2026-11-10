import { DatabaseSync } from 'node:sqlite';

export class SqliteDatabase {
  private readonly db: DatabaseSync;

  constructor(filePath: string) {
    this.db = new DatabaseSync(filePath);
    this.initPragmas();
    this.createTables();
    this.runMigrations();
  }

  public get connection(): DatabaseSync {
    return this.db;
  }

  private initPragmas(): void {
    this.db.exec('PRAGMA journal_mode = WAL;');
    this.db.exec('PRAGMA synchronous = NORMAL;');
  }

  private createTables(): void {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS alerts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        severity TEXT NOT NULL,
        created_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS device_tokens (
        token TEXT PRIMARY KEY,
        platform TEXT NOT NULL,
        registered_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS state_cache (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        expires_at INTEGER
      );

      CREATE TABLE IF NOT EXISTS water_level_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        station_id TEXT NOT NULL,
        station_name TEXT NOT NULL,
        area TEXT,
        depth REAL NOT NULL,
        change_10m REAL,
        change_1h REAL,
        change_6h REAL,
        alert_level INTEGER NOT NULL,
        time_point TEXT NOT NULL,
        recorded_at TEXT NOT NULL,
        UNIQUE(station_id, time_point)
      );

      CREATE TABLE IF NOT EXISTS rainfall_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        station_id TEXT NOT NULL,
        station_name TEXT NOT NULL,
        area TEXT,
        sum_depth REAL NOT NULL,
        level TEXT NOT NULL,
        difference REAL NOT NULL,
        updated_at TEXT NOT NULL,
        recorded_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS hydro_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dam_id INTEGER NOT NULL,
        loaicongtrinh INTEGER NOT NULL,
        tencongtrinh INTEGER NOT NULL,
        name TEXT NOT NULL,
        river TEXT,
        water_level REAL NOT NULL,
        in_flow REAL NOT NULL,
        out_flow REAL NOT NULL,
        out_flow_change REAL NOT NULL,
        recorded_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        saved_at TEXT NOT NULL,
        UNIQUE(loaicongtrinh, tencongtrinh, recorded_at)
      );
    `);
  }

  private runMigrations(): void {
    try {
      this.db.exec('ALTER TABLE hydro_history ADD COLUMN river TEXT;');
    } catch {}
  }
}
