import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../models/hydro_dam.dart';
import '../../providers/monitoring_providers.dart';

class DamThresholds {
  final double mndbt;
  final double nguongTran;
  final double mnc;

  const DamThresholds({
    required this.mndbt,
    required this.nguongTran,
    required this.mnc,
  });

  static DamThresholds getForDam(String damName) {
    if (damName.contains('Hương Điền')) {
      return const DamThresholds(mndbt: 58.0, nguongTran: 42.75, mnc: 46.0);
    }
    if (damName.contains('Bình Điền')) {
      return const DamThresholds(mndbt: 85.0, nguongTran: 73.0, mnc: 53.0);
    }
    if (damName.contains('Tả Trạch')) {
      return const DamThresholds(mndbt: 45.0, nguongTran: 37.0, mnc: 23.0);
    }
    return const DamThresholds(mndbt: 60.0, nguongTran: 45.0, mnc: 40.0);
  }
}

class HydroDateBar extends ConsumerWidget {
  const HydroDateBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedHydroDateProvider);
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final dateStr =
        '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            onPressed: () =>
                ref.read(selectedHydroDateProvider.notifier).previousDay(),
            tooltip: 'Ngày trước',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2024, 1, 1),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  ref.read(selectedHydroDateProvider.notifier).setDate(picked);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_outlined,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '$dateStr ${isToday ? "(Hôm nay)" : ""}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              size: 22,
              color: isToday
                  ? AppColors.textMuted.withValues(alpha: 0.3)
                  : AppColors.textPrimary,
            ),
            onPressed: isToday
                ? null
                : () => ref.read(selectedHydroDateProvider.notifier).nextDay(),
            tooltip: 'Ngày sau',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          if (!isToday) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: () =>
                  ref.read(selectedHydroDateProvider.notifier).resetToday(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Hôm nay',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SingleDamHistoryChart extends StatelessWidget {
  final HydroDam dam;

  const SingleDamHistoryChart({
    super.key,
    required this.dam,
  });

  @override
  Widget build(BuildContext context) {
    final isBo = dam.river.contains('Bồ') || dam.name.contains('Hương Điền');
    final riverColor = isBo ? AppColors.riverBo : AppColors.riverHuong;
    final riverBg = isBo ? const Color(0xFFDBEAFE) : const Color(0xFFE0F2FE);
    final riverName = isBo ? 'Lưu vực Sông Bồ' : 'Lưu vực Sông Hương';
    final timeline = dam.timeline;
    final thresholds = DamThresholds.getForDam(dam.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: riverColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dam.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: riverBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  riverName,
                  style: TextStyle(
                    color: riverColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (dam.recordedAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Mốc ghi nhận mới nhất: ${dam.recordedAt}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  label: 'Mực nước hồ',
                  value: dam.waterLevel > 0
                      ? '${dam.waterLevel.toStringAsFixed(1)} m'
                      : 'N/A',
                  color: AppColors.primary,
                  bgColor: AppColors.surfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricBox(
                  label: 'Lưu lượng đến',
                  value: '${dam.inFlow.toStringAsFixed(0)} m³/s',
                  color: AppColors.damInflow,
                  bgColor: const Color(0xFFE0F2FE),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricBox(
                  label: 'Lưu lượng xả',
                  value: '${dam.outFlow.toStringAsFixed(0)} m³/s',
                  color: AppColors.damOutflow,
                  bgColor: const Color(0xFFF3E8FF),
                  change: dam.outFlowChange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildThresholdBadge(
                'MNDBT',
                '${thresholds.mndbt.toStringAsFixed(thresholds.mndbt % 1 == 0 ? 0 : 2)}m',
                const Color(0xFFDC2626),
                const Color(0xFFFEE2E2),
              ),
              const SizedBox(width: 6),
              _buildThresholdBadge(
                'Ngưỡng tràn',
                '${thresholds.nguongTran.toStringAsFixed(thresholds.nguongTran % 1 == 0 ? 0 : 2)}m',
                const Color(0xFFD97706),
                const Color(0xFFFEF3C7),
              ),
              const SizedBox(width: 6),
              _buildThresholdBadge(
                'MNC',
                '${thresholds.mnc.toStringAsFixed(thresholds.mnc % 1 == 0 ? 0 : 2)}m',
                const Color(0xFF475569),
                const Color(0xFFF1F5F9),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (timeline.isEmpty)
            Container(
              height: 150,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Không có dữ liệu chuỗi đo đạc cho ngày này',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'MỰC NƯỚC HỒ & CÁC NGƯỠNG AN TOÀN (m)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDotLegend('Mực nước', AppColors.riverHuong),
                    const SizedBox(width: 6),
                    _buildLineLegend('MNDBT', const Color(0xFFDC2626)),
                    const SizedBox(width: 6),
                    _buildLineLegend('Tràn', const Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    _buildLineLegend('MNC', const Color(0xFF64748B)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 145,
              child: _buildWaterLevelChart(timeline, thresholds),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'LƯU LƯỢNG ĐẾN & LƯU LƯỢNG XẢ (m³/s)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDotLegend('Qđến', AppColors.damInflow),
                    const SizedBox(width: 8),
                    _buildDotLegend('Qxả', AppColors.damOutflow),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 145,
              child: _buildFlowChart(timeline),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThresholdBadge(
    String label,
    String value,
    Color textColor,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLineLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    double? change,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (change != null && change.abs() > 0) ...[
                const SizedBox(width: 2),
                Text(
                  '${change > 0 ? "+" : ""}${change.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterLevelChart(
    List<HydroTimelinePoint> timeline,
    DamThresholds thresholds,
  ) {
    double minVal = thresholds.nguongTran < thresholds.mnc
        ? thresholds.nguongTran
        : thresholds.mnc;
    double maxVal = thresholds.mndbt;

    for (final pt in timeline) {
      if (pt.waterLevel > 0) {
        if (pt.waterLevel < minVal) minVal = pt.waterLevel;
        if (pt.waterLevel > maxVal) maxVal = pt.waterLevel;
      }
    }

    final minY = (minVal - 2.0).floorToDouble().clamp(0.0, double.infinity);
    final maxY = (maxVal + 2.0).ceilToDouble();

    final spots = <FlSpot>[];
    for (int i = 0; i < timeline.length; i++) {
      spots.add(FlSpot(i.toDouble(), timeline[i].waterLevel));
    }

    final maxX = (timeline.length > 1 ? timeline.length - 1 : 1).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY > minY ? maxY : minY + 2.0,
        lineTouchData: LineTouchData(
          enabled: true,
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: AppColors.riverHuong.withValues(alpha: 0.6),
                  strokeWidth: 1.5,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4.5,
                    color: Colors.white,
                    strokeWidth: 2.5,
                    strokeColor: AppColors.riverHuong,
                  ),
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF0F172A),
            tooltipBorder:
                const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
            tooltipBorderRadius: BorderRadius.circular(8),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final hour = (idx >= 0 && idx < timeline.length)
                    ? timeline[idx].hour
                    : '';
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(2)} m',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                  children: [
                    TextSpan(
                      text: '\n$hour (Hồ)',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppColors.borderLight,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${value.toStringAsFixed(0)}m',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: maxX > 6 ? (maxX / 4).floorToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= timeline.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    timeline[idx].hour,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: thresholds.mndbt,
              color: const Color(0xFFDC2626),
              strokeWidth: 1.2,
              dashArray: [5, 3],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 6, bottom: 2),
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
                labelResolver: (_) =>
                    'MNDBT: ${thresholds.mndbt.toStringAsFixed(thresholds.mndbt % 1 == 0 ? 0 : 2)}m',
              ),
            ),
            HorizontalLine(
              y: thresholds.nguongTran,
              color: const Color(0xFFD97706),
              strokeWidth: 1.1,
              dashArray: [4, 3],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 6, bottom: 2),
                style: const TextStyle(
                  color: Color(0xFFD97706),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
                labelResolver: (_) =>
                    'Tràn: ${thresholds.nguongTran.toStringAsFixed(thresholds.nguongTran % 1 == 0 ? 0 : 2)}m',
              ),
            ),
            HorizontalLine(
              y: thresholds.mnc,
              color: const Color(0xFF64748B),
              strokeWidth: 1.0,
              dashArray: [3, 3],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 6, bottom: 2),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
                labelResolver: (_) =>
                    'MNC: ${thresholds.mnc.toStringAsFixed(thresholds.mnc % 1 == 0 ? 0 : 2)}m',
              ),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.riverHuong,
            barWidth: 2.4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.riverHuong.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowChart(List<HydroTimelinePoint> timeline) {
    double maxFlow = 200.0;
    for (final pt in timeline) {
      if (pt.inFlow > maxFlow) maxFlow = pt.inFlow;
      if (pt.outFlow > maxFlow) maxFlow = pt.outFlow;
    }
    maxFlow = (maxFlow * 1.15).ceilToDouble();

    final inSpots = <FlSpot>[];
    final outSpots = <FlSpot>[];
    for (int i = 0; i < timeline.length; i++) {
      inSpots.add(FlSpot(i.toDouble(), timeline[i].inFlow));
      outSpots.add(FlSpot(i.toDouble(), timeline[i].outFlow));
    }

    final maxX = (timeline.length > 1 ? timeline.length - 1 : 1).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxFlow,
        lineTouchData: LineTouchData(
          enabled: true,
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: (barData.color ?? AppColors.damInflow)
                      .withValues(alpha: 0.6),
                  strokeWidth: 1.5,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4.5,
                    color: Colors.white,
                    strokeWidth: 2.5,
                    strokeColor: barData.color ?? AppColors.damInflow,
                  ),
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF0F172A),
            tooltipBorder:
                const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
            tooltipBorderRadius: BorderRadius.circular(8),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final hour = (idx >= 0 && idx < timeline.length)
                    ? timeline[idx].hour
                    : '';
                final isOutflow = spot.barIndex == 1;
                final label = isOutflow ? 'Xả' : 'Đến';
                final color = isOutflow
                    ? const Color(0xFFC084FC)
                    : const Color(0xFF38BDF8);

                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(0)} m³/s',
                  TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                  children: [
                    TextSpan(
                      text: ' ($label)\n$hour',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppColors.borderLight,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${value.toInt()}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: maxX > 6 ? (maxX / 4).floorToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= timeline.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    timeline[idx].hour,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: inSpots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.damInflow,
            barWidth: 2.2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.damInflow.withValues(alpha: 0.08),
            ),
          ),
          LineChartBarData(
            spots: outSpots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.damOutflow,
            barWidth: 2.2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.damOutflow.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}
