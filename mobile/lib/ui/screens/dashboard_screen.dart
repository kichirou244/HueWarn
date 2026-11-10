import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/dashboard_data.dart';
import '../../providers/monitoring_providers.dart';
import '../widgets/header_bar.dart';
import '../widgets/river_water_charts.dart';
import '../widgets/water_level_card.dart';
import '../widgets/rain_chart.dart';
import '../widgets/rain_card.dart';
import '../widgets/single_dam_history_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardNotifierProvider);
    final selectedTab = ref.watch(selectedTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: dashboardAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              error: (error, stack) => _buildErrorView(ref, error.toString()),
              data: (dashboard) {
                final songHuongHistory =
                    dashboard.waterLevels.history['841699255114'] ?? [];
                final songBoHistory =
                    dashboard.waterLevels.history['841699255097'] ?? [];

                final huongStation = dashboard.waterLevels.stations
                    .where((s) => s.id == '841699255114')
                    .firstOrNull;
                final boStation = dashboard.waterLevels.stations
                    .where((s) => s.id == '841699255097')
                    .firstOrNull;

                final huongDepth = huongStation?.depth ??
                    (songHuongHistory.isNotEmpty ? songHuongHistory.last.depth : 0.0);
                final boDepth = boStation?.depth ??
                    (songBoHistory.isNotEmpty ? songBoHistory.last.depth : 0.0);

                final hydroAsync = ref.watch(hydroDamsNotifierProvider);
                final currentDams =
                    hydroAsync.value?.dams ?? dashboard.hydroDams.dams;

                final boDams = currentDams
                    .where((d) =>
                        d.river.contains('Bồ') ||
                        d.name.contains('Hương Điền'))
                    .toList();
                final huongDams =
                    currentDams.where((d) => !boDams.contains(d)).toList();

                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () =>
                      ref.read(dashboardNotifierProvider.notifier).refresh(),
                  child: Column(
                    children: [
                      HeaderBar(
                        updatedAt: dashboard.waterLevels.updatedAt.isNotEmpty
                            ? dashboard.waterLevels.updatedAt
                            : dashboard.timestamp,
                        isLoading: dashboardAsync.isRefreshing,
                        onTriggerCheck: () => ref
                            .read(dashboardNotifierProvider.notifier)
                            .triggerEvaluation(),
                      ),
                      _buildTabSelector(ref, selectedTab),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (selectedTab == 0) ...[
                                _buildQuickSummary(
                                    dashboard, huongDepth, boDepth, boDams, huongDams),
                                const SizedBox(height: 12),
                              ],
                              if (selectedTab == 0 || selectedTab == 1) ...[
                                _buildSectionHeader(
                                    '1. MỰC NƯỚC SÔNG HƯƠNG & SÔNG BỒ',
                                    Icons.water),
                                const SizedBox(height: 10),
                                SongHuongChart(
                                  history: songHuongHistory,
                                  currentDepth: huongDepth,
                                ),
                                SongBoChart(
                                  history: songBoHistory,
                                  currentDepth: boDepth,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'DANH SÁCH CÁC TRẠM ĐO MỰC NƯỚC',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...dashboard.waterLevels.stations
                                    .take(selectedTab == 0
                                        ? 3
                                        : dashboard.waterLevels.stations.length)
                                    .map((s) => WaterLevelCard(station: s)),
                                const SizedBox(height: 16),
                              ],
                              if (selectedTab == 0 || selectedTab == 2) ...[
                                _buildSectionHeader(
                                  '2. LƯỢNG MƯA (${dashboard.rainfall.stations.length} TRẠM HUẾ)',
                                  Icons.cloud_outlined,
                                ),
                                const SizedBox(height: 10),
                                RainChart(stations: dashboard.rainfall.stations),
                                const SizedBox(height: 14),
                                ...dashboard.rainfall.stations
                                    .take(selectedTab == 0
                                        ? 6
                                        : dashboard.rainfall.stations.length)
                                    .map((s) => RainCard(station: s)),
                                if (selectedTab == 0 &&
                                    dashboard.rainfall.stations.length > 6)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 4, bottom: 8),
                                    child: OutlinedButton(
                                      onPressed: () => ref
                                          .read(selectedTabProvider.notifier)
                                          .selectTab(2),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: AppColors.primary),
                                        foregroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Xem toàn bộ ${dashboard.rainfall.stations.length} trạm đo mưa',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                              ],
                              if (selectedTab == 0 || selectedTab == 3) ...[
                                _buildSectionHeader(
                                    '3. HỒ CHỨA & THỦY ĐIỆN THEO LƯU VỰC',
                                    Icons.power_outlined),
                                const SizedBox(height: 10),
                                const HydroDateBar(),
                                const SizedBox(height: 6),
                                if (hydroAsync.isLoading)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          color: AppColors.primary),
                                    ),
                                  )
                                else if (currentDams.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const Text(
                                      'Không có dữ liệu đo đạc thủy điện cho ngày đã chọn',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                else ...[
                                  if (boDams.isNotEmpty) ...[
                                    _buildRiverDamSubheader(
                                        'LƯU VỰC SÔNG BỒ (THỦY ĐIỆN HƯƠNG ĐIỀN)',
                                        AppColors.riverBo),
                                    const SizedBox(height: 8),
                                    ...boDams.map(
                                        (d) => SingleDamHistoryChart(dam: d)),
                                    const SizedBox(height: 12),
                                  ],
                                  if (huongDams.isNotEmpty) ...[
                                    _buildRiverDamSubheader(
                                        'LƯU VỰC SÔNG HƯƠNG (BÌNH ĐIỀN & TẢ TRẠCH)',
                                        AppColors.riverHuong),
                                    const SizedBox(height: 8),
                                    ...huongDams.map(
                                        (d) => SingleDamHistoryChart(dam: d)),
                                  ],
                                ],
                                const SizedBox(height: 24),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiverDamSubheader(String title, Color riverColor) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: riverColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: riverColor,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSummary(
    DashboardData dashboard,
    double huongDepth,
    double boDepth,
    List<dynamic> boDams,
    List<dynamic> huongDams,
  ) {
    final topRain = dashboard.rainfall.stations.isNotEmpty
        ? dashboard.rainfall.stations.first
        : null;

    double boDischarge = 0;
    for (final dam in boDams) {
      boDischarge += (dam.outFlow as num).toDouble();
    }

    double huongDischarge = 0;
    for (final dam in huongDams) {
      huongDischarge += (dam.outFlow as num).toDouble();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Sông Hương (Dã Viên)',
                  value: '${huongDepth.toStringAsFixed(2)}m',
                  subtitle:
                      'Nhận xả: ${huongDischarge.toStringAsFixed(0)} m³/s',
                  accentColor: AppColors.riverHuong,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: 'Sông Bồ (Tứ Phú)',
                  value: '${boDepth.toStringAsFixed(2)}m',
                  subtitle: 'Nhận xả: ${boDischarge.toStringAsFixed(0)} m³/s',
                  accentColor: AppColors.riverBo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Mưa lớn nhất',
                  value: topRain != null
                      ? '${topRain.sumDepth.toStringAsFixed(1)}mm'
                      : '--',
                  subtitle:
                      topRain != null ? topRain.stationName : 'Đang cập nhật',
                  accentColor: AppColors.rainHeavy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: 'Tổng xả các hồ',
                  value:
                      '${(boDischarge + huongDischarge).toStringAsFixed(0)} m³/s',
                  subtitle: 'Hương Điền + Bình Điền + Tả Trạch',
                  accentColor: AppColors.damOutflow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(WidgetRef ref, int selectedTab) {
    final tabs = [
      {'title': 'Tổng quan', 'icon': Icons.dashboard_outlined},
      {'title': 'Mực nước', 'icon': Icons.water},
      {'title': 'Lượng mưa', 'icon': Icons.cloud_outlined},
      {'title': 'Thủy điện', 'icon': Icons.power_outlined},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = selectedTab == index;
            final item = tabs[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () =>
                    ref.read(selectedTabProvider.notifier).selectTab(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 14,
                        color: isSelected
                            ? AppColors.textWhite
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item['title'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.textWhite
                              : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(WidgetRef ref, String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.primary, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Không thể kết nối đến máy chủ giám sát',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(dashboardNotifierProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
