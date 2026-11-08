import 'dart:async';

import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/incident.dart';
import 'incident_repository.dart';

/// In-memory store with Firestore-like streams, for tests and the offline demo.
class FakeIncidentRepository implements IncidentRepository {
  FakeIncidentRepository({
    this.latency = const Duration(milliseconds: 500),
    bool seed = true,
  }) {
    if (seed) _seed();
  }

  final Duration latency;
  final _incidents = <String, Incident>{};
  final _history = <String, List<StatusChange>>{};
  final _notifications = <String, List<AppNotification>>{};
  final _changes = StreamController<void>.broadcast();
  int _nextId = 100;

  Stream<T> _watch<T>(T Function() read) => Stream.multi((sink) {
        sink.add(read());
        final sub = _changes.stream.listen((_) => sink.add(read()));
        sink.onCancel = sub.cancel;
      });

  void _notify() => _changes.add(null);

  @override
  Stream<List<Incident>> watchAll() => _watch(() => _incidents.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  @override
  Stream<Incident?> watchOne(String id) => _watch(() => _incidents[id]);

  @override
  Stream<List<StatusChange>> watchHistory(String incidentId) =>
      _watch(() => List.of(_history[incidentId] ?? const []));

  @override
  Stream<List<AppNotification>> watchNotifications(String uid) =>
      _watch(() => (_notifications[uid] ?? const <AppNotification>[])
          .toList()
        ..sort((a, b) => b.at.compareTo(a.at)));

  @override
  Future<String> create({
    required Incident draft,
    String? photoPath,
    void Function(double progress)? onProgress,
  }) async {
    if (photoPath != null) {
      for (var i = 1; i <= 10; i++) {
        await Future.delayed(latency ~/ 5);
        onProgress?.call(i / 10);
      }
    } else {
      await Future.delayed(latency);
    }
    final id = 'inc-${_nextId++}';
    final now = DateTime.now();
    _incidents[id] = Incident(
      id: id,
      title: draft.title,
      description: draft.description,
      category: draft.category,
      location: draft.location,
      status: IncidentStatus.submitted,
      priority: IncidentPriority.medium,
      reporterId: draft.reporterId,
      reporterName: draft.reporterName,
      isAnonymous: draft.isAnonymous,
      photoUrl: photoPath,
      createdAt: now,
      updatedAt: now,
    );
    _history[id] = [
      StatusChange(
          to: IncidentStatus.submitted, byName: draft.reporterName, at: now),
    ];
    _notify();
    return id;
  }

  @override
  Future<void> update(Incident incident, {String? newPhotoPath, bool removePhoto = false}) async {
    await Future.delayed(latency);
    _incidents[incident.id] = incident.copyWith(
      updatedAt: DateTime.now(),
      photoUrl: newPhotoPath,
      clearPhoto: removePhoto,
    );
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(latency);
    _incidents.remove(id);
    _history.remove(id);
    _notify();
  }

  @override
  Future<void> changeStatus({
    required Incident incident,
    required IncidentStatus to,
    required AppUser by,
    String? note,
  }) async {
    await Future.delayed(latency);
    final now = DateTime.now();
    final trimmed = (note?.trim().isEmpty ?? true) ? null : note!.trim();
    _incidents[incident.id] = incident.copyWith(
      status: to,
      updatedAt: now,
      resolutionNote: to == IncidentStatus.resolved ? trimmed : null,
      clearResolution: to != IncidentStatus.resolved,
    );
    (_history[incident.id] ??= []).add(StatusChange(
        from: incident.status, to: to, byName: by.name, at: now, note: trimmed));
    (_notifications[incident.reporterId] ??= []).add(AppNotification(
      id: 'n-${_nextId++}',
      incidentId: incident.id,
      title: '${incident.title} is now ${to.label}',
      message: trimmed ?? 'Updated by ${by.name}',
      at: now,
    ));
    _notify();
  }

  @override
  Future<void> setPriority(String id, IncidentPriority priority) async {
    await Future.delayed(latency ~/ 2);
    final i = _incidents[id];
    if (i == null) return;
    _incidents[id] = i.copyWith(priority: priority, updatedAt: DateTime.now());
    _notify();
  }

  @override
  Future<void> setHidden(String id, bool hidden) async {
    await Future.delayed(latency ~/ 2);
    final i = _incidents[id];
    if (i == null) return;
    _incidents[id] = i.copyWith(isHidden: hidden, updatedAt: DateTime.now());
    _notify();
  }

  @override
  Future<void> markNotificationRead(String uid, String notificationId) async {
    final list = _notifications[uid];
    if (list == null) return;
    final i = list.indexWhere((n) => n.id == notificationId);
    if (i < 0 || list[i].read) return;
    final n = list[i];
    list[i] = AppNotification(
        id: n.id,
        incidentId: n.incidentId,
        title: n.title,
        message: n.message,
        at: n.at,
        read: true);
    _notify();
  }

  void _seed() {
    final now = DateTime.now();
    void add(
      String title,
      String description,
      IncidentCategory category,
      String location,
      List<IncidentStatus> path,
      Duration age, {
      String reporterId = 'u-amina',
      String reporterName = 'Amina Hassan',
      IncidentPriority priority = IncidentPriority.medium,
      bool anonymous = false,
      String? resolution,
    }) {
      final id = 'inc-${_nextId++}';
      final created = now.subtract(age);
      final steps = <StatusChange>[];
      for (var i = 0; i < path.length; i++) {
        steps.add(StatusChange(
          from: i == 0 ? null : path[i - 1],
          to: path[i],
          byName: i == 0 ? reporterName : 'David Mugisha',
          at: created.add(Duration(hours: i * 5)),
          note: i == path.length - 1 ? resolution : null,
        ));
      }
      _history[id] = steps;
      _incidents[id] = Incident(
        id: id,
        title: title,
        description: description,
        category: category,
        location: location,
        status: path.last,
        priority: priority,
        reporterId: reporterId,
        reporterName: reporterName,
        isAnonymous: anonymous,
        resolutionNote: resolution,
        createdAt: created,
        updatedAt: steps.last.at,
      );
    }

    const s = IncidentStatus.submitted;
    const r = IncidentStatus.inReview;
    const p = IncidentStatus.inProgress;
    const d = IncidentStatus.resolved;

    add('Water shortage',
        'There has been no water supply in the student residence since this morning. This is affecting many students on the 2nd floor.',
        IncidentCategory.water, 'Student Residence', [s], const Duration(hours: 2),
        priority: IncidentPriority.high);
    add('Broken classroom projector',
        'The projector in room 204 flickers and turns off after a few minutes, interrupting lectures.',
        IncidentCategory.facilities, 'Block B', [s, r, p], const Duration(days: 1));
    add('Overflowing bin',
        'The large bin next to the cafeteria entrance has not been emptied for two days and smells.',
        IncidentCategory.sanitation, 'Cafeteria', [s, r, p, d], const Duration(days: 3),
        resolution: 'Bin emptied and collection schedule moved to daily.');
    add('Flickering corridor lights',
        'Lights on the ground floor corridor flicker all evening; it is hard to see at night.',
        IncidentCategory.electricity, 'Block A', [s, r], const Duration(hours: 9),
        reporterId: 'u-other', reporterName: 'Kevin Otieno');
    add('Broken chair in library',
        'One of the study chairs near the window has a broken leg and is unsafe to sit on.',
        IncidentCategory.furniture, 'Library', [s], const Duration(hours: 20),
        reporterId: 'u-other2', reporterName: 'Grace Uwase', priority: IncidentPriority.low);
    add('Main gate light out',
        'The light at the main gate is off, making the entrance very dark after 7pm.',
        IncidentCategory.safety, 'Main Gate', [s, r, p], const Duration(days: 2),
        reporterId: 'u-other', reporterName: 'Anonymous student', anonymous: true,
        priority: IncidentPriority.high);
    add('Power outage in lab',
        'Sockets in the computer lab have no power since the storm yesterday.',
        IncidentCategory.electricity, 'Block C', [s, r, p, d], const Duration(days: 5),
        reporterId: 'u-other2', reporterName: 'Grace Uwase',
        resolution: 'Tripped breaker reset and inspected.');
  }
}
