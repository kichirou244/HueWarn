import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../models/water_station.dart';

class SongHuongChart extends StatelessWidget {
  final List<WaterLevelHistoryPoint> history;
  final double currentDepth;

  const SongHuongChart({
    super.key,
    required this.history,
    required this.currentDepth,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return _buildEmptyContainer('Sông Hương (Trạm Dã Viên)');
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i].depth));
    }

    final maxX = (spots.length > 1 ? spots.length - 1 : 1).toDouble();
    double maxY = 4.0;
    for (final s in spots) {
      if (s.y + 0.6 > maxY) maxY = s.y + 0.6;
    }

    final statusInfo = _getHuongStatus(currentDepth);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 18,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: AppColors.riverHuong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SÔNG HƯƠNG - TRẠM DÃ VIÊN',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusInfo.bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusInfo.label,
                  style: TextStyle(
                    color: statusInfo.textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: 0,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  enabled: true,
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: (barData.color ?? AppColors.primary).withValues(alpha: 0.6),
                          strokeWidth: 1.5,
                          dashArray: [4, 4],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 5,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: barData.color ?? AppColors.primary,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    tooltipBorder: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                    tooltipBorderRadius: BorderRadius.circular(8),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final timeStr = (idx >= 0 && idx < history.length)
                            ? history[idx].timePoint.split(' ').first
                            : '';
                        final depthStr = '${spot.y.toStringAsFixed(2)} m';
                        return LineTooltipItem(
                          depthStr,
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                          children: timeStr.isNotEmpty
                              ? [
                                  TextSpan(
                                    text: '\n$timeStr',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ]
                              : null,
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1.0,
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
                      reservedSize: 34,
                      interval: 1.0,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${value.toInt()}m',
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
                      reservedSize: 28,
                      interval: maxX > 6 ? (maxX / 4).floorToDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= history.length) {
                          return const SizedBox.shrink();
                        }
                        final timeStr = history[idx].timePoint.split(' ').first;
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(
                            timeStr,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
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
                      y: 1.0,
                      color: AppColors.bd1,
                      strokeWidth: 1,
                      dashArray: [4, 3],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 4),
                        style: const TextStyle(
                          color: AppColors.bd1,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                        labelResolver: (line) => 'BĐ1: 1.0m',
                      ),
                    ),
                    HorizontalLine(
                      y: 1.8,
                      color: AppColors.dapDa,
                      strokeWidth: 1.2,
                      dashArray: [3, 3],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 4),
                        style: const TextStyle(
                          color: AppColors.dapDa,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                        labelResolver: (line) => 'Đập Đá: 1.8m',
                      ),
                    ),
                    HorizontalLine(
                      y: 2.0,
                      color: AppColors.bd2,
                      strokeWidth: 1,
                      dashArray: [4, 3],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 4),
                        style: const TextStyle(
                          color: AppColors.bd2,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                        labelResolver: (line) => 'BĐ2: 2.0m',
                      ),
                    ),
                    HorizontalLine(
                      y: 3.5,
                      color: AppColors.bd3,
                      strokeWidth: 1.2,
                      dashArray: [4, 2],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 4),
                        style: const TextStyle(
                          color: AppColors.bd3,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                        labelResolver: (line) => 'BĐ3: 3.5m',
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
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.riverHuong.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getHuongStatus(double depth) {
    if (depth >= 3.5) {
      return const _StatusInfo('Báo động 3', AppColors.bd3Bg, AppColors.bd3);
    }
    if (depth >= 2.0) {
      return const _StatusInfo('Báo động 2', AppColors.bd2Bg, AppColors.bd2);
    }
    if (depth >= 1.8) {
      return const _StatusInfo('Tràn Đập Đá', AppColors.dapDaBg, AppColors.dapDa);
    }
    if (depth >= 1.0) {
      return const _StatusInfo('Báo động 1', AppColors.bd1Bg, AppColors.bd1);
    }
    return const _StatusInfo('Bình thường', AppColors.safeBg, AppColors.safe);
  }

  Widget _buildEmptyContainer(String title) {
    return Container(
      height: 180,
      margin: const EdgeInsets.only(bottom: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'Đang cập nhật chuỗi dữ liệu $title...',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }
}

class SongBoChart extends StatelessWidget {
  final List<WaterLevelHistoryPoint> history;
  final double currentDepth;

  const SongBoChart({
    super.key,
    required this.history,
    required this.currentDepth,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return _buildEmptyContainer('Sông Bồ (Trạm Tứ Phú)');
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i].depth));
    }

    final maxX = (spots.length > 1 ? spots.length - 1 : 1).toDouble();
    double maxY = 5.0;
    for (final s in spots) {
      if (s.y + 0.6 > maxY) maxY = s.y + 0.6;
    }

    final statusInfo = _getBoStatus(currentDepth);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 18,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: AppColors.riverBo,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SÔNG BỒ - TRẠM TỨ PHÚ',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusInfo.bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusInfo.label,
                  style: TextStyle(
                    color: statusInfo.textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: 0,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  enabled: true,
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: (barData.color ?? AppColors.primary).withValues(alpha: 0.6),
                          strokeWidth: 1.5,
                          dashArray: [4, 4],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 5,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: barData.color ?? AppColors.primary,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    tooltipBorder: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                    tooltipBorderRadius: BorderRadius.circular(8),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final timeStr = (idx >= 0 && idx < history.length)
                            ? history[idx].timePoint.split(' ').first
                            : '';
                        final depthStr = '${spot.y.toStringAsFixed(2)} m';
                        return LineTooltipItem(
                          depthStr,
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                          children: timeStr.isNotEmpty
                              ? [
                                  TextSpan(
                                    text: '\n$timeStr',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ]
                              : null,
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1.0,
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
                      reservedSize: 34,
                      interval: 1.0,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${value.toInt()}m',
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
                      reservedSize: 28,
                      interval: maxX > 6 ? (maxX / 4).floorToDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= history.length) {
                          return const SizedBox.shrink();
                        }
                        final timeStr = history[idx].timePoint.split(' ').first;
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(
                            timeStr,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
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
                      y: 1.5,
                      color: AppColors.bd1,
                      strokeWidth: 1,
                      dashArray: [4, 3],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 4),
                        style: const TextStyle(
                          color: AppColors.bd1,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                        labelResolver: (line) => 'BĐ1: 1.5m',
                      ),
                    ),
                    HorizontalLine(
                      y: 3.0,
                      color: AppColors.bd2,
                      strokeWidth: 1.2,
                      dashArray: [4, 3],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 4),
                        style: const TextStyle(
                          color: AppColors.bd2,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                        labelResolver: (line) => 'BĐ2: 3.0m',
                      ),
                    ),
                    HorizontalLine(
                      y: 4.5,
                      color: AppColors.bd3,
                      strokeWidth: 1.2,
                      dashArray: [4, 2],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 4),
                        style: const TextStyle(
                          color: AppColors.bd3,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                        labelResolver: (line) => 'BĐ3: 4.5m',
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: AppColors.riverBo,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.riverBo.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getBoStatus(double depth) {
    if (depth >= 4.5) {
      return const _StatusInfo('Báo động 3', AppColors.bd3Bg, AppColors.bd3);
    }
    if (depth >= 3.0) {
      return const _StatusInfo('Báo động 2', AppColors.bd2Bg, AppColors.bd2);
    }
    if (depth >= 1.5) {
      return const _StatusInfo('Báo động 1', AppColors.bd1Bg, AppColors.bd1);
    }
    return const _StatusInfo('Bình thường', AppColors.safeBg, AppColors.safe);
  }

  Widget _buildEmptyContainer(String title) {
    return Container(
      height: 180,
      margin: const EdgeInsets.only(bottom: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'Đang cập nhật chuỗi dữ liệu $title...',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }
}

class _StatusInfo {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _StatusInfo(this.label, this.bgColor, this.textColor);
}
