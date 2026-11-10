import { Request, Response } from 'express';
import { IWaterLevelService } from '../services/water-level.service.js';

export class WaterLevelController {
  constructor(private readonly waterLevelService: IWaterLevelService) {}

  public getSummary = async (_req: Request, res: Response): Promise<void> => {
    try {
      const summary = await this.waterLevelService.getWaterLevelSummary();
      res.json({ success: true, data: summary });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal Server Error';
      res.status(500).json({ success: false, error: message });
    }
  };
}
