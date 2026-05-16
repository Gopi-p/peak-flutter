import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/providers.dart';
import 'router.dart';
import 'services/notification_service.dart';
import 'ui/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await NotificationService.instance.init();
  final onboarded = await readOnboardedFlag();

  runApp(ProviderScope(
    overrides: [
      onboardingDoneProvider.overrideWith((ref) => onboarded),
    ],
    child: const PeakApp(),
  ));
}

class PeakApp extends ConsumerWidget {
  const PeakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(exerciseCatalogProvider);
    return catalogAsync.when(
      loading: () => MaterialApp(
        theme: buildPeakTheme(),
        debugShowCheckedModeBanner: false,
        home: const _SplashScreen(),
      ),
      error: (e, _) => MaterialApp(
        theme: buildPeakTheme(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: Text('Boot failed: $e'))),
      ),
      data: (_) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          title: 'Peak',
          debugShowCheckedModeBanner: false,
          theme: buildPeakTheme(),
          darkTheme: buildPeakTheme(),
          themeMode: ThemeMode.dark,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
