import { Request, Response } from 'express';
import { IWaterLevelService } from '../services/water-level.service.js';
import { IRainfallService } from '../services/rainfall.service.js';
import { IHydroElectricService } from '../services/hydro-electric.service.js';
import { INotificationService } from '../services/notification.service.js';
import { DashboardData } from '../types/index.js';

export class DashboardController {
  constructor(
    private readonly waterLevelService: IWaterLevelService,
    private readonly rainfallService: IRainfallService,
    private readonly hydroService: IHydroElectricService,
    private readonly notificationService: INotificationService
  ) {}

  public getDashboard = async (req: Request, res: Response): Promise<void> => {
    try {
      const date = typeof req.query.date === 'string' ? req.query.date : undefined;
      const [waterLevels, rainfall, hydroDams, recentAlerts] = await Promise.all([
        this.waterLevelService.getWaterLevelSummary(),
        this.rainfallService.getRainfallSummary(),
        this.hydroService.getHydroSummary(date),
        this.notificationService.getAlerts(5),
      ]);

      const dashboard: DashboardData = {
        waterLevels,
        rainfall,
        hydroDams,
        recentAlerts,
        timestamp: new Date().toISOString(),
      };

      res.json({ success: true, data: dashboard });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal Server Error';
      res.status(500).json({ success: false, error: message });
    }
  };
}
