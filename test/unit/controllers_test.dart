import 'package:campusfix/data/models/app_failure.dart';
import 'package:campusfix/data/models/enums.dart';
import 'package:campusfix/data/repositories/fake_auth_repository.dart';
import 'package:campusfix/data/repositories/fake_incident_repository.dart';
import 'package:campusfix/logic/auth_providers.dart';
import 'package:campusfix/logic/incident_actions.dart';
import 'package:campusfix/logic/incident_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Container on fakes, signed in as [email], with live streams kept alive.
Future<ProviderContainer> signedIn(String email) async {
  final auth = FakeAuthRepository(latency: Duration.zero);
  final c = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(auth),
    incidentRepositoryProvider
        .overrideWithValue(FakeIncidentRepository(latency: Duration.zero, seed: false)),
  ]);
  addTearDown(c.dispose);
  c.listen(myIncidentsProvider, (_, _) {});
  c.listen(visibleIncidentsProvider, (_, _) {});
  c.listen(notificationsProvider, (_, _) {});
  await auth.signIn(email: email, password: 'password');
  await pumpEventQueue();
  return c;
}

Future<String> submit(ProviderContainer c, {bool anonymous = false}) {
  final form = c.read(reportFormProvider.notifier)
    ..reset()
    ..setCategory(IncidentCategory.water)
    ..setLocation('Library')
    ..setAnonymous(anonymous);
  return form.submit(title: 'Leaking tap', description: 'Water under the sink all day.');
}

void main() {
  test('submit requires category and location', () async {
    final c = await signedIn('amina@alustudent.com');
    final form = c.read(reportFormProvider.notifier)..reset();
    await expectLater(form.submit(title: 'Leak', description: 'Long enough text'),
        throwsA(isA<AppFailure>()));
  });

  test('anonymous report never stores the real name', () async {
    final c = await signedIn('amina@alustudent.com');
    await submit(c, anonymous: true);
    await pumpEventQueue();
    final mine = c.read(myIncidentsProvider).value!;
    expect(mine.single.reporterName, 'Anonymous student');
    expect(mine.single.reporterId, 'u-amina'); // still tracked for rate limit / ownership
  });

  test('open-report limit blocks the 6th open report', () async {
    final c = await signedIn('amina@alustudent.com');
    for (var i = 0; i < 5; i++) {
      await submit(c);
      await pumpEventQueue();
    }
    await expectLater(submit(c), throwsA(isA<AppFailure>()));
  });

  test('students cannot change status', () async {
    final c = await signedIn('amina@alustudent.com');
    await submit(c);
    await pumpEventQueue();
    final incident = c.read(myIncidentsProvider).value!.single;
    expect(await c.read(incidentActionsProvider.notifier)
        .changeStatus(incident, IncidentStatus.resolved, null), isFalse);
  });

  test('staff status change updates incident and history', () async {
    final c = await signedIn('staff@alustudent.com');
    final repo = c.read(incidentRepositoryProvider);
    final id = await submit(c); // fake has no rules; prod rules are covered in rules-test/
    await pumpEventQueue();
    final incident = c.read(visibleIncidentsProvider).value!.single;
    expect(await c.read(incidentActionsProvider.notifier)
        .changeStatus(incident, IncidentStatus.inProgress, 'On it'), isTrue);
    final history = await repo.watchHistory(id).first;
    expect(history.last.to, IncidentStatus.inProgress);
    expect(history.last.note, 'On it');
  });
}
