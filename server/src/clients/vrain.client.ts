import axios, { AxiosInstance } from 'axios';
import { AppConfig } from '../config/environment.js';

export interface RawVRainStationEntry {
  color: string;
  level: string;
  sumDepth: number;
  station: {
    uuid: string;
    name: string;
    lat: number;
    lng: number;
    address: string;
    area: {
      id: number;
      name: string;
      type: string;
      codeName: string;
    };
    city: {
      id: number;
      name: string;
      type: string;
      codeName: string;
    };
  };
}

export interface IVRainClient {
  fetchCityRain(cityId?: number): Promise<{ entries: RawVRainStationEntry[]; lastModified: string | null } | null>;
}

export class VRainClient implements IVRainClient {
  private readonly axiosInstance: AxiosInstance;

  constructor(private readonly config: AppConfig) {
    this.axiosInstance = axios.create({
      baseURL: this.config.vrain.baseUrl,
      timeout: 15000,
      validateStatus: () => true,
    });
  }

  public async fetchCityRain(cityId: number = 31): Promise<{ entries: RawVRainStationEntry[]; lastModified: string | null } | null> {
    try {
      const response = await this.axiosInstance.get(`/public/current/${cityId}.json`, {
        headers: {
          accept: 'application/json, text/plain, */*',
          'accept-language': 'vi',
          'cache-control': 'no-cache, no-store, must-revalidate',
          pragma: 'no-cache',
          'x-vrain-user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/157.0.0.0 Safari/537.36',
          Referer: 'https://vrain.vn/',
        },
      });

      if (response.status !== 200 || !Array.isArray(response.data)) {
        return null;
      }

      const lastModified = (response.headers['last-modified'] || response.headers['Last-Modified'] || null) as string | null;
      return {
        entries: response.data as RawVRainStationEntry[],
        lastModified,
      };
    } catch {
      return null;
    }
  }
}
