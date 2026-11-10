import express, { Express } from 'express';
import cors from 'cors';
import { config } from './config/environment.js';
import { SqliteDatabase } from './database/sqlite.js';
import { VWaterClient } from './clients/vwater.client.js';
import { VRainClient } from './clients/vrain.client.js';
import { HydroClient } from './clients/hydro.client.js';
import {
  SqliteAlertRepository,
  SqliteDeviceTokenRepository,
  SqliteHistoricalRepository,
  SqliteStateCacheRepository,
} from './repositories/sqlite.repository.js';
import { WaterLevelService } from './services/water-level.service.js';
import { RainfallService } from './services/rainfall.service.js';
import { HydroElectricService } from './services/hydro-electric.service.js';
import { NotificationService } from './services/notification.service.js';
import { CronService } from './services/cron.service.js';
import { WaterLevelController } from './controllers/water-level.controller.js';
import { RainfallController } from './controllers/rainfall.controller.js';
import { HydroElectricController } from './controllers/hydro-electric.controller.js';
import { DashboardController } from './controllers/dashboard.controller.js';
import { AlertController } from './controllers/alert.controller.js';
import { NotificationController } from './controllers/notification.controller.js';
import { createApiRouter } from './routes/api.routes.js';

export interface AppInstance {
  app: Express;
  cronService: CronService;
  sqliteDb: SqliteDatabase;
}

export function createApp(): AppInstance {
  const app = express();

  app.use(cors());
  app.use(express.json());

  const sqliteDb = new SqliteDatabase(config.sqlitePath);
  const cacheRepository = new SqliteStateCacheRepository(sqliteDb);
  const alertRepository = new SqliteAlertRepository(sqliteDb);
  const deviceTokenRepository = new SqliteDeviceTokenRepository(sqliteDb);
  const historicalRepository = new SqliteHistoricalRepository(sqliteDb);

  const vwaterClient = new VWaterClient(config);
  const vrainClient = new VRainClient(config);
  const hydroClient = new HydroClient(config);

  const waterLevelService = new WaterLevelService(
    vwaterClient,
    cacheRepository,
    historicalRepository,
    config
  );
  const rainfallService = new RainfallService(
    vrainClient,
    cacheRepository,
    historicalRepository,
    config
  );
  const hydroService = new HydroElectricService(
    hydroClient,
    cacheRepository,
    historicalRepository,
    config
  );
  const notificationService = new NotificationService(alertRepository, deviceTokenRepository);

  const cronService = new CronService(
    waterLevelService,
    rainfallService,
    hydroService,
    notificationService,
    config
  );

  const waterLevelController = new WaterLevelController(waterLevelService);
  const rainfallController = new RainfallController(rainfallService);
  const hydroController = new HydroElectricController(hydroService);
  const dashboardController = new DashboardController(
    waterLevelService,
    rainfallService,
    hydroService,
    notificationService
  );
  const alertController = new AlertController(notificationService);
  const notificationController = new NotificationController(notificationService, cronService);

  const apiRouter = createApiRouter({
    waterLevelController,
    rainfallController,
    hydroController,
    dashboardController,
    alertController,
    notificationController,
  });

  app.use('/api', apiRouter);

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  return { app, cronService, sqliteDb };
}
