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

      if (response.status !== 200 || !response.data) {
        return null;
      }

      // Legacy shape: { stats: [{ timePoint, stations: [...] }] }
      if (Array.isArray(response.data.stats)) {
        return response.data as RawVWaterResponse;
      }

      // New shape (v3): { ids, stations, rows: [{ t, ts, v: number[] }] }
      // Each row's values are aligned by index with `ids`.
      if (Array.isArray(response.data.rows) && Array.isArray(response.data.ids)) {
        const stationMeta = new Map<
          string,
          { name: string; area: string; waterStationType: string }
        >();
        for (const station of response.data.stations ?? []) {
          if (station?.id) {
            stationMeta.set(station.id, {
              name: station.name ?? station.id,
              area: station.area ?? '',
              waterStationType: station.waterStationType ?? '',
            });
          }
        }

        const ids = response.data.ids as string[];
        const stats: RawVWaterStat[] = (response.data.rows as Array<{
          t: string;
          v?: Array<number | null>;
        }>).map((row) => ({
          timePoint: row.t,
          stations: ids.map((id, index) => {
            const meta = stationMeta.get(id);
            const depth = row.v?.[index];
            return {
              id,
              name: meta?.name ?? id,
              area: meta?.area ?? '',
              depth: depth === null || depth === undefined ? '0' : String(depth),
              waterStationType: meta?.waterStationType ?? '',
            };
          }),
        }));

        return { stats };
      }

      return null;
    } catch {
      return null;
    }
  }

  private async requestStats(dateStr: string, cookie: string) {
    // The detail API moved from /api/vwater/private/v2/... to the legacy
    // gateway at /d/vwater/private/v3/... (same credentials / session cookie).
    return this.axiosInstance.get('/d/vwater/private/v3/stats/details', {
      params: {
        from: dateStr,
        to: dateStr,
        i: '_10m',
      },
      headers: {
        accept: 'application/json, text/plain, */*',
        'accept-language': 'vi',
        cookie,
        referer: `${this.config.vwater.baseUrl}/main/dashboard`,
        'x-org-uuid': this.config.vwater.orgUuid,
        'x-vrain-user-agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36',
      },
    });
  }
}
