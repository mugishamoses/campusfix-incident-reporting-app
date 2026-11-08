import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/auth_providers.dart';

/// Bottom navigation with the raised centre "Report" button (students only).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStaff = ref.watch(currentUserProvider)?.isStaff ?? false;
    void go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Color(0x142A1259), blurRadius: 20)],
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                _NavItem(
                    icon: Icons.home_rounded,
                    label: isStaff ? 'Dashboard' : 'Home',
                    selected: shell.currentIndex == 0,
                    onTap: () => go(0)),
                _NavItem(
                    icon: Icons.description_rounded,
                    label: 'Reports',
                    selected: shell.currentIndex == 1,
                    onTap: () => go(1)),
                if (!isStaff)
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Report an incident',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push(Routes.newReport);
                        },
                        // Stack so the raised button overhangs without overflowing the bar.
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            Positioned(
                              top: -20,
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.heroGradient,
                                  boxShadow: AppShadow.lifted,
                                ),
                                child: const Icon(Icons.add_rounded,
                                    color: Colors.white, size: 30),
                              ),
                            ),
                            const Positioned(
                              bottom: 10,
                              child: Text('Report',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                _NavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    selected: shell.currentIndex == 2,
                    onTap: () => go(2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 36,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.1 : 1,
                duration: const Duration(milliseconds: 200),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
