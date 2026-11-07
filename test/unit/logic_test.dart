import 'package:campusfix/data/models/app_user.dart';
import 'package:campusfix/data/models/enums.dart';
import 'package:campusfix/data/models/incident.dart';
import 'package:campusfix/data/repositories/fake_incident_repository.dart';
import 'package:campusfix/logic/incident_providers.dart';
import 'package:flutter_test/flutter_test.dart';

Incident _incident(String id,
    {IncidentStatus status = IncidentStatus.submitted,
    IncidentCategory category = IncidentCategory.water,
    String title = 'Leak',
    String reporter = 'u1',
    bool hidden = false}) {
  final t = DateTime(2026);
  return Incident(
    id: id,
    title: title,
    description: 'desc',
    category: category,
    location: 'Library',
    status: status,
    priority: IncidentPriority.medium,
    reporterId: reporter,
    reporterName: 'R',
    isHidden: hidden,
    createdAt: t,
    updatedAt: t,
  );
}

const _student = AppUser(
    uid: 'u1', name: 'S', email: 's@alustudent.com', role: UserRole.student,
    department: 'x', emailVerified: true);
const _staff = AppUser(
    uid: 'st', name: 'T', email: 't@alustudent.com', role: UserRole.staff,
    department: 'x', emailVerified: true);

void main() {
  final list = [
    _incident('1', title: 'Broken projector', category: IncidentCategory.facilities),
    _incident('2', status: IncidentStatus.resolved),
    _incident('3', status: IncidentStatus.inProgress, title: 'Dark gate'),
  ];

  test('IncidentFilter combines status, category and query', () {
    expect(const IncidentFilter().apply(list).length, 3);
    expect(const IncidentFilter(status: IncidentStatus.resolved).apply(list).map((i) => i.id), ['2']);
    expect(const IncidentFilter(category: IncidentCategory.water).apply(list).length, 2);
    expect(const IncidentFilter(query: 'PROJ').apply(list).map((i) => i.id), ['1']);
    expect(const IncidentFilter(query: 'library').apply(list).length, 3);
  });

  test('ReportStats counts per status', () {
    final s = ReportStats.of(list);
    expect(s.total, 3);
    expect(s[IncidentStatus.resolved], 1);
    expect(s.open, 2);
  });

  test('hidden reports visible only to staff and owner', () {
    final items = [_incident('a', hidden: true, reporter: 'other'), _incident('b', hidden: true)];
    expect(visibleTo(_student, items).map((i) => i.id), ['b']);
    expect(visibleTo(_staff, items).length, 2);
    expect(visibleTo(null, items), isEmpty);
  });

  test('changeStatus writes incident, history and reporter notification', () async {
    final repo = FakeIncidentRepository(latency: Duration.zero, seed: false);
    final id = await repo.create(draft: _incident(''));
    final created = (await repo.watchOne(id).first)!;

    await repo.changeStatus(
        incident: created, to: IncidentStatus.resolved, by: _staff, note: ' Fixed ');

    final updated = (await repo.watchOne(id).first)!;
    expect(updated.status, IncidentStatus.resolved);
    expect(updated.resolutionNote, 'Fixed');
    final history = await repo.watchHistory(id).first;
    expect(history.map((h) => h.to), [IncidentStatus.submitted, IncidentStatus.resolved]);
    final notes = await repo.watchNotifications('u1').first;
    expect(notes.single.read, isFalse);
  });
}
