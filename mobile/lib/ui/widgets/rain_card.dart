import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/rain_data.dart';

class RainCard extends StatelessWidget {
  final RainStation station;

  const RainCard({
    super.key,
    required this.station,
  });

  @override
  Widget build(BuildContext context) {
    final rainStyle = _getRainLevelStyle(station.level, station.sumDepth);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 38,
                  decoration: BoxDecoration(
                    color: rainStyle.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.stationName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (station.area.isNotEmpty) ...[
                            Text(
                              station.area,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Text(
                              ' • ',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: rainStyle.bgColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              station.level,
                              style: TextStyle(
                                color: rainStyle.color,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    station.sumDepth.toStringAsFixed(1),
                    style: TextStyle(
                      color: rainStyle.color,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Text(
                    'mm',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (station.difference.abs() > 0.01)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      station.difference > 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      size: 14,
                      color: station.difference > 0 ? AppColors.bd2 : AppColors.safe,
                    ),
                    Text(
                      '${station.difference > 0 ? "+" : ""}${station.difference.toStringAsFixed(1)}mm',
                      style: TextStyle(
                        color: station.difference > 0 ? AppColors.bd2 : AppColors.safe,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  _RainStyle _getRainLevelStyle(String level, double depth) {
    if (level.contains('rất to') || depth >= 100) {
      return const _RainStyle(AppColors.rainHeavy, Color(0xFFFEE2E2));
    }
    if (level.contains('to') || depth >= 50) {
      return const _RainStyle(AppColors.rainMedium, Color(0xFFFFEDD5));
    }
    if (level.contains('vừa') || depth >= 16) {
      return const _RainStyle(AppColors.rainModerate, Color(0xFFDCFCE7));
    }
    if (level.contains('nhỏ') || depth > 0) {
      return const _RainStyle(AppColors.rainLight, Color(0xFFE0F2FE));
    }
    return const _RainStyle(AppColors.rainNone, Color(0xFFF1F5F9));
  }
}

class _RainStyle {
  final Color color;
  final Color bgColor;

  const _RainStyle(this.color, this.bgColor);
}
