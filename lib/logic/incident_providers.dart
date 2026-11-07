import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';

import '../data/models/app_user.dart';
import '../data/models/enums.dart';
import '../data/models/incident.dart';
import '../data/repositories/fake_incident_repository.dart';
import '../data/repositories/firestore_incident_repository.dart';
import '../data/repositories/incident_repository.dart';
import 'auth_providers.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) => AppConfig.fakeBackend
    ? FakeIncidentRepository()
    : FirestoreIncidentRepository(FirebaseFirestore.instance, FirebaseStorage.instance));

/// uid of a signed-in, verified user (null otherwise). Streams key off this so
/// they restart on account switch instead of erroring after sign-out.
final _readerUidProvider = Provider<String?>((ref) => ref.watch(
    currentUserProvider.select((u) => u != null && u.emailVerified ? u.uid : null)));

final _allIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  if (ref.watch(_readerUidProvider) == null) return Stream.value(const []);
  return ref.watch(incidentRepositoryProvider).watchAll();
});

/// Hidden (spam) reports are only visible to staff and their own reporter.
List<Incident> visibleTo(AppUser? user, List<Incident> all) => user == null
    ? const []
    : all.where((i) => user.isStaff || !i.isHidden || i.reporterId == user.uid).toList();

final visibleIncidentsProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final user = ref.watch(currentUserProvider);
  return ref.watch(_allIncidentsProvider).whenData((all) => visibleTo(user, all));
});

final myIncidentsProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  return ref
      .watch(_allIncidentsProvider)
      .whenData((all) => all.where((i) => i.reporterId == uid).toList());
});

final incidentProvider = StreamProvider.family<Incident?, String>(
    (ref, id) => ref.watch(incidentRepositoryProvider).watchOne(id));

final historyProvider = StreamProvider.family<List<StatusChange>, String>(
    (ref, id) => ref.watch(incidentRepositoryProvider).watchHistory(id));

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(_readerUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(incidentRepositoryProvider).watchNotifications(uid);
});

final unreadCountProvider = Provider<int>((ref) =>
    ref.watch(notificationsProvider).value?.where((n) => !n.read).length ?? 0);

// ---------------------------------------------------------------- stats

class ReportStats {
  const ReportStats(this.counts, this.total);

  factory ReportStats.of(List<Incident> list) {
    final counts = {for (final s in IncidentStatus.values) s: 0};
    for (final i in list) {
      counts[i.status] = counts[i.status]! + 1;
    }
    return ReportStats(counts, list.length);
  }

  final Map<IncidentStatus, int> counts;
  final int total;

  int operator [](IncidentStatus s) => counts[s]!;
  int get open => total - this[IncidentStatus.resolved];
}

// ---------------------------------------------------------------- filters

class IncidentFilter {
  const IncidentFilter({this.status, this.category, this.query = ''});

  final IncidentStatus? status;
  final IncidentCategory? category;
  final String query;

  bool get isActive => status != null || category != null || query.isNotEmpty;

  List<Incident> apply(List<Incident> list) {
    final q = query.trim().toLowerCase();
    return list.where((i) {
      if (status != null && i.status != status) return false;
      if (category != null && i.category != category) return false;
      if (q.isEmpty) return true;
      return i.title.toLowerCase().contains(q) ||
          i.location.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q);
    }).toList();
  }
}

class IncidentFilterNotifier extends Notifier<IncidentFilter> {
  @override
  IncidentFilter build() {
    ref.watch(_readerUidProvider); // fresh filters for each account
    return const IncidentFilter();
  }

  void setStatus(IncidentStatus? s) => state =
      IncidentFilter(status: s, category: state.category, query: state.query);

  void setCategory(IncidentCategory? c) => state =
      IncidentFilter(status: state.status, category: c, query: state.query);

  void setQuery(String q) => state =
      IncidentFilter(status: state.status, category: state.category, query: q);

  void clear() => state = const IncidentFilter();
}

/// Campus feed filter (Reports tab).
final feedFilterProvider =
    NotifierProvider<IncidentFilterNotifier, IncidentFilter>(
        IncidentFilterNotifier.new);

/// Personal list filter (Profile tab) — independent of the feed.
final myFilterProvider =
    NotifierProvider<IncidentFilterNotifier, IncidentFilter>(
        IncidentFilterNotifier.new);

final filteredFeedProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final filter = ref.watch(feedFilterProvider);
  return ref.watch(visibleIncidentsProvider).whenData(filter.apply);
});

final filteredMyIncidentsProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final filter = ref.watch(myFilterProvider);
  return ref.watch(myIncidentsProvider).whenData(filter.apply);
});

/// Staff queue: open reports, high priority first, then oldest first.
final staffQueueProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  return ref.watch(visibleIncidentsProvider).whenData((all) => all
      .where((i) => i.status.isOpen && !i.isHidden)
      .toList()
    ..sort((a, b) {
      final p = b.priority.index.compareTo(a.priority.index);
      return p != 0 ? p : a.createdAt.compareTo(b.createdAt);
    }));
});
