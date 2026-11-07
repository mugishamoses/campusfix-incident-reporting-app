import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';

import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/fake_auth_repository.dart';
import '../data/repositories/firebase_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AppConfig.fakeBackend
    ? FakeAuthRepository()
    : FirebaseAuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance));

final authStateProvider = StreamProvider<AppUser?>(
    (ref) => ref.watch(authRepositoryProvider).authStateChanges());

/// Signed-in user, or null while loading / signed out.
final currentUserProvider =
    Provider<AppUser?>((ref) => ref.watch(authStateProvider).value);

/// Runs auth actions and exposes their loading/error state to the UI.
class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _repo.signIn(email: email.trim(), password: password));

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String department,
  }) =>
      _run(() async {
        await _repo.register(
            name: name, email: email.trim(), password: password, department: department);
        await _repo.sendEmailVerification();
      });

  Future<bool> resendVerification() => _run(_repo.sendEmailVerification);

  Future<bool> reloadUser() => _run(_repo.reloadUser);

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _repo.sendPasswordReset(email.trim()));

  Future<bool> signOut() => _run(_repo.signOut);
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

/// Turns any error into a message the user can read.
String errorMessage(Object? error) => switch (error) {
      AppFailure(:final message) => message,
      _ => 'Something went wrong. Please try again.',
    };
