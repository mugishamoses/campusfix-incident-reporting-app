import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/enum_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/incident.dart';
import '../../../logic/auth_providers.dart';
import '../../../logic/incident_actions.dart';
import '../../../logic/incident_providers.dart';
import '../../widgets/basics.dart';
import '../../widgets/incident_widgets.dart';
import '../../widgets/state_views.dart';

enum _MenuAction { edit, delete, hide, unhide }

class IncidentDetailsScreen extends ConsumerWidget {
  const IncidentDetailsScreen({super.key, required this.id});
  final String id;

  Future<void> _onMenu(
      BuildContext context, WidgetRef ref, Incident incident, _MenuAction action) async {
    final actions = ref.read(incidentActionsProvider.notifier);
    switch (action) {
      case _MenuAction.edit:
        context.push(Routes.editReport(incident.id));
      case _MenuAction.delete:
        final ok = await showConfirmDialog(context,
            title: 'Delete this report?',
            message: 'This can\'t be undone.',
            confirmLabel: 'Delete',
            destructive: true);
        if (!ok || !context.mounted) return;
        if (await actions.delete(incident) && context.mounted) {
          context.pop();
          showSnack(context, 'Report deleted.');
        }
      case _MenuAction.hide || _MenuAction.unhide:
        final hide = action == _MenuAction.hide;
        if (await actions.setHidden(incident, hide) && context.mounted) {
          showSnack(context, hide ? 'Hidden from the public feed.' : 'Visible again.');
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(incidentActionsProvider, (_, next) {
      if (next is AsyncError) showSnack(context, errorMessage(next.error), error: true);
    });
    final user = ref.watch(currentUserProvider);
    final incidentAsync = ref.watch(incidentProvider(id));
    final incident = incidentAsync.value;
    final isOwner = incident != null && incident.reporterId == user?.uid;
    final isStaff = user?.isStaff ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          if (incident != null && ((isOwner && incident.isEditable) || isStaff))
            PopupMenuButton<_MenuAction>(
              tooltip: 'More actions',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (a) => _onMenu(context, ref, incident, a),
              itemBuilder: (_) => [
                if (isOwner && incident.isEditable) ...[
                  const PopupMenuItem(value: _MenuAction.edit, child: Text('Edit report')),
                  const PopupMenuItem(
                      value: _MenuAction.delete,
                      child: Text('Delete report', style: TextStyle(color: AppColors.danger))),
                ],
                if (isStaff)
                  incident.isHidden
                      ? const PopupMenuItem(
                          value: _MenuAction.unhide, child: Text('Show in public feed'))
                      : const PopupMenuItem(
                          value: _MenuAction.hide, child: Text('Hide as spam')),
              ],
            ),
        ],
      ),
      body: switch (incidentAsync) {
        AsyncData(value: null) => const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Report not found',
            message: 'It may have been deleted.'),
        AsyncError(:final error) => ErrorState(error: error),
        AsyncData(:final value?) => _DetailsBody(incident: value, user: user),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _DetailsBody extends ConsumerWidget {
  const _DetailsBody({required this.incident, required this.user});
  final Incident incident;
  final AppUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final history = ref.watch(historyProvider(incident.id)).value ?? const [];
    final isStaff = user?.isStaff ?? false;
    final reporter = incident.reporterId == user?.uid
        ? 'You${incident.isAnonymous ? ' (anonymously)' : ''}'
        : incident.reporterName;
    const gap = SizedBox(height: AppSpace.l);

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.s, AppSpace.l, AppSpace.xxl),
      children: [
        if (incident.isHidden)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.m),
            child: AppCard(
              color: const Color(0xFFFFF1CC),
              child: MetaRow(Icons.visibility_off_rounded,
                  'Hidden from the public feed by staff.'),
            ),
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IncidentImage(incident: incident, size: 76),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(incident.title, style: text.titleMedium),
                        const SizedBox(height: 2),
                        Text(incident.location, style: text.bodySmall),
                        const SizedBox(height: AppSpace.s),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          StatusPill(incident.status),
                          Tag(incident.category.label,
                              icon: incident.category.icon,
                              color: incident.category.color,
                              background: incident.category.color.withValues(alpha: .1)),
                          if (isStaff) PriorityTag(incident.priority),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpace.m),
                child: Divider(),
              ),
              MetaRow(Icons.calendar_today_outlined, 'Submitted on ${fullDate(incident.createdAt)}'),
              const SizedBox(height: AppSpace.s),
              MetaRow(Icons.person_outline_rounded, 'Reported by $reporter'),
            ],
          ),
        ),
        gap,
        Text('Status Timeline', style: text.titleMedium),
        const SizedBox(height: AppSpace.m),
        AppCard(child: StatusTimeline(current: incident.status, history: history)),
        if (incident.resolutionNote != null) ...[
          gap,
          AppCard(
            color: const Color(0xFFDDF6EA),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.success),
                const SizedBox(width: AppSpace.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resolution', style: text.titleSmall),
                      const SizedBox(height: 2),
                      Text(incident.resolutionNote!, style: text.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (isStaff) ...[gap, _StaffPanel(incident: incident)],
        gap,
        Text('Description', style: text.titleMedium),
        const SizedBox(height: AppSpace.s),
        Text(incident.description, style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
        if (incident.photoUrl != null) ...[
          gap,
          Text('Attached Photo', style: text.titleMedium),
          const SizedBox(height: AppSpace.m),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => _PhotoViewer(incident: incident),
            )),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: IncidentImage(incident: incident, radius: AppRadius.card),
            ),
          ),
        ],
        if (history.length > 1) ...[
          gap,
          Text('Activity', style: text.titleMedium),
          const SizedBox(height: AppSpace.s),
          for (final h in history.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.m),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: h.to.background,
                    child: Icon(h.to.icon, size: 14, color: h.to.color),
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.from == null ? 'Report submitted' : 'Moved to ${h.to.label}',
                          style: text.titleSmall?.copyWith(fontSize: 14),
                        ),
                        Text('${h.byName} · ${timeAgo(h.at)}',
                            style: text.bodySmall),
                        if (h.note != null) ...[
                          const SizedBox(height: 2),
                          Text('"${h.note}"', style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// Staff-only controls: move status forward/back, priority, resolution note.
class _StaffPanel extends ConsumerStatefulWidget {
  const _StaffPanel({required this.incident});
  final Incident incident;

  @override
  ConsumerState<_StaffPanel> createState() => _StaffPanelState();
}

class _StaffPanelState extends ConsumerState<_StaffPanel> {
  final _note = TextEditingController();
  late IncidentStatus _target = widget.incident.status;

  @override
  void didUpdateWidget(covariant _StaffPanel old) {
    super.didUpdateWidget(old);
    if (old.incident.status != widget.incident.status) _target = widget.incident.status;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await ref
        .read(incidentActionsProvider.notifier)
        .changeStatus(widget.incident, _target, _note.text);
    if (ok && mounted) {
      HapticFeedback.mediumImpact();
      _note.clear();
      showSnack(context, 'Status updated to ${_target.label}. Reporter notified.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final loading = ref.watch(incidentActionsProvider).isLoading;
    final i = widget.incident;
    final changed = _target != i.status;

    return AppCard(
      color: AppColors.primarySoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpace.s),
            Text('Manage report', style: text.titleMedium),
          ]),
          const SizedBox(height: AppSpace.m),
          Text('Status', style: text.titleSmall),
          const SizedBox(height: AppSpace.s),
          Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.s,
            children: [
              for (final s in IncidentStatus.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _target == s,
                  showCheckmark: false,
                  selectedColor: s.color,
                  backgroundColor: AppColors.surface,
                  side: BorderSide.none,
                  labelStyle: TextStyle(
                      color: _target == s ? Colors.white : AppColors.text,
                      fontWeight: FontWeight.w600),
                  onSelected: (_) => setState(() => _target = s),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.l),
          Text('Priority', style: text.titleSmall),
          const SizedBox(height: AppSpace.s),
          SegmentedButton<IncidentPriority>(
            showSelectedIcon: false,
            segments: [
              for (final p in IncidentPriority.values)
                ButtonSegment(value: p, label: Text(p.label)),
            ],
            selected: {i.priority},
            onSelectionChanged: (s) =>
                ref.read(incidentActionsProvider.notifier).setPriority(i, s.first),
          ),
          if (changed) ...[
            const SizedBox(height: AppSpace.l),
            TextField(
              controller: _note,
              maxLines: 2,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: _target == IncidentStatus.resolved
                    ? 'What was done to fix it? (shown to the student)'
                    : 'Optional note for the student',
              ),
            ),
            const SizedBox(height: AppSpace.s),
            PrimaryButton(
              label: 'Update to ${_target.label}',
              loading: loading,
              onPressed: _save,
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: Center(
          child: InteractiveViewer(
            child: IncidentImage(incident: incident, radius: 0),
          ),
        ),
      );
}
