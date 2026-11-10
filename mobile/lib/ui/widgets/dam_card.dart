import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/hydro_dam.dart';

class DamCard extends StatelessWidget {
  final HydroDam dam;

  const DamCard({
    super.key,
    required this.dam,
  });

  @override
  Widget build(BuildContext context) {
    final isBo = dam.river.contains('Bồ') || dam.name.contains('Hương Điền');
    final riverColor = isBo ? AppColors.riverBo : AppColors.riverHuong;
    final riverBg = isBo ? const Color(0xFFDBEAFE) : const Color(0xFFE0F2FE);
    final riverName = isBo ? 'Lưu vực Sông Bồ' : 'Lưu vực Sông Hương';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                          fontWeight: FontWeight.w700,
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
          const SizedBox(height: 4),
          if (dam.recordedAt.isNotEmpty)
            Text(
              'Cập nhật: ${dam.recordedAt}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  label: 'Mực nước hồ',
                  value: dam.waterLevel > 0 ? '${dam.waterLevel.toStringAsFixed(1)} m' : 'N/A',
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
        ],
      ),
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
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                    fontSize: 13,
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
                    fontSize: 9.5,
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
}
