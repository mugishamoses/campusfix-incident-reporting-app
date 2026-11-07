import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../logic/auth_providers.dart';
import '../../logic/incident_providers.dart';
import 'basics.dart';

/// "Hello, Amina 👋" + notification bell (with unread dot) + avatar.
class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({super.key, required this.subtitle});
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final unread = ref.watch(unreadCountProvider);
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, ${firstName(user?.name ?? '')} 👋', style: text.headlineSmall),
              const SizedBox(height: AppSpace.xs),
              Text(subtitle, style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
        IconButton(
          tooltip: unread == 0 ? 'Notifications' : '$unread unread notifications',
          onPressed: () => context.push(Routes.notifications),
          icon: Badge(
            isLabelVisible: unread > 0,
            backgroundColor: AppColors.danger,
            smallSize: 9,
            child: const Icon(Icons.notifications_none_rounded, size: 28),
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        GestureDetector(
          onTap: () => StatefulNavigationShell.maybeOf(context)?.goBranch(2),
          child: Avatar(name: user?.name ?? '?', size: 44),
        ),
      ],
    );
  }
}
