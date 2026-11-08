import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/enums.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) => _db.doc('users/$uid');

  /// Auth user joined with `users/{uid}` (role); also fires after `reload()`.
  @override
  Stream<AppUser?> authStateChanges() {
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? profileSub;
    late final StreamController<AppUser?> controller;
    StreamSubscription<User?>? authSub;
    controller = StreamController<AppUser?>(
      onListen: () {
        authSub = _auth.userChanges().listen((user) {
          profileSub?.cancel();
          if (user == null) {
            controller.add(null);
            return;
          }
          profileSub = _userDoc(user.uid).snapshots().listen(
                (snap) => controller.add(_toAppUser(user, snap.data())),
                onError: controller.addError,
              );
        }, onError: controller.addError);
      },
      onCancel: () async {
        await profileSub?.cancel();
        await authSub?.cancel();
      },
    );
    return controller.stream;
  }

  AppUser _toAppUser(User user, Map<String, dynamic>? data) => AppUser(
        uid: user.uid,
        // Profile doc may not exist for a split second right after sign-up.
        name: data?['name'] as String? ?? user.displayName ?? '',
        email: user.email ?? '',
        role: enumByName(UserRole.values, data?['role'], UserRole.student),
        department: data?['department'] as String? ?? '',
        emailVerified: user.emailVerified,
      );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AppFailure(_message(e.code));
    } on FirebaseException catch (e) {
      throw AppFailure(messageForCode(e.code));
    }
  }

  static String _message(String code) => switch (code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-email' =>
          'Incorrect email or password.',
        'email-already-in-use' => 'An account with this email already exists.',
        'weak-password' => 'Choose a stronger password.',
        'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
        'network-request-failed' => 'You appear to be offline. Check your connection.',
        'user-disabled' => 'This account has been disabled.',
        _ => 'Authentication failed ($code).',
      };

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(() => _auth.signInWithEmailAndPassword(email: email, password: password));

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String department,
  }) =>
      _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        final user = cred.user!;
        await user.updateDisplayName(name.trim());
        // Role is always "student" — security rules reject anything else.
        await _userDoc(user.uid).set({
          'name': name.trim(),
          'email': email.toLowerCase(),
          'department': department.trim(),
          'role': UserRole.student.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

  @override
  Future<void> sendEmailVerification() =>
      _guard(() async => _auth.currentUser?.sendEmailVerification());

  @override
  Future<void> reloadUser() => _guard(() async {
        final user = _auth.currentUser;
        if (user == null) return;
        await user.reload();
        // Refresh the ID token so security rules see email_verified = true.
        await user.getIdToken(true);
      });

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email));

  @override
  Future<void> signOut() => _auth.signOut();
}
