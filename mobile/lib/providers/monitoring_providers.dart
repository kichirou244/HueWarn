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

/// True while a pull-to-refresh is in flight. The previous data stays in
/// [dashboardNotifierProvider], so the UI can show section skeletons instead
/// of falling back to the first-load spinner.
final isRefreshingProvider = NotifierProvider<IsRefreshingNotifier, bool>(() {
  return IsRefreshingNotifier();
});

class IsRefreshingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

class DashboardNotifier extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    final repository = ref.watch(monitoringRepositoryProvider);
    return repository.getDashboard();
  }

  Future<void> refresh() async {
    final refreshing = ref.read(isRefreshingProvider.notifier);
    final previous = state.value;
    refreshing.set(true);
    try {
      final repository = ref.read(monitoringRepositoryProvider);
      state = AsyncValue.data(await repository.getDashboard());
    } catch (error, stackTrace) {
      // Keep the last good data on screen if a refresh fails.
      if (previous != null) {
        state = AsyncValue.data(previous);
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
    } finally {
      refreshing.set(false);
    }
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
