import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/enum_styles.dart';
import '../../../data/models/enums.dart';
import '../../../logic/incident_providers.dart';
import '../../widgets/basics.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/incident_widgets.dart';
import '../../widgets/state_views.dart';

/// Staff home: campus-wide counts and a priority-sorted triage queue.
class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(visibleIncidentsProvider);
    final stats = ReportStats.of(all.value ?? const []);
    final queue = ref.watch(staffQueueProvider);
    final text = Theme.of(context).textTheme;
    void openFeed(IncidentStatus? s) {
      ref.read(feedFilterProvider.notifier).setStatus(s);
      StatefulNavigationShell.of(context).goBranch(1);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.l, AppSpace.l, 0),
              sliver: SliverList.list(children: [
                const GreetingHeader(subtitle: 'Here\'s what needs attention on campus today.'),
                const SizedBox(height: AppSpace.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpace.xl - 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(AppRadius.hero),
                    boxShadow: AppShadow.lifted,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Open reports',
                                style: TextStyle(color: Colors.white.withValues(alpha: .85))),
                            const SizedBox(height: 4),
                            Text('${stats.open}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
                            Text('${stats[IncidentStatus.submitted]} waiting for review',
                                style: TextStyle(color: Colors.white.withValues(alpha: .85))),
                          ],
                        ),
                      ),
                      const Icon(Icons.assignment_late_outlined, color: Colors.white54, size: 64),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.l),
                Row(
                  children: [
                    for (final s in IncidentStatus.values) ...[
                      Expanded(
                        child: StatTile(
                          label: s == IncidentStatus.submitted ? 'New' : s.label,
                          value: stats[s],
                          icon: s.icon,
                          color: s.color,
                          onTap: () => openFeed(s),
                        ),
                      ),
                      if (s != IncidentStatus.resolved) const SizedBox(width: AppSpace.s),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpace.xl),
                SectionHeader('Needs attention', action: 'See all', onAction: () => openFeed(null)),
                Text('Highest priority first, then oldest.', style: text.bodySmall),
                const SizedBox(height: AppSpace.m),
              ]),
            ),
            AsyncSliverList(
              value: queue,
              limit: 8,
              itemBuilder: (i) => Stack(
                children: [
                  IncidentCard(incident: i, onTap: () => context.push(Routes.incident(i.id))),
                  if (i.priority == IncidentPriority.high)
                    Positioned(
                      left: 0,
                      top: 14,
                      bottom: 14,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: IncidentPriority.high.color,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                        ),
                      ),
                    ),
                ],
              ),
              empty: const EmptyState(
                icon: Icons.task_alt_rounded,
                title: 'Queue is clear',
                message: 'Every report is resolved. Nice work!',
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxl)),
          ],
        ),
      ),
    );
  }
}
