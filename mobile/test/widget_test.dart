import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/main.dart';
import 'package:mobile/models/dashboard_data.dart';
import 'package:mobile/models/water_station.dart';
import 'package:mobile/models/rain_data.dart';
import 'package:mobile/models/hydro_dam.dart';
import 'package:mobile/models/alert_notification.dart';
import 'package:mobile/providers/monitoring_providers.dart';
import 'package:mobile/repositories/monitoring_repository.dart';

class FakeMonitoringRepository implements MonitoringRepository {
  @override
  Future<DashboardData> getDashboard({String? date}) async {
    return const DashboardData(
      waterLevels: WaterLevelSummary(
        updatedAt: '12:00 10/11/2026',
        highestAlertLevel: 0,
        rapidIncreaseDetected: false,
        maxDepth: 1.0,
        stations: [],
        history: {},
      ),
      rainfall: RainSummary(
        updatedAt: '12:00 10/11/2026',
        cityId: 31,
        stations: [],
        hasSignificantChanges: false,
        summaryText: '',
      ),
      hydroDams: HydroSummary(
        updatedAt: '12:00 10/11/2026',
        queryDate: '10/11/2026',
        dams: [],
      ),
      recentAlerts: [],
      timestamp: '2026-11-10T12:00:00.000Z',
    );
  }

  @override
  Future<WaterLevelSummary> getWaterLevels() async {
    return const WaterLevelSummary(
      updatedAt: '12:00 10/11/2026',
      highestAlertLevel: 0,
      rapidIncreaseDetected: false,
      maxDepth: 1.0,
      stations: [],
      history: {},
    );
  }

  @override
  Future<RainSummary> getRainfall() async {
    return const RainSummary(
      updatedAt: '12:00 10/11/2026',
      cityId: 31,
      stations: [],
      hasSignificantChanges: false,
      summaryText: '',
    );
  }

  @override
  Future<HydroSummary> getHydroDams({String? date}) async {
    return const HydroSummary(
      updatedAt: '12:00 10/11/2026',
      queryDate: '10/11/2026',
      dams: [],
    );
  }

  @override
  Future<List<AlertNotification>> getAlerts({int limit = 20}) async => [];

  @override
  Future<void> registerDeviceToken(String token, String platform) async {}

  @override
  Future<void> triggerEvaluation() async {}
}

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          monitoringRepositoryProvider.overrideWithValue(FakeMonitoringRepository()),
        ],
        child: const HueWarnApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HueWarnApp), findsOneWidget);
  });
}
