import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui/pages/bodyweight/bodyweight_page.dart';
import 'ui/pages/goals/goals_page.dart';
import 'ui/pages/history/history_detail_page.dart';
import 'ui/pages/history/history_page.dart';
import 'ui/pages/insights/insights_page.dart';
import 'ui/pages/library/exercise_detail_page.dart';
import 'ui/pages/library/library_page.dart';
import 'ui/pages/onboarding/onboarding_page.dart';
import 'ui/pages/plate_calc/plate_calc_page.dart';
import 'ui/pages/session/active_session_page.dart';
import 'ui/pages/session/exercise_picker_page.dart';
import 'ui/pages/session/log_set_page.dart';
import 'ui/pages/session/muscle_picker_page.dart';
import 'ui/pages/session/summary_page.dart';
import 'ui/pages/session/whats_next_page.dart';
import 'ui/pages/settings/settings_page.dart';
import 'ui/pages/today/today_page.dart';
import 'ui/shell.dart';

const onboardingDoneKey = 'peak.onboarded';

final onboardingDoneProvider = StateProvider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  final onboarded = ref.watch(onboardingDoneProvider);

  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) {
      final goingToOnboarding = state.matchedLocation == '/onboarding';
      if (!onboarded && !goingToOnboarding) return '/onboarding';
      if (onboarded && goingToOnboarding) return '/today';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/today', builder: (_, __) => const TodayPage()),
          GoRoute(path: '/insights', builder: (_, __) => const InsightsPage()),
          GoRoute(path: '/history', builder: (_, __) => const HistoryPage()),
          GoRoute(path: '/library', builder: (_, __) => const LibraryPage()),
        ],
      ),
      GoRoute(
        path: '/history/:id',
        builder: (_, state) => HistoryDetailPage(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/library/:id',
        builder: (_, state) => ExerciseDetailPage(exerciseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/session/:id',
        builder: (_, state) => ActiveSessionPage(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/session/:id/muscle',
        builder: (_, state) => MusclePickerPage(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/session/:id/exercise',
        builder: (_, state) => ExercisePickerPage(
          sessionId: state.pathParameters['id']!,
          muscle: state.uri.queryParameters['muscle']!,
        ),
      ),
      GoRoute(
        path: '/session/:id/log',
        builder: (_, state) => LogSetPage(
          sessionId: state.pathParameters['id']!,
          entryId: state.uri.queryParameters['entryId']!,
        ),
      ),
      GoRoute(
        path: '/session/:id/whats-next',
        builder: (_, state) => WhatsNextPage(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/session/:id/summary',
        builder: (_, state) => SummaryPage(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      GoRoute(path: '/goals', builder: (_, __) => const GoalsPage()),
      GoRoute(path: '/bodyweight', builder: (_, __) => const BodyWeightPage()),
      GoRoute(path: '/plate-calc', builder: (_, __) => const PlateCalcPage()),
    ],
  );
});

/// Reads the persisted onboarding flag at startup and pushes into the provider.
Future<bool> readOnboardedFlag() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(onboardingDoneKey) ?? false;
}

Future<void> markOnboarded() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(onboardingDoneKey, true);
}

Future<void> resetOnboarded() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(onboardingDoneKey, false);
}
