import 'package:campusfix/data/repositories/fake_auth_repository.dart';
import 'package:campusfix/data/repositories/fake_incident_repository.dart';
import 'package:campusfix/logic/auth_providers.dart';
import 'package:campusfix/logic/incident_providers.dart';
import 'package:campusfix/ui/screens/student/report_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpForm(WidgetTester tester) async {
  // Tall viewport so the whole (lazily built) form is on screen at once.
  tester.view.physicalSize = const Size(1200, 6000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(latency: Duration.zero)),
      incidentRepositoryProvider.overrideWithValue(FakeIncidentRepository(latency: Duration.zero)),
    ],
    child: const MaterialApp(home: ReportFormScreen()),
  ));
  await tester.pump();
  await tester.tap(find.text('Submit Report'));
  await tester.pump();
}

void main() {
  testWidgets('empty submit flags category, title, description and location', (tester) async {
    await pumpForm(tester);
    expect(find.text('Choose a category'), findsOneWidget);
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Description is required'), findsOneWidget);
    expect(find.text('Choose a location'), findsOneWidget);
    expect(find.text('Please complete the highlighted fields.'), findsOneWidget);
  });

  testWidgets('choosing a category clears its error', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.text('Water'));
    await tester.pump();
    expect(find.text('Choose a category'), findsNothing);
  });
}
