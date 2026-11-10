import dotenv from 'dotenv';

dotenv.config();

export interface AppConfig {
  port: number;
  sqlitePath: string;
  vwater: {
    baseUrl: string;
    orgUuid: string;
    username: string;
    password: string;
    targetStationIds: string[];
  };
  vrain: {
    baseUrl: string;
    cityId: number;
  };
  hydro: {
    baseUrl: string;
    token: string;
    serviceId: string;
    stations: Array<{
      loaicongtrinh: number;
      tencongtrinh: number;
      name: string;
      river: string;
    }>;
  };
  thresholds: {
    warning: number;
    danger: number;
    critical: number;
    rapidIncrease: number;
    rainChange: number;
  };
  cronSchedule: string;
}

export const config: AppConfig = {
  port: parseInt(process.env.PORT || '4007', 10),
  sqlitePath: process.env.SQLITE_PATH || 'huewarn.sqlite',
  vwater: {
    baseUrl: process.env.VWATER_BASE_URL || 'https://hue.vfass.vn',
    orgUuid: process.env.VWATER_ORG_UUID || 'a2222302-d07a-4503-93da-e35685565be3',
    username: process.env.VWATER_USERNAME || 'thuathienhue',
    password: process.env.VWATER_PASSWORD || '123456',
    targetStationIds: ['841699255114', '841699255097'],
  },
  vrain: {
    baseUrl: process.env.VRAIN_BASE_URL || 'https://data.vrain.vn',
    cityId: 31,
  },
  hydro: {
    baseUrl: process.env.HYDRO_BASE_URL || 'https://sohoa.hue.gov.vn',
    token: process.env.HYDRO_TOKEN || '04898dfe-cf1b-43e8-9ead-3c6b9f4fc022',
    serviceId: process.env.HYDRO_SERVICE_ID || 'FBuJEaybjjCbAHM+znEEsA==',
    stations: [
      {
        loaicongtrinh: 1,
        tencongtrinh: 1,
        name: 'Thủy điện Hương Điền',
        river: 'Sông Bồ',
      },
      {
        loaicongtrinh: 1,
        tencongtrinh: 2,
        name: 'Thủy điện Bình Điền',
        river: 'Sông Hương',
      },
      {
        loaicongtrinh: 2,
        tencongtrinh: 3,
        name: 'Hồ Tả Trạch',
        river: 'Sông Hương',
      },
    ],
  },
  thresholds: {
    warning: parseFloat(process.env.WATER_LEVEL_WARNING || '2.5'),
    danger: parseFloat(process.env.WATER_LEVEL_DANGER || '3.5'),
    critical: parseFloat(process.env.WATER_LEVEL_CRITICAL || '4.0'),
    rapidIncrease: parseFloat(process.env.RAPID_INCREASE_THRESHOLD || '0.5'),
    rainChange: 1.0,
  },
  cronSchedule: process.env.CRON_SCHEDULE || '*/10 * * * *',
};
