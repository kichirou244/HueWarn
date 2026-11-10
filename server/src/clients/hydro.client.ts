import axios, { AxiosInstance } from 'axios';
import { AppConfig } from '../config/environment.js';

export interface RawHydroRecord {
  id: number;
  sttbanghi: string;
  chucnang: string;
  tenchucnang: string;
  loaicongtrinh: string;
  tenloaicongtrinh: string;
  tencongtrinh: string;
  tentencongtrinh: string;
  ngaylaysolieu: string;
  gio: string;
  htl: string;
  hhl: string;
  qden: string;
  qdi: string;
  socuamo: string;
  mucnuocsong: string;
  ngaycapnhat?: string;
}

export interface RawHydroResponse {
  code: number;
  message: string;
  data: RawHydroRecord[];
}

export interface IHydroClient {
  fetchDamRecords(
    loaicongtrinh: number,
    tencongtrinh: number,
    fromDateStr: string,
    toDateStr: string
  ): Promise<RawHydroRecord[] | null>;
}

export class HydroClient implements IHydroClient {
  private readonly axiosInstance: AxiosInstance;

  constructor(private readonly config: AppConfig) {
    this.axiosInstance = axios.create({
      baseURL: this.config.hydro.baseUrl,
      timeout: 15000,
      validateStatus: () => true,
    });
  }

  public async fetchDamRecords(
    loaicongtrinh: number,
    tencongtrinh: number,
    fromDateStr: string,
    toDateStr: string
  ): Promise<RawHydroRecord[] | null> {
    try {
      const response = await this.axiosInstance.post<RawHydroResponse>(
        '/data/danhsach',
        {
          serviceid: this.config.hydro.serviceId,
          thamso: {
            tukhoa: '',
            chucnang: 1,
            loaicongtrinh,
            tencongtrinh,
            trangthai: '1',
            tungaylaysolieu: fromDateStr,
            denngaylaysolieu: toDateStr,
          },
          page: 1,
          perpage: '50',
        },
        {
          headers: {
            token: this.config.hydro.token,
            'user-agent': 'HuesReact/356 CFNetwork/1568.200.51 Darwin/24.1.0',
            'Content-Type': 'application/json',
          },
        }
      );

      if (response.status !== 200 || response.data?.code !== 0) {
        return null;
      }

      return response.data.data;
    } catch {
      return null;
    }
  }
}
