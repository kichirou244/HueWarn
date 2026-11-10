export interface WaterStationData {
  id: string;
  name: string;
  area: string;
  depth: number;
  change10m: number | null;
  change1h: number | null;
  change6h: number | null;
  isTarget: boolean;
  alertLevel: 0 | 1 | 2 | 3;
}

export interface WaterLevelHistoryPoint {
  timePoint: string;
  depth: number;
}

export interface WaterLevelSummary {
  updatedAt: string;
  highestAlertLevel: number;
  rapidIncreaseDetected: boolean;
  maxDepth: number;
  stations: WaterStationData[];
  history: Record<string, WaterLevelHistoryPoint[]>;
}

export interface RainStationData {
  stationId: string;
  stationName: string;
  area: string;
  sumDepth: number;
  level: string;
  difference: number;
}

export interface RainSummary {
  updatedAt: string;
  cityId: number;
  stations: RainStationData[];
  hasSignificantChanges: boolean;
  summaryText: string;
}

export interface HydroTimelinePoint {
  hour: string;
  date: string;
  timePoint: string;
  waterLevel: number;
  inFlow: number;
  outFlow: number;
}

export interface HydroDamData {
  id: number;
  loaicongtrinh: number;
  tencongtrinh: number;
  name: string;
  river: string;
  waterLevel: number;
  inFlow: number;
  outFlow: number;
  outFlowChange: number;
  recordedAt: string;
  updatedAt: string;
  timeline: HydroTimelinePoint[];
}

export interface HydroSummary {
  updatedAt: string;
  queryDate: string;
  dams: HydroDamData[];
}

export interface AlertNotification {
  id: string;
  title: string;
  message: string;
  severity: 'info' | 'warning' | 'danger' | 'critical';
  createdAt: string;
}

export interface DashboardData {
  waterLevels: WaterLevelSummary;
  rainfall: RainSummary;
  hydroDams: HydroSummary;
  recentAlerts: AlertNotification[];
  timestamp: string;
}

export interface DeviceToken {
  token: string;
  platform: 'ios' | 'web';
  registeredAt: string;
}
