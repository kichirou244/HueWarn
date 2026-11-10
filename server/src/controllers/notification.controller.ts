import { Request, Response } from 'express';
import { INotificationService } from '../services/notification.service.js';
import { ICronService } from '../services/cron.service.js';

export class NotificationController {
  constructor(
    private readonly notificationService: INotificationService,
    private readonly cronService: ICronService
  ) {}

  public register = async (req: Request, res: Response): Promise<void> => {
    try {
      const { token, platform } = req.body;
      if (!token || !platform) {
        res.status(400).json({ success: false, error: 'Token and platform are required' });
        return;
      }

      await this.notificationService.registerDevice(token, platform);
      res.json({ success: true, message: 'Device token registered successfully' });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal Server Error';
      res.status(500).json({ success: false, error: message });
    }
  };

  public unregister = async (req: Request, res: Response): Promise<void> => {
    try {
      const { token } = req.body;
      if (!token) {
        res.status(400).json({ success: false, error: 'Token is required' });
        return;
      }

      await this.notificationService.unregisterDevice(token);
      res.json({ success: true, message: 'Device token unregistered successfully' });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal Server Error';
      res.status(500).json({ success: false, error: message });
    }
  };

  public triggerCron = async (_req: Request, res: Response): Promise<void> => {
    try {
      const alert = await this.cronService.evaluateAndNotify();
      res.json({
        success: true,
        message: alert ? 'Alert evaluated and triggered' : 'Evaluated - conditions normal',
        alert,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal Server Error';
      res.status(500).json({ success: false, error: message });
    }
  };
}
