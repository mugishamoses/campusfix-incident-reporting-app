import '../models/app_user.dart';

export '../models/app_failure.dart';

abstract interface class AuthRepository {
  /// Emits the signed-in user (with role), or null when signed out.
  Stream<AppUser?> authStateChanges();

  Future<void> signIn({required String email, required String password});

  /// Always creates a `student`; staff are promoted from the Firebase console.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String department,
  });

  Future<void> sendEmailVerification();

  /// Re-fetches the user so a freshly clicked verification link is picked up.
  Future<void> reloadUser();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
