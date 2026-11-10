import '../core/network/api_client.dart';
import '../models/dashboard_data.dart';
import '../models/water_station.dart';
import '../models/rain_data.dart';
import '../models/hydro_dam.dart';
import '../models/alert_notification.dart';

abstract class MonitoringRepository {
  Future<DashboardData> getDashboard({String? date});
  Future<WaterLevelSummary> getWaterLevels();
  Future<RainSummary> getRainfall();
  Future<HydroSummary> getHydroDams({String? date});
  Future<List<AlertNotification>> getAlerts({int limit = 20});
  Future<void> registerDeviceToken(String token, String platform);
  Future<void> triggerEvaluation();
}

class ApiMonitoringRepository implements MonitoringRepository {
  final ApiClient apiClient;

  ApiMonitoringRepository(this.apiClient);

  @override
  Future<DashboardData> getDashboard({String? date}) async {
    final response = await apiClient.dio.get(
      '/dashboard',
      queryParameters: date != null ? {'date': date} : null,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return DashboardData.fromJson(data);
  }

  @override
  Future<WaterLevelSummary> getWaterLevels() async {
    final response = await apiClient.dio.get('/water-levels');
    final data = response.data['data'] as Map<String, dynamic>;
    return WaterLevelSummary.fromJson(data);
  }

  @override
  Future<RainSummary> getRainfall() async {
    final response = await apiClient.dio.get('/rainfall');
    final data = response.data['data'] as Map<String, dynamic>;
    return RainSummary.fromJson(data);
  }

  @override
  Future<HydroSummary> getHydroDams({String? date}) async {
    final response = await apiClient.dio.get(
      '/dams',
      queryParameters: date != null ? {'date': date} : null,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return HydroSummary.fromJson(data);
  }

  @override
  Future<List<AlertNotification>> getAlerts({int limit = 20}) async {
    final response = await apiClient.dio.get('/alerts', queryParameters: {'limit': limit});
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => AlertNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> registerDeviceToken(String token, String platform) async {
    await apiClient.dio.post('/notifications/register', data: {
      'token': token,
      'platform': platform,
    });
  }

  @override
  Future<void> triggerEvaluation() async {
    await apiClient.dio.post('/cron/trigger');
  }
}
