// Renders real app screens (fake backend, real fonts) to PNGs for the report.
// Run: flutter test tool/screenshots_test.dart --update-goldens
// Output: docs/screenshots/*.png
import 'dart:io';

import 'package:campusfix/core/router/app_router.dart';
import 'package:campusfix/core/theme/app_theme.dart';
import 'package:campusfix/data/models/enums.dart';
import 'package:campusfix/data/repositories/fake_auth_repository.dart';
import 'package:campusfix/data/repositories/fake_incident_repository.dart';
import 'package:campusfix/logic/auth_providers.dart';
import 'package:campusfix/logic/incident_actions.dart';
import 'package:campusfix/logic/incident_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _sdkFonts = 'bin/cache/artifacts/material_fonts';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader.addFont(Future.value(ByteData.sublistView(Uint8List.fromList(File(p).readAsBytesSync()))));
  }
  await loader.load();
}

class _Shot {
  _Shot(this.tester, this.container);
  final WidgetTester tester;
  final ProviderContainer container;

  Future<void> settle() async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> go(String path) async {
    container.read(routerProvider).go(path);
    await settle();
  }

  Future<void> push(String path) async {
    container.read(routerProvider).push(path);
    await settle();
  }

  Future<void> save(String name) =>
      expectLater(find.byKey(const ValueKey('shot')), matchesGoldenFile('../docs/screenshots/$name.png'));
}

Future<_Shot> _boot(WidgetTester tester, {String? as}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final auth = FakeAuthRepository(latency: Duration.zero);
  final repo = FakeIncidentRepository(latency: Duration.zero);
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(auth),
    incidentRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: RepaintBoundary(
      key: const ValueKey('shot'),
      child: Consumer(
        builder: (_, ref, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(fontFamily: 'Jakarta'),
          routerConfig: ref.watch(routerProvider),
        ),
      ),
    ),
  ));
  final shot = _Shot(tester, container);
  await shot.settle();
  if (as != null) {
    await tester.runAsync(() => auth.signIn(email: as, password: 'password'));
    await shot.settle();
  }
  return shot;
}

void main() {
  setUpAll(() async {
    final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
    await _loadFont('Jakarta', [
      for (final w in [400, 500, 600, 700, 800]) 'tool/fonts/PlusJakartaSans-$w.ttf',
    ]);
    await _loadFont('MaterialIcons', ['$flutterRoot/$_sdkFonts/MaterialIcons-Regular.otf']);
    await _loadFont('Roboto', ['$flutterRoot/$_sdkFonts/Roboto-Regular.ttf']);
  });

  const student = 'amina@alustudent.com';
  const staff = 'staff@alustudent.com';

  testWidgets('01 login', (t) async {
    final s = await _boot(t);
    await s.save('01_login');
  });

  testWidgets('02 register', (t) async {
    final s = await _boot(t);
    await s.push(Routes.register);
    await s.save('02_register');
  });

  testWidgets('03 verify email', (t) async {
    final s = await _boot(t);
    await t.runAsync(() => s.container.read(authRepositoryProvider).register(
        name: 'Jean Uwimana', email: 'jean@alustudent.com', password: 'password12', department: 'Business'));
    await s.settle();
    await s.save('03_verify_email');
  });

  testWidgets('04 student home', (t) async {
    final s = await _boot(t, as: student);
    await s.save('04_home');
  });

  testWidgets('05 report form', (t) async {
    final s = await _boot(t, as: student);
    await s.push(Routes.newReport);
    s.container.read(reportFormProvider.notifier)
      ..setCategory(IncidentCategory.electricity)
      ..setLocation('Block B');
    await t.enterText(find.byType(TextFormField).at(0), 'Sockets not working in room 204');
    await t.enterText(find.byType(TextFormField).at(1),
        'None of the wall sockets on the left side of room 204 have power since this morning. Students cannot charge laptops during class.');
    FocusManager.instance.primaryFocus?.unfocus();
    await s.settle();
    await s.save('05_report_form');
  });

  testWidgets('06 report form validation', (t) async {
    final s = await _boot(t, as: student);
    await s.push(Routes.newReport);
    await t.scrollUntilVisible(find.text('Submit Report'), 300, scrollable: find.byType(Scrollable).last);
    await t.tap(find.text('Submit Report'));
    await s.settle();
    await t.drag(find.byType(ListView), const Offset(0, 3000)); // back to top to show the errors
    await s.settle();
    await s.save('06_report_validation');
  });

  testWidgets('07 campus feed filtered', (t) async {
    final s = await _boot(t, as: student);
    await s.go(Routes.reports);
    s.container.read(feedFilterProvider.notifier).setStatus(IncidentStatus.inProgress);
    await s.settle();
    await s.save('07_feed_filtered');
  });

  testWidgets('08 incident details (student)', (t) async {
    final s = await _boot(t, as: student);
    await s.push(Routes.incident('inc-101'));
    await s.save('08_details_student');
  });

  testWidgets('09 my reports', (t) async {
    final s = await _boot(t, as: student);
    await s.go(Routes.profile);
    await s.save('09_my_reports');
  });

  testWidgets('10 notifications', (t) async {
    final s = await _boot(t, as: student);
    final repo = s.container.read(incidentRepositoryProvider);
    final mine = s.container.read(myIncidentsProvider).value!;
    final staffUser = (await t.runAsync(() async {
      final a = FakeAuthRepository(latency: Duration.zero);
      await a.signIn(email: staff, password: 'password');
      return a.authStateChanges().first;
    }))!;
    await t.runAsync(() async {
      await repo.changeStatus(incident: mine.first, to: IncidentStatus.inReview, by: staffUser, note: 'Plumber assigned, arriving at 2pm.');
    });
    await s.settle();
    await s.push(Routes.notifications);
    await s.save('10_notifications');
  });

  testWidgets('11 staff dashboard', (t) async {
    final s = await _boot(t, as: staff);
    await s.save('11_staff_dashboard');
  });

  testWidgets('12 incident details (staff controls)', (t) async {
    final s = await _boot(t, as: staff);
    await s.push(Routes.incident('inc-100'));
    await t.tap(find.text('In Review').last);
    await s.settle();
    await s.save('12_details_staff');
  });
}
