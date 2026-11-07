import 'package:campusfix/core/utils/formatters.dart';
import 'package:campusfix/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('accepts campus domain, case-insensitive', () {
      expect(Validators.email('amina@alustudent.com'), isNull);
      expect(Validators.email('  Amina@ALUSTUDENT.com '), isNull);
    });
    test('rejects other domains and bad input', () {
      expect(Validators.email('a@gmail.com'), contains('alustudent.com'));
      expect(Validators.email('a@alustudent.com.evil.io'), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email(''), 'Email is required');
    });
  });

  test('password, title and description lengths', () {
    expect(Validators.password('short'), isNotNull);
    expect(Validators.password('longenough'), isNull);
    expect(Validators.title('ab'), isNotNull);
    expect(Validators.title('Leaking tap'), isNull);
    expect(Validators.description('too short'), isNotNull);
    expect(Validators.description('Water leaking under the sink.'), isNull);
  });

  group('timeAgo', () {
    final now = DateTime(2026, 11, 7, 12);
    test('relative ranges', () {
      expect(timeAgo(now, now: now), 'Just now');
      expect(timeAgo(now.subtract(const Duration(minutes: 1)), now: now), '1 min ago');
      expect(timeAgo(now.subtract(const Duration(hours: 2)), now: now), '2 hours ago');
      expect(timeAgo(now.subtract(const Duration(days: 1)), now: now), '1 day ago');
      expect(timeAgo(DateTime(2026, 10, 1), now: now), 'Oct 1, 2026');
    });
  });

  test('initials', () {
    expect(initials('Amina Hassan'), 'AH');
    expect(initials('  grace  '), 'G');
  });
}
