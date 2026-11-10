import { randomUUID } from 'crypto';
import { IAlertRepository, IDeviceTokenRepository } from '../repositories/interfaces.js';
import { AlertNotification } from '../types/index.js';

export interface INotificationService {
  dispatchAlert(
    title: string,
    message: string,
    severity: 'info' | 'warning' | 'danger' | 'critical'
  ): Promise<AlertNotification>;
  getAlerts(limit?: number): Promise<AlertNotification[]>;
  registerDevice(token: string, platform: 'ios' | 'web'): Promise<void>;
  unregisterDevice(token: string): Promise<void>;
}

export class NotificationService implements INotificationService {
  constructor(
    private readonly alertRepository: IAlertRepository,
    private readonly deviceTokenRepository: IDeviceTokenRepository
  ) {}

  public async dispatchAlert(
    title: string,
    message: string,
    severity: 'info' | 'warning' | 'danger' | 'critical'
  ): Promise<AlertNotification> {
    const alert: AlertNotification = {
      id: randomUUID(),
      title,
      message,
      severity,
      createdAt: new Date().toISOString(),
    };

    await this.alertRepository.saveAlert(alert);

    const tokens = await this.deviceTokenRepository.getAllTokens();
    for (const device of tokens) {
      this.sendToDevice(device.token, alert);
    }

    return alert;
  }

  public async getAlerts(limit: number = 20): Promise<AlertNotification[]> {
    return this.alertRepository.getRecentAlerts(limit);
  }

  public async registerDevice(token: string, platform: 'ios' | 'web'): Promise<void> {
    await this.deviceTokenRepository.registerToken(token, platform);
  }

  public async unregisterDevice(token: string): Promise<void> {
    await this.deviceTokenRepository.unregisterToken(token);
  }

  private sendToDevice(token: string, alert: AlertNotification): void {
    process.stdout.write(
      `[Push Notification] To: ${token.slice(0, 8)}... | ${alert.severity.toUpperCase()} | ${alert.title}\n`
    );
  }
}
