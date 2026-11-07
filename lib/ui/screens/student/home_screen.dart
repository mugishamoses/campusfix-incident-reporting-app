import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/enum_styles.dart';
import '../../../data/models/enums.dart';
import '../../../logic/incident_providers.dart';
import '../../widgets/basics.dart';
import '../../widgets/feature_widgets.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/incident_widgets.dart';
import '../../widgets/state_views.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(myIncidentsProvider);
    final stats = ReportStats.of(mine.value ?? const []);
    void openProfile([IncidentStatus? status]) {
      ref.read(myFilterProvider.notifier).setStatus(status);
      StatefulNavigationShell.of(context).goBranch(2);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.l, AppSpace.l, 0),
              sliver: SliverList.list(children: [
                const GreetingHeader(
                    subtitle: 'Help make our campus safer.\nReport issues and track their resolution.'),
                const SizedBox(height: AppSpace.xl),
                HeroBanner(onReport: () => context.push(Routes.newReport)),
                const SizedBox(height: AppSpace.xl),
                SectionHeader('Report Summary', action: 'See all', onAction: openProfile),
                const SizedBox(height: AppSpace.s),
                Row(
                  children: [
                    for (final (label, value, icon, color, status) in [
                      ('My Reports', stats.total, Icons.description_outlined, AppColors.primary, null),
                      ('In Progress', stats[IncidentStatus.inProgress], Icons.schedule_rounded,
                          IncidentStatus.inReview.color, IncidentStatus.inProgress),
                      ('Resolved', stats[IncidentStatus.resolved], Icons.check_circle_outline_rounded,
                          IncidentStatus.resolved.color, IncidentStatus.resolved),
                      ('Submitted', stats[IncidentStatus.submitted], Icons.error_outline_rounded,
                          AppColors.danger, IncidentStatus.submitted),
                    ]) ...[
                      Expanded(
                        child: StatTile(
                          label: label,
                          value: value,
                          icon: icon,
                          color: color,
                          onTap: () => openProfile(status),
                        ),
                      ),
                      if (label != 'Submitted') const SizedBox(width: AppSpace.s),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpace.xl),
                SectionHeader('Recent Reports',
                    action: 'See all', onAction: () => openProfile()),
                const SizedBox(height: AppSpace.s),
              ]),
            ),
            AsyncSliverList(
              value: mine,
              limit: 3,
              itemBuilder: (i) => IncidentCard(
                  incident: i, onTap: () => context.push(Routes.incident(i.id))),
              empty: EmptyState(
                icon: Icons.campaign_outlined,
                title: 'No reports yet',
                message: 'Spotted something broken? Your reports will show up here.',
                action: SizedBox(
                  width: 200,
                  child: PrimaryButton(
                      label: 'Report an issue',
                      onPressed: () => context.push(Routes.newReport)),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxl)),
          ],
        ),
      ),
    );
  }
}
