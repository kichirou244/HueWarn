import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/alert_notification.dart';

class AlertBanner extends StatelessWidget {
  final int alertLevel;
  final bool rapidIncrease;
  final List<AlertNotification> recentAlerts;

  const AlertBanner({
    super.key,
    required this.alertLevel,
    required this.rapidIncrease,
    required this.recentAlerts,
  });

  @override
  Widget build(BuildContext context) {
    if (alertLevel == 0 && !rapidIncrease && recentAlerts.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.safeBg,
          border: Border.all(color: AppColors.safe.withValues(alpha: 0.4), width: 1.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.safe, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mực nước sông Hương và sông Bồ hiện ở ngưỡng an toàn.',
                style: TextStyle(
                  color: AppColors.safe,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final latestAlert = recentAlerts.isNotEmpty ? recentAlerts.first : null;
    final title = latestAlert?.title ?? _getDefaultTitle();
    final message = latestAlert?.message ?? _getDefaultMessage();
    final style = _getBannerStyle(latestAlert?.severity);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.bgColor,
        border: Border.all(color: style.borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: style.textColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: style.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: style.textColor.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  _BannerColorStyle _getBannerStyle(String? severity) {
    if (severity == 'critical' || alertLevel == 3) {
      return const _BannerColorStyle(AppColors.bd3Bg, AppColors.bd3, AppColors.bd3);
    }
    if (severity == 'danger' || alertLevel == 2) {
      return const _BannerColorStyle(AppColors.bd2Bg, AppColors.bd2, AppColors.bd2);
    }
    if (severity == 'warning' || alertLevel == 1 || rapidIncrease) {
      return const _BannerColorStyle(AppColors.bd1Bg, AppColors.bd1, AppColors.bd1);
    }
    return const _BannerColorStyle(AppColors.safeBg, AppColors.safe, AppColors.safe);
  }

  String _getDefaultTitle() {
    if (alertLevel == 3) return 'CẢNH BÁO MỰC NƯỚC: MỨC BÁO ĐỘNG 3 (KHẨN CẤP)';
    if (alertLevel == 2) return 'CẢNH BÁO MỰC NƯỚC: MỨC BÁO ĐỘNG 2 (NGUY HIỂM)';
    if (alertLevel == 1) return 'CẢNH BÁO MỰC NƯỚC: MỨC BÁO ĐỘNG 1';
    if (rapidIncrease) return 'CẢNH BÁO NƯỚC DÂNG NHANH';
    return 'CẢNH BÁO THỜI TIẾT & MỰC NƯỚC';
  }

  String _getDefaultMessage() {
    if (rapidIncrease) {
      return 'Phát hiện nước sông tăng trên 0.5m trong vòng 1 giờ qua. Cần lưu ý theo dõi.';
    }
    return 'Mực nước sông đạt ngưỡng báo động. Đề nghị người dân chủ động các biện pháp an toàn.';
  }
}

class _BannerColorStyle {
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _BannerColorStyle(this.bgColor, this.borderColor, this.textColor);
}
