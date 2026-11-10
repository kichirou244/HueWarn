import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/dashboard_data.dart';
import '../models/hydro_dam.dart';
import '../repositories/monitoring_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final monitoringRepositoryProvider = Provider<MonitoringRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiMonitoringRepository(client);
});

class DashboardNotifier extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    final repository = ref.watch(monitoringRepositoryProvider);
    return repository.getDashboard();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(monitoringRepositoryProvider);
      return repository.getDashboard();
    });
  }

  Future<void> triggerEvaluation() async {
    final repository = ref.read(monitoringRepositoryProvider);
    await repository.triggerEvaluation();
    await refresh();
  }
}

final dashboardNotifierProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardData>(() {
  return DashboardNotifier();
});

class SelectedTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int index) {
    state = index;
  }
}

final selectedTabProvider = NotifierProvider<SelectedTabNotifier, int>(() {
  return SelectedTabNotifier();
});

class SelectedWaterStationNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectStation(String? id) {
    state = id;
  }
}

final selectedWaterStationIdProvider =
    NotifierProvider<SelectedWaterStationNotifier, String?>(() {
  return SelectedWaterStationNotifier();
});

class SelectedHydroDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) {
    state = date;
  }

  void previousDay() {
    state = state.subtract(const Duration(days: 1));
  }

  void nextDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(state.year, state.month, state.day);
    if (current.isBefore(today)) {
      state = state.add(const Duration(days: 1));
    }
  }

  void resetToday() {
    state = DateTime.now();
  }
}

final selectedHydroDateProvider =
    NotifierProvider<SelectedHydroDateNotifier, DateTime>(() {
  return SelectedHydroDateNotifier();
});

class HydroDamsNotifier extends AsyncNotifier<HydroSummary> {
  @override
  Future<HydroSummary> build() async {
    final date = ref.watch(selectedHydroDateProvider);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final dateStr = '$day/$month/$year';
    final repository = ref.watch(monitoringRepositoryProvider);
    return repository.getHydroDams(date: dateStr);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final hydroDamsNotifierProvider =
    AsyncNotifierProvider<HydroDamsNotifier, HydroSummary>(() {
  return HydroDamsNotifier();
});
