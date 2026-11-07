import 'enums.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.emailVerified,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final bool emailVerified;

  bool get isStaff => role == UserRole.staff;

  AppUser copyWith({bool? emailVerified}) => AppUser(
        uid: uid,
        name: name,
        email: email,
        role: role,
        department: department,
        emailVerified: emailVerified ?? this.emailVerified,
      );
}
