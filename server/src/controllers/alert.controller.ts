import { Request, Response } from 'express';
import { INotificationService } from '../services/notification.service.js';

export class AlertController {
  constructor(private readonly notificationService: INotificationService) {}

  public getAlerts = async (req: Request, res: Response): Promise<void> => {
    try {
      const limit = parseInt(req.query.limit as string, 10) || 20;
      const alerts = await this.notificationService.getAlerts(limit);
      res.json({ success: true, data: alerts });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal Server Error';
      res.status(500).json({ success: false, error: message });
    }
  };
}
