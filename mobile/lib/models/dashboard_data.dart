import 'water_station.dart';
import 'rain_data.dart';
import 'hydro_dam.dart';
import 'alert_notification.dart';

class DashboardData {
  final WaterLevelSummary waterLevels;
  final RainSummary rainfall;
  final HydroSummary hydroDams;
  final List<AlertNotification> recentAlerts;
  final String timestamp;

  const DashboardData({
    required this.waterLevels,
    required this.rainfall,
    required this.hydroDams,
    required this.recentAlerts,
    required this.timestamp,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      waterLevels: WaterLevelSummary.fromJson(
        json['waterLevels'] as Map<String, dynamic>? ?? {},
      ),
      rainfall: RainSummary.fromJson(
        json['rainfall'] as Map<String, dynamic>? ?? {},
      ),
      hydroDams: HydroSummary.fromJson(
        json['hydroDams'] as Map<String, dynamic>? ?? {},
      ),
      recentAlerts: (json['recentAlerts'] as List<dynamic>?)
              ?.map((e) => AlertNotification.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
}
