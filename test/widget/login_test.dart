import 'package:campusfix/data/repositories/fake_auth_repository.dart';
import 'package:campusfix/logic/auth_providers.dart';
import 'package:campusfix/ui/screens/auth/auth_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository(latency: Duration.zero)),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ));

  testWidgets('shows validation errors for empty and non-campus email', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'me@gmail.com');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Use your @alustudent.com email'), findsOneWidget);
  });

  testWidgets('wrong password shows an error snackbar', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'amina@alustudent.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });
}
