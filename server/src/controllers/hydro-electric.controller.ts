import { Request, Response } from 'express';
import { IHydroElectricService } from '../services/hydro-electric.service.js';

export class HydroElectricController {
  constructor(private readonly hydroService: IHydroElectricService) {}

  public getSummary = async (req: Request, res: Response): Promise<void> => {
    try {
      const date = typeof req.query.date === 'string' ? req.query.date : undefined;
      const summary = await this.hydroService.getHydroSummary(date);
      res.json({ success: true, data: summary });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal Server Error';
      res.status(500).json({ success: false, error: message });
    }
  };
}
