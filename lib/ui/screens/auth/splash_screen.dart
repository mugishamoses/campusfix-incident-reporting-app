import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64, this.onDark = false});
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onDark ? Colors.white : null,
          gradient: onDark ? null : AppColors.heroGradient,
          borderRadius: BorderRadius.circular(size * .3),
          boxShadow: onDark ? null : AppShadow.lifted,
        ),
        child: Icon(Icons.campaign_rounded,
            size: size * .55, color: onDark ? AppColors.primary : Colors.white),
      );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 84, onDark: true),
              const SizedBox(height: AppSpace.l),
              const Text(AppConstants.appName,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpace.xs),
              Text(AppConstants.tagline,
                  style: TextStyle(color: Colors.white.withValues(alpha: .8))),
            ],
          ),
        ),
      );
}
