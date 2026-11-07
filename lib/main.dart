import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppConfig.fakeBackend) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  runApp(const ProviderScope(child: CampusFixApp()));
}

class CampusFixApp extends ConsumerWidget {
  const CampusFixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: ref.watch(routerProvider),
        builder: (context, child) => _PhoneFrame(child: child!),
      );
}

/// On wide screens (web/desktop/tablet) keep the phone-designed UI at phone width.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= 600) return child;
    const width = 440.0;
    return ColoredBox(
      color: const Color(0xFFE9E4F5),
      child: Center(
        child: Container(
          width: width,
          margin: const EdgeInsets.symmetric(vertical: 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Color(0x332A1259), blurRadius: 40, offset: Offset(0, 12))],
          ),
          child: MediaQuery(data: mq.copyWith(size: Size(width, mq.size.height - 32)), child: child),
        ),
      ),
    );
  }
}
