import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../logic/auth_providers.dart';
import '../../ui/screens/auth/auth_screens.dart';
import '../../ui/screens/auth/splash_screen.dart';
import '../../ui/screens/shared/incident_details_screen.dart';
import '../../ui/screens/shared/notifications_screen.dart';
import '../../ui/screens/shared/profile_screen.dart';
import '../../ui/screens/shell/app_shell.dart';
import '../../ui/screens/staff/staff_dashboard_screen.dart';
import '../../ui/screens/student/feed_screen.dart';
import '../../ui/screens/student/home_screen.dart';
import '../../ui/screens/student/report_form_screen.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgot = '/forgot';
  static const verify = '/verify';
  static const home = '/home';
  static const reports = '/reports';
  static const profile = '/profile';
  static const newReport = '/report/new';
  static const notifications = '/notifications';
  static String incident(String id) => '/incident/$id';
  static String editReport(String id) => '/report/edit/$id';
}

const _publicRoutes = {Routes.login, Routes.register, Routes.forgot};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loc = state.matchedLocation;
      if (auth.isLoading && !auth.hasValue) return Routes.splash;
      final user = auth.value;
      if (user == null) return _publicRoutes.contains(loc) ? null : Routes.login;
      if (!user.emailVerified) return loc == Routes.verify ? null : Routes.verify;
      if (_publicRoutes.contains(loc) || loc == Routes.verify || loc == Routes.splash) {
        return Routes.home;
      }
      // Students can't open staff-only screens; staff don't file reports.
      if (user.isStaff && loc.startsWith('/report/')) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: Routes.forgot, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: Routes.verify, builder: (_, _) => const VerifyEmailScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, _) => Consumer(
                builder: (_, ref, _) => ref.watch(currentUserProvider)?.isStaff ?? false
                    ? const StaffDashboardScreen()
                    : const HomeScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.reports, builder: (_, _) => const FeedScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: Routes.newReport,
        pageBuilder: (_, _) => const MaterialPage(
            fullscreenDialog: true, child: ReportFormScreen()),
      ),
      GoRoute(
        path: '/report/edit/:id',
        builder: (_, s) => ReportFormScreen(editId: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/incident/:id',
        builder: (_, s) => IncidentDetailsScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
          path: Routes.notifications,
          builder: (_, _) => const NotificationsScreen()),
    ],
  );
});
