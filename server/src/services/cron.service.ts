import cron, { ScheduledTask } from 'node-cron';
import { AppConfig } from '../config/environment.js';
import { IWaterLevelService } from './water-level.service.js';
import { IRainfallService } from './rainfall.service.js';
import { IHydroElectricService } from './hydro-electric.service.js';
import { INotificationService } from './notification.service.js';
import { AlertNotification } from '../types/index.js';

export interface ICronService {
  start(): void;
  stop(): void;
  evaluateAndNotify(): Promise<AlertNotification | null>;
}

export class CronService implements ICronService {
  private scheduledTask: ScheduledTask | null = null;

  constructor(
    private readonly waterLevelService: IWaterLevelService,
    private readonly rainfallService: IRainfallService,
    private readonly hydroService: IHydroElectricService,
    private readonly notificationService: INotificationService,
    private readonly config: AppConfig
  ) {}

  public start(): void {
    if (this.scheduledTask) {
      return;
    }

    this.scheduledTask = cron.schedule(this.config.cronSchedule, async () => {
      await this.evaluateAndNotify();
    });
  }

  public stop(): void {
    if (this.scheduledTask) {
      this.scheduledTask.stop();
      this.scheduledTask = null;
    }
  }

  public async evaluateAndNotify(): Promise<AlertNotification | null> {
    const waterSummary = await this.waterLevelService.getWaterLevelSummary();

    let title = '';
    let severity: 'info' | 'warning' | 'danger' | 'critical' = 'info';

    if (waterSummary.highestAlertLevel === 3) {
      title = 'CẢNH BÁO MỰC NƯỚC: MỨC BÁO ĐỘNG 3 (KHẨN CẤP)';
      severity = 'critical';
    } else if (waterSummary.highestAlertLevel === 2) {
      title = 'CẢNH BÁO MỰC NƯỚC: MỨC BÁO ĐỘNG 2 (NGUY HIỂM)';
      severity = 'danger';
    } else if (waterSummary.highestAlertLevel === 1) {
      title = 'CẢNH BÁO MỰC NƯỚC: MỨC BÁO ĐỘNG 1';
      severity = 'warning';
    } else if (waterSummary.rapidIncreaseDetected) {
      title = `CẢNH BÁO NƯỚC DÂNG NHANH (≥ ${this.config.thresholds.rapidIncrease}m/giờ)`;
      severity = 'warning';
    }

    if (!title) {
      return null;
    }

    const rainSummary = await this.rainfallService.getRainfallSummary();
    const hydroSummary = await this.hydroService.getHydroSummary();

    const targetStationsText = waterSummary.stations
      .filter((s) => s.isTarget)
      .map((s) => {
        const levelName =
          s.alertLevel === 3
            ? 'BĐ3'
            : s.alertLevel === 2
            ? 'BĐ2'
            : s.alertLevel === 1
            ? 'BĐ1'
            : 'An toàn';
        return `${s.name}: ${s.depth}m (${levelName})`;
      })
      .join(' | ');

    const damText = hydroSummary.dams
      .map((d) => `${d.name}: xả ${d.outFlow}m³/s (${d.outFlowChange >= 0 ? '+' : ''}${d.outFlowChange})`)
      .join(' | ');

    const message = `${targetStationsText}. Mưa: ${rainSummary.summaryText}. Thủy điện: ${damText}`;

    return this.notificationService.dispatchAlert(title, message, severity);
  }
}
