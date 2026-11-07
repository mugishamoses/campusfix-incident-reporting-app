import 'dart:async';

import '../models/app_user.dart';
import '../models/enums.dart';
import 'auth_repository.dart';

/// In-memory auth for UI development and tests.
/// shortcut: no persistence, replaced by FirebaseAuthRepository in Phase 3.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.latency = const Duration(milliseconds: 700)});

  final Duration latency;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  final Map<String, ({String password, AppUser user})> _accounts = {
    'amina@alustudent.com': (
      password: 'password',
      user: const AppUser(
        uid: 'u-amina',
        name: 'Amina Hassan',
        email: 'amina@alustudent.com',
        role: UserRole.student,
        department: 'Computer Science',
        emailVerified: true,
      ),
    ),
    'staff@alustudent.com': (
      password: 'password',
      user: const AppUser(
        uid: 'u-staff',
        name: 'David Mugisha',
        email: 'staff@alustudent.com',
        role: UserRole.staff,
        department: 'Facilities Office',
        emailVerified: true,
      ),
    ),
  };

  void _emit(AppUser? user) {
    _current = user;
    _controller.add(user);
  }

  @override
  Stream<AppUser?> authStateChanges() => Stream.multi((sink) {
        // Subscribe synchronously so no event between "current" and "next" is lost.
        sink.add(_current);
        final sub = _controller.stream.listen(sink.add);
        sink.onCancel = sub.cancel;
      });

  @override
  Future<void> signIn({required String email, required String password}) async {
    await Future.delayed(latency);
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AppFailure('Incorrect email or password.');
    }
    _emit(account.user);
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String department,
  }) async {
    await Future.delayed(latency);
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AppFailure('An account with this email already exists.');
    }
    final user = AppUser(
      uid: 'u-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      email: key,
      role: UserRole.student,
      department: department.trim(),
      emailVerified: false,
    );
    _accounts[key] = (password: password, user: user);
    _emit(user);
  }

  @override
  Future<void> sendEmailVerification() => Future.delayed(latency);

  /// Simulates the user having clicked the verification link.
  @override
  Future<void> reloadUser() async {
    await Future.delayed(latency);
    final user = _current;
    if (user == null) return;
    final verified = user.copyWith(emailVerified: true);
    _accounts[user.email] = (
      password: _accounts[user.email]!.password,
      user: verified,
    );
    _emit(verified);
  }

  @override
  Future<void> sendPasswordReset(String email) => Future.delayed(latency);

  @override
  Future<void> signOut() async => _emit(null);
}
