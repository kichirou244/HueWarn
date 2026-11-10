import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/water_station.dart';

class WaterLevelCard extends StatelessWidget {
  final WaterStation station;

  const WaterLevelCard({
    super.key,
    required this.station,
  });

  @override
  Widget build(BuildContext context) {
    final status = _getAlertStatus();
    final isHuong = station.id == '841699255114';
    final isBo = station.id == '841699255097';
    final riverColor = isHuong ? AppColors.riverHuong : (isBo ? AppColors.riverBo : AppColors.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: station.isTarget ? riverColor.withValues(alpha: 0.5) : AppColors.border,
          width: station.isTarget ? 1.5 : 1.0,
        ),
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
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: riverColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (station.area.isNotEmpty)
                            Text(
                              station.area,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status.bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    color: status.textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mực nước hiện tại',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        station.depth.toStringAsFixed(2),
                        style: TextStyle(
                          color: status.textColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'm',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  _buildDeltaBadge('10p', station.change10m),
                  const SizedBox(width: 8),
                  _buildDeltaBadge('1h', station.change1h),
                  const SizedBox(width: 8),
                  _buildDeltaBadge('6h', station.change6h),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaBadge(String label, double? change) {
    if (change == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
            const Text('--', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final isUp = change > 0;
    final isDown = change < 0;
    final sign = isUp ? '+' : '';
    final color = isUp ? AppColors.bd2 : (isDown ? AppColors.safe : AppColors.textSecondary);
    final bg = isUp ? AppColors.bd2Bg : (isDown ? AppColors.safeBg : AppColors.surfaceVariant);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUp ? Icons.arrow_drop_up : (isDown ? Icons.arrow_drop_down : Icons.remove),
                size: 14,
                color: color,
              ),
              Text(
                '$sign${change.toStringAsFixed(2)}',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _CardAlertStatus _getAlertStatus() {
    if (station.id == '841699255114') {
      if (station.depth >= 3.5) return const _CardAlertStatus('Báo động 3', AppColors.bd3Bg, AppColors.bd3);
      if (station.depth >= 2.0) return const _CardAlertStatus('Báo động 2', AppColors.bd2Bg, AppColors.bd2);
      if (station.depth >= 1.8) return const _CardAlertStatus('Tràn Đập Đá', AppColors.dapDaBg, AppColors.dapDa);
      if (station.depth >= 1.0) return const _CardAlertStatus('Báo động 1', AppColors.bd1Bg, AppColors.bd1);
      return const _CardAlertStatus('Bình thường', AppColors.safeBg, AppColors.safe);
    }

    if (station.id == '841699255097') {
      if (station.depth >= 4.5) return const _CardAlertStatus('Báo động 3', AppColors.bd3Bg, AppColors.bd3);
      if (station.depth >= 3.0) return const _CardAlertStatus('Báo động 2', AppColors.bd2Bg, AppColors.bd2);
      if (station.depth >= 1.5) return const _CardAlertStatus('Báo động 1', AppColors.bd1Bg, AppColors.bd1);
      return const _CardAlertStatus('Bình thường', AppColors.safeBg, AppColors.safe);
    }

    if (station.alertLevel == 3) return const _CardAlertStatus('Khẩn cấp', AppColors.bd3Bg, AppColors.bd3);
    if (station.alertLevel == 2) return const _CardAlertStatus('Nguy hiểm', AppColors.bd2Bg, AppColors.bd2);
    if (station.alertLevel == 1) return const _CardAlertStatus('Cảnh báo', AppColors.bd1Bg, AppColors.bd1);
    return const _CardAlertStatus('Bình thường', AppColors.safeBg, AppColors.safe);
  }
}

class _CardAlertStatus {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _CardAlertStatus(this.label, this.bgColor, this.textColor);
}
