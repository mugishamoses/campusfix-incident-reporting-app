import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/enums.dart';
import '../../../logic/incident_providers.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/incident_widgets.dart';
import '../../widgets/state_views.dart';

/// Campus-wide reports with search, status and category filters.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(feedFilterProvider);
    final notifier = ref.read(feedFilterProvider.notifier);
    final results = ref.watch(filteredFeedProvider);
    final count = results.value?.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Campus Reports'), centerTitle: false),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: AppSpace.page,
                  child: SearchField(onChanged: notifier.setQuery),
                ),
                const SizedBox(height: AppSpace.m),
                ChoiceChipsBar<IncidentStatus>(
                  values: IncidentStatus.values,
                  selected: filter.status,
                  labelOf: (s) => s.label,
                  onSelected: notifier.setStatus,
                ),
                const SizedBox(height: AppSpace.s),
                ChoiceChipsBar<IncidentCategory>(
                  values: IncidentCategory.values,
                  selected: filter.category,
                  labelOf: (c) => c.label,
                  allLabel: 'All categories',
                  onSelected: notifier.setCategory,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.m, AppSpace.s, AppSpace.s),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          count == null ? ' ' : '$count report${count == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (filter.status != null || filter.category != null)
                        TextButton(
                          onPressed: () {
                            notifier.setStatus(null);
                            notifier.setCategory(null);
                          },
                          child: const Text('Clear filters'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AsyncSliverList(
            value: results,
            itemBuilder: (i) => IncidentCard(
                incident: i, onTap: () => context.push(Routes.incident(i.id))),
            empty: EmptyState(
              icon: filter.isActive ? Icons.search_off_rounded : Icons.inbox_outlined,
              title: filter.isActive ? 'No matching reports' : 'All quiet on campus',
              message: filter.isActive
                  ? 'Try a different search or clear the filters.'
                  : 'No incidents have been reported yet.',
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxl)),
        ],
      ),
      backgroundColor: AppColors.background,
    );
  }
}
