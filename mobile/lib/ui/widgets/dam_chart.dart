import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../models/hydro_dam.dart';

class DamChart extends StatelessWidget {
  final List<HydroDam> dams;

  const DamChart({
    super.key,
    required this.dams,
  });

  @override
  Widget build(BuildContext context) {
    if (dams.isEmpty) {
      return Container(
        height: 190,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Đang cập nhật số liệu lưu lượng thủy điện...',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    double maxFlow = 500.0;
    for (final dam in dams) {
      if (dam.inFlow > maxFlow) maxFlow = dam.inFlow;
      if (dam.outFlow > maxFlow) maxFlow = dam.outFlow;
    }
    maxFlow = (maxFlow * 1.15).ceilToDouble();

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < dams.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 6,
          barRods: [
            BarChartRodData(
              toY: dams[i].inFlow,
              color: AppColors.damInflow,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: dams[i].outFlow,
              color: AppColors.damOutflow,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Container(
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
            children: [
              const Expanded(
                child: Text(
                  'LƯU LƯỢNG ĐẾN / XẢ (m³/s)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
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
                  _buildLegendDot('Đến (Qđến)', AppColors.damInflow),
                  const SizedBox(width: 8),
                  _buildLegendDot('Xả (Qđi)', AppColors.damOutflow),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxFlow,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    tooltipBorder: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                    tooltipBorderRadius: BorderRadius.circular(8),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dam = dams[group.x];
                      final isOutflow = rodIndex == 1;
                      final type = isOutflow ? 'Xả (Qđi)' : 'Đến (Qđến)';
                      final val = rod.toY.toStringAsFixed(0);
                      return BarTooltipItem(
                        '${dam.name}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          TextSpan(
                            text: '$type: $val m³/s',
                            style: TextStyle(
                              color: isOutflow ? const Color(0xFFC084FC) : const Color(0xFF38BDF8),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      );
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
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${value.toInt()}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
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
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dams.length) {
                          return const SizedBox.shrink();
                        }
                        final dam = dams[idx];
                        String damLabel = 'Hương Điền';
                        String riverLabel = '(S. Bồ)';
                        if (dam.name.contains('Bình Điền')) {
                          damLabel = 'Bình Điền';
                          riverLabel = '(S. Hương)';
                        } else if (dam.name.contains('Tả Trạch')) {
                          damLabel = 'Tả Trạch';
                          riverLabel = '(S. Hương)';
                        }

                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                damLabel,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                riverLabel,
                                style: TextStyle(
                                  color: riverLabel.contains('Bồ')
                                      ? AppColors.riverBo
                                      : AppColors.riverHuong,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
