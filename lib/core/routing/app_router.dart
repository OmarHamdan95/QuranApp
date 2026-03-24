import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/audio/presentation/screens/audio_player_screen.dart';
import '../../features/bookmarks/presentation/screens/bookmarks_screen.dart';
import '../../features/bookmarks/presentation/screens/favorites_screen.dart';
import '../../features/downloads/presentation/screens/downloads_manager_screen.dart';
import '../../features/hifz/presentation/screens/hifz_dashboard_screen.dart';
import '../../features/hifz/presentation/screens/hifz_plan_setup_screen.dart';
import '../../features/hifz/presentation/screens/self_test_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/mosabqat/presentation/screens/daily_challenge_screen.dart';
import '../../features/mosabqat/presentation/screens/mosabqat_home_screen.dart';
import '../../features/mosabqat/presentation/screens/mosabqat_stats_screen.dart';
import '../../features/mosabqat/presentation/screens/quiz_play_screen.dart';
import '../../features/mosabqat/presentation/screens/quiz_results_screen.dart';
import '../../features/mosabqat/presentation/screens/quiz_setup_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/prayer/presentation/screens/prayer_times_screen.dart';
import '../../features/prayer/presentation/screens/qibla_compass_screen.dart';
import '../../features/quran/presentation/screens/juz_index_screen.dart';
import '../../features/quran/presentation/screens/quran_reader_screen.dart';
import '../../features/quran/presentation/screens/surah_index_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tafsir/presentation/screens/tafsir_view_screen.dart';
import '../../shared/widgets/app_scaffold.dart';

/// Route path constants.
abstract final class RoutePaths {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String surahIndex = '/quran/surahs';
  static const String juzIndex = '/quran/juz';
  static const String quranReader = '/quran/read/:surahNumber';
  static const String audioPlayer = '/audio';
  static const String bookmarks = '/bookmarks';
  static const String favorites = '/favorites';
  static const String tafsir = '/tafsir/:surahNumber/:ayahNumber';
  static const String search = '/search';
  static const String prayerTimes = '/prayer';
  static const String qibla = '/prayer/qibla';
  static const String hifzDashboard = '/hifz';
  static const String hifzPlanSetup = '/hifz/plan';
  static const String selfTest = '/hifz/test';
  static const String mosabqatHome = '/mosabqat';
  static const String quizSetup = '/mosabqat/setup';
  static const String quizPlay = '/mosabqat/play';
  static const String quizResults = '/mosabqat/results';
  static const String dailyChallenge = '/mosabqat/daily';
  static const String mosabqatStats = '/mosabqat/stats';
  static const String settings = '/settings';
  static const String downloads = '/downloads';
}

/// Route name constants for named navigation.
abstract final class RouteNames {
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String home = 'home';
  static const String surahIndex = 'surahIndex';
  static const String juzIndex = 'juzIndex';
  static const String quranReader = 'quranReader';
  static const String audioPlayer = 'audioPlayer';
  static const String bookmarks = 'bookmarks';
  static const String favorites = 'favorites';
  static const String tafsir = 'tafsir';
  static const String search = 'search';
  static const String prayerTimes = 'prayerTimes';
  static const String qibla = 'qibla';
  static const String hifzDashboard = 'hifzDashboard';
  static const String hifzPlanSetup = 'hifzPlanSetup';
  static const String selfTest = 'selfTest';
  static const String mosabqatHome = 'mosabqatHome';
  static const String quizSetup = 'quizSetup';
  static const String quizPlay = 'quizPlay';
  static const String quizResults = 'quizResults';
  static const String dailyChallenge = 'dailyChallenge';
  static const String mosabqatStats = 'mosabqatStats';
  static const String settings = 'settings';
  static const String downloads = 'downloads';
}

// Navigator keys for shell route branches.
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorQuranKey = GlobalKey<NavigatorState>(debugLabel: 'quran');
final _shellNavigatorPrayerKey = GlobalKey<NavigatorState>(debugLabel: 'prayer');
final _shellNavigatorHifzKey = GlobalKey<NavigatorState>(debugLabel: 'hifz');
final _shellNavigatorMoreKey = GlobalKey<NavigatorState>(debugLabel: 'more');

/// Provides the app's [GoRouter] instance.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    routes: [
      // ── Splash & Onboarding (no bottom nav) ──
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Main App Shell with Bottom Navigation ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Home Tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Quran Tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorQuranKey,
            routes: [
              GoRoute(
                path: RoutePaths.surahIndex,
                name: RouteNames.surahIndex,
                builder: (context, state) => const SurahIndexScreen(),
              ),
              GoRoute(
                path: RoutePaths.juzIndex,
                name: RouteNames.juzIndex,
                builder: (context, state) => const JuzIndexScreen(),
              ),
            ],
          ),

          // Prayer Tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorPrayerKey,
            routes: [
              GoRoute(
                path: RoutePaths.prayerTimes,
                name: RouteNames.prayerTimes,
                builder: (context, state) => const PrayerTimesScreen(),
              ),
            ],
          ),

          // Hifz Tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHifzKey,
            routes: [
              GoRoute(
                path: RoutePaths.hifzDashboard,
                name: RouteNames.hifzDashboard,
                builder: (context, state) => const HifzDashboardScreen(),
              ),
            ],
          ),

          // More Tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMoreKey,
            routes: [
              GoRoute(
                path: RoutePaths.settings,
                name: RouteNames.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Full-screen routes (no bottom nav) ──
      GoRoute(
        path: RoutePaths.quranReader,
        name: RouteNames.quranReader,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final surahNumber = int.parse(state.pathParameters['surahNumber']!);
          final ayahNumber = int.tryParse(
            state.uri.queryParameters['ayah'] ?? '',
          );
          return QuranReaderScreen(
            surahNumber: surahNumber,
            initialAyah: ayahNumber,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.audioPlayer,
        name: RouteNames.audioPlayer,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AudioPlayerScreen(),
      ),
      GoRoute(
        path: RoutePaths.bookmarks,
        name: RouteNames.bookmarks,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        path: RoutePaths.favorites,
        name: RouteNames.favorites,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: RoutePaths.tafsir,
        name: RouteNames.tafsir,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final surahNumber = int.parse(state.pathParameters['surahNumber']!);
          final ayahNumber = int.parse(state.pathParameters['ayahNumber']!);
          return TafsirViewScreen(
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.search,
        name: RouteNames.search,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: RoutePaths.qibla,
        name: RouteNames.qibla,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QiblaCompassScreen(),
      ),
      GoRoute(
        path: RoutePaths.hifzPlanSetup,
        name: RouteNames.hifzPlanSetup,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HifzPlanSetupScreen(),
      ),
      GoRoute(
        path: RoutePaths.selfTest,
        name: RouteNames.selfTest,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SelfTestScreen(),
      ),
      GoRoute(
        path: RoutePaths.mosabqatHome,
        name: RouteNames.mosabqatHome,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MosabqatHomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.quizSetup,
        name: RouteNames.quizSetup,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QuizSetupScreen(),
      ),
      GoRoute(
        path: RoutePaths.quizPlay,
        name: RouteNames.quizPlay,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QuizPlayScreen(),
      ),
      GoRoute(
        path: RoutePaths.quizResults,
        name: RouteNames.quizResults,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final score = int.tryParse(
            state.uri.queryParameters['score'] ?? '0',
          ) ?? 0;
          final total = int.tryParse(
            state.uri.queryParameters['total'] ?? '0',
          ) ?? 0;
          return QuizResultsScreen(score: score, total: total);
        },
      ),
      GoRoute(
        path: RoutePaths.dailyChallenge,
        name: RouteNames.dailyChallenge,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DailyChallengeScreen(),
      ),
      GoRoute(
        path: RoutePaths.mosabqatStats,
        name: RouteNames.mosabqatStats,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MosabqatStatsScreen(),
      ),
      GoRoute(
        path: RoutePaths.downloads,
        name: RouteNames.downloads,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DownloadsManagerScreen(),
      ),
    ],
  );
});
