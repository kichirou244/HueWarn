import axios, { AxiosInstance } from 'axios';
import { AppConfig } from '../config/environment.js';

export interface RawVWaterStation {
  id: string;
  name: string;
  area: string;
  depth: string;
  waterStationType: string;
}

export interface RawVWaterStat {
  timePoint: string;
  stations: RawVWaterStation[];
}

export interface RawVWaterResponse {
  stats: RawVWaterStat[];
}

export interface IVWaterClient {
  fetchStats(dateStr: string): Promise<RawVWaterResponse | null>;
}

export class VWaterClient implements IVWaterClient {
  private readonly axiosInstance: AxiosInstance;
  private cookie: string | null = null;

  constructor(private readonly config: AppConfig) {
    this.axiosInstance = axios.create({
      baseURL: this.config.vwater.baseUrl,
      timeout: 15000,
      validateStatus: () => true,
    });
  }

  private async login(): Promise<string | null> {
    try {
      const response = await this.axiosInstance.post(
        '/api/public/v2/login',
        {
          fromMobile: false,
          orgUuid: this.config.vwater.orgUuid,
          password: this.config.vwater.password,
          username: this.config.vwater.username,
        },
        {
          headers: {
            referer: `${this.config.vwater.baseUrl}/login`,
            'x-org-uuid': this.config.vwater.orgUuid,
            'Content-Type': 'application/json',
          },
        }
      );

      if (response.status !== 200) {
        return null;
      }

      const setCookieHeader = response.headers['set-cookie'];
      if (!setCookieHeader) {
        return null;
      }

      const cookieEntry = Array.isArray(setCookieHeader)
        ? setCookieHeader.find((item) => item.startsWith('sid='))
        : setCookieHeader;

      if (!cookieEntry) {
        return null;
      }

      this.cookie = cookieEntry.split(';')[0];
      return this.cookie;
    } catch {
      return null;
    }
  }

  public async fetchStats(dateStr: string): Promise<RawVWaterResponse | null> {
    if (!this.cookie) {
      const loggedInCookie = await this.login();
      if (!loggedInCookie) {
        return null;
      }
    }

    try {
      let response = await this.requestStats(dateStr, this.cookie!);

      if (response.status === 401) {
        const freshCookie = await this.login();
        if (!freshCookie) {
          return null;
        }
        response = await this.requestStats(dateStr, freshCookie);
      }

      if (response.status !== 200 || !response.data?.stats) {
        return null;
      }

      return response.data as RawVWaterResponse;
    } catch {
      return null;
    }
  }

  private async requestStats(dateStr: string, cookie: string) {
    return this.axiosInstance.get('/api/vwater/private/v2/stats/details', {
      params: {
        from: dateStr,
        to: dateStr,
        i: '_10m',
      },
      headers: {
        cookie,
        referer: `${this.config.vwater.baseUrl}/main/detail/vfass`,
        'x-org-uuid': this.config.vwater.orgUuid,
      },
    });
  }
}
