import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../logic/incident_actions.dart';
import '../../../logic/incident_providers.dart';
import '../../widgets/basics.dart';
import '../../widgets/state_views.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: AppSpace.s)),
          AsyncSliverList(
            value: ref.watch(notificationsProvider),
            empty: const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: "You're all caught up",
              message: "We'll let you know when staff update one of your reports.",
            ),
            itemBuilder: (n) => AppCard(
              color: n.read ? AppColors.surface : AppColors.primarySoft,
              onTap: () {
                ref.read(incidentActionsProvider.notifier).markRead(n.id);
                context.push(Routes.incident(n.incidentId));
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surface,
                    child: Icon(Icons.update_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: text.titleSmall),
                        const SizedBox(height: 2),
                        Text(n.message, style: text.bodySmall),
                        const SizedBox(height: 4),
                        Text(timeAgo(n.at), style: text.bodySmall?.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                  if (!n.read)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
