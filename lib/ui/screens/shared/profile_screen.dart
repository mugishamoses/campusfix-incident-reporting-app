import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/enum_styles.dart';
import '../../../data/models/enums.dart';
import '../../../logic/auth_providers.dart';
import '../../../logic/incident_providers.dart';
import '../../widgets/basics.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/incident_widgets.dart';
import '../../widgets/state_views.dart';

/// "My Reports" from the mockup: profile card, stats, filtered personal list.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _openSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_none_rounded),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(Routes.notifications);
              },
            ),
            const ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('About ${AppConstants.appName}'),
              subtitle: Text(AppConstants.tagline),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
              title: const Text('Sign out', style: TextStyle(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(sheetContext);
                final ok = await showConfirmDialog(context,
                    title: 'Sign out?',
                    message: 'You can sign back in any time with your campus email.',
                    confirmLabel: 'Sign out');
                if (ok) ref.read(authControllerProvider.notifier).signOut();
              },
            ),
            const SizedBox(height: AppSpace.s),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();
    final text = Theme.of(context).textTheme;
    final filter = ref.watch(myFilterProvider);
    final stats = ReportStats.of(ref.watch(myIncidentsProvider).value ?? const []);
    final list = ref.watch(filteredMyIncidentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(user.isStaff ? 'Profile' : 'My Reports'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(context, ref),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: AppSpace.page,
            sliver: SliverList.list(children: [
              AppCard(
                child: Row(
                  children: [
                    Avatar(name: user.name, size: 60),
                    const SizedBox(width: AppSpace.l),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: text.titleMedium),
                          const SizedBox(height: 4),
                          MetaRow(Icons.school_outlined, user.department),
                          const SizedBox(height: 4),
                          MetaRow(Icons.alternate_email_rounded, user.email),
                        ],
                      ),
                    ),
                    Tag(user.isStaff ? 'Staff' : 'Student',
                        color: AppColors.primary, background: AppColors.primarySoft),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.l),
              if (!user.isStaff)
                Row(children: [
                  Expanded(
                      child: StatTile(
                          label: 'Total Reports',
                          value: stats.total,
                          icon: Icons.description_outlined,
                          color: AppColors.primary)),
                  const SizedBox(width: AppSpace.s),
                  Expanded(
                      child: StatTile(
                          label: 'In Progress',
                          value: stats[IncidentStatus.inProgress],
                          icon: Icons.schedule_rounded,
                          color: IncidentStatus.inReview.color)),
                  const SizedBox(width: AppSpace.s),
                  Expanded(
                      child: StatTile(
                          label: 'Resolved',
                          value: stats[IncidentStatus.resolved],
                          icon: Icons.check_circle_outline_rounded,
                          color: IncidentStatus.resolved.color)),
                ]),
              const SizedBox(height: AppSpace.l),
            ]),
          ),
          if (user.isStaff)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Staff account',
                message: 'You manage campus reports from the Dashboard and Reports tabs.',
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: ChoiceChipsBar<IncidentStatus>(
                values: IncidentStatus.values,
                selected: filter.status,
                labelOf: (s) => s.label,
                onSelected: ref.read(myFilterProvider.notifier).setStatus,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpace.m)),
            AsyncSliverList(
              value: list,
              itemBuilder: (i) => IncidentCard(
                  incident: i, onTap: () => context.push(Routes.incident(i.id))),
              empty: EmptyState(
                icon: Icons.inbox_outlined,
                title: filter.status == null
                    ? 'No reports yet'
                    : 'No ${filter.status!.label.toLowerCase()} reports',
                message: 'Reports you submit will appear here.',
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxl)),
        ],
      ),
    );
  }
}
