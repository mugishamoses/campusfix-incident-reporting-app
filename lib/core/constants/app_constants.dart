abstract final class AppConstants {
  static const appName = 'CampusFix';
  static const tagline = 'See it. Report it. Get it fixed.';

  /// Only verified campus emails may register.
  static const allowedEmailDomains = ['alustudent.com'];

  /// Anti-abuse: a student can't have more than this many unresolved reports.
  static const maxOpenReportsPerStudent = 5;

  static const titleMin = 3;
  static const titleMax = 80;
  static const descriptionMin = 10;
  static const descriptionMax = 1000;
  static const passwordMin = 8;

  static const campusLocations = [
    'Block A',
    'Block B',
    'Block C',
    'Library',
    'Cafeteria',
    'Student Residence',
    'Sports Ground',
    'Main Gate',
    'Parking Lot',
    'Admin Building',
  ];
}

abstract final class AppConfig {
  /// Real Firebase by default. Offline UI demo with seeded data:
  /// `flutter run --dart-define=FAKE_BACKEND=true`.
  static const fakeBackend = bool.fromEnvironment('FAKE_BACKEND');
}
