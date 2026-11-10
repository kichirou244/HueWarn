import { Request, Response } from 'express';
import { IRainfallService } from '../services/rainfall.service.js';

export class RainfallController {
  constructor(private readonly rainfallService: IRainfallService) {}

  public getSummary = async (_req: Request, res: Response): Promise<void> => {
    try {
      const summary = await this.rainfallService.getRainfallSummary();
      res.json({ success: true, data: summary });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal Server Error';
      res.status(500).json({ success: false, error: message });
    }
  };
}
