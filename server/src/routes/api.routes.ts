import { Router } from 'express';
import { WaterLevelController } from '../controllers/water-level.controller.js';
import { RainfallController } from '../controllers/rainfall.controller.js';
import { HydroElectricController } from '../controllers/hydro-electric.controller.js';
import { DashboardController } from '../controllers/dashboard.controller.js';
import { AlertController } from '../controllers/alert.controller.js';
import { NotificationController } from '../controllers/notification.controller.js';

export interface RouteControllers {
  waterLevelController: WaterLevelController;
  rainfallController: RainfallController;
  hydroController: HydroElectricController;
  dashboardController: DashboardController;
  alertController: AlertController;
  notificationController: NotificationController;
}

export function createApiRouter(controllers: RouteControllers): Router {
  const router = Router();

  router.get('/dashboard', controllers.dashboardController.getDashboard);
  router.get('/water-levels', controllers.waterLevelController.getSummary);
  router.get('/rainfall', controllers.rainfallController.getSummary);
  router.get('/dams', controllers.hydroController.getSummary);
  router.get('/alerts', controllers.alertController.getAlerts);

  router.post('/notifications/register', controllers.notificationController.register);
  router.post('/notifications/unregister', controllers.notificationController.unregister);
  router.post('/cron/trigger', controllers.notificationController.triggerCron);

  return router;
}
