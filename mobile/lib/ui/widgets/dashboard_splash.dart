import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// First-load screen: rotating logo + app name while data is being fetched.
class DashboardSplash extends StatefulWidget {
  const DashboardSplash({super.key});

  @override
  State<DashboardSplash> createState() => _DashboardSplashState();
}

class _DashboardSplashState extends State<DashboardSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: CurvedAnimation(parent: _controller, curve: Curves.linear),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.06).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/huewarn_icon_1024.png'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'HUEWARN',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đang tải dữ liệu giám sát...',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(
            width: 140,
            child: LinearProgressIndicator(
              backgroundColor: AppColors.accentLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}
