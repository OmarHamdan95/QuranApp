import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/hifz_plan.dart';
import '../../domain/entities/hifz_progress.dart';

// ─────────────────────────────────────────────
// Seed Data — 30 Surahs with realistic hifz data
// ─────────────────────────────────────────────
const _seedSurahProgress = [
  SurahHifzProgress(
    surahNumber: 1,
    surahName: 'الفاتحة',
    totalAyahs: 7,
    memorizedAyahs: 7,
    status: MemorizationStatus.memorized,
    reviewCount: 12,
  ),
  SurahHifzProgress(
    surahNumber: 2,
    surahName: 'البقرة',
    totalAyahs: 286,
    memorizedAyahs: 140,
    status: MemorizationStatus.inProgress,
    reviewCount: 3,
  ),
  SurahHifzProgress(
    surahNumber: 3,
    surahName: 'آل عمران',
    totalAyahs: 200,
    memorizedAyahs: 60,
    status: MemorizationStatus.inProgress,
    reviewCount: 1,
  ),
  SurahHifzProgress(
    surahNumber: 67,
    surahName: 'الملك',
    totalAyahs: 30,
    memorizedAyahs: 30,
    status: MemorizationStatus.memorized,
    reviewCount: 8,
  ),
  SurahHifzProgress(
    surahNumber: 78,
    surahName: 'النبأ',
    totalAyahs: 40,
    memorizedAyahs: 40,
    status: MemorizationStatus.memorized,
    reviewCount: 6,
  ),
  SurahHifzProgress(
    surahNumber: 112,
    surahName: 'الإخلاص',
    totalAyahs: 4,
    memorizedAyahs: 4,
    status: MemorizationStatus.memorized,
    reviewCount: 20,
  ),
  SurahHifzProgress(
    surahNumber: 113,
    surahName: 'الفلق',
    totalAyahs: 5,
    memorizedAyahs: 5,
    status: MemorizationStatus.memorized,
    reviewCount: 18,
  ),
  SurahHifzProgress(
    surahNumber: 114,
    surahName: 'الناس',
    totalAyahs: 6,
    memorizedAyahs: 6,
    status: MemorizationStatus.memorized,
    reviewCount: 17,
  ),
];

// ─────────────────────────────────────────────
// State Classes
// ─────────────────────────────────────────────

/// State for the hifz feature.
class HifzState {
  final HifzProgress progress;
  final HifzPlan? activePlan;
  final List<HifzSessionLog> recentSessions;
  final bool isLoading;
  final String? error;

  const HifzState({
    required this.progress,
    this.activePlan,
    this.recentSessions = const [],
    this.isLoading = false,
    this.error,
  });

  HifzState copyWith({
    HifzProgress? progress,
    HifzPlan? activePlan,
    List<HifzSessionLog>? recentSessions,
    bool? isLoading,
    String? error,
  }) {
    return HifzState(
      progress: progress ?? this.progress,
      activePlan: activePlan ?? this.activePlan,
      recentSessions: recentSessions ?? this.recentSessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────

class HifzNotifier extends StateNotifier<HifzState> {
  HifzNotifier()
      : super(
          HifzState(
            progress: const HifzProgress(
              totalMemorizedAyahs: 750,
              currentStreak: 7,
              longestStreak: 21,
              surahProgress: _seedSurahProgress,
            ),
            activePlan: HifzPlan(
              id: 'plan_1',
              name: 'خطتي الرئيسية',
              dailyAyahGoal: 5,
              scheduleType: HifzScheduleType.daily,
              rangeType: HifzRangeType.fullQuran,
              startSurah: 2,
              startAyah: 141,
              includeRevision: true,
              revisionAyahsPerDay: 10,
              remindersEnabled: true,
              reminderTime: '06:00',
              createdAt: DateTime(2025, 1, 1),
              targetCompletionDate: DateTime(2027, 12, 31),
            ),
          ),
        );

  void updateSurahProgress(int surahNumber, int memorizedAyahs) {
    final updatedSurahList = state.progress.surahProgress.map((s) {
      if (s.surahNumber == surahNumber) {
        final newStatus = memorizedAyahs >= s.totalAyahs
            ? MemorizationStatus.memorized
            : memorizedAyahs > 0
                ? MemorizationStatus.inProgress
                : MemorizationStatus.notStarted;

        return SurahHifzProgress(
          surahNumber: s.surahNumber,
          surahName: s.surahName,
          totalAyahs: s.totalAyahs,
          memorizedAyahs: memorizedAyahs,
          status: newStatus,
          lastReviewed: DateTime.now(),
          reviewCount: s.reviewCount + 1,
        );
      }
      return s;
    }).toList();

    final totalMemorized = updatedSurahList.fold<int>(
      0,
      (sum, s) => sum + s.memorizedAyahs,
    );

    state = state.copyWith(
      progress: HifzProgress(
        totalMemorizedAyahs: totalMemorized,
        currentStreak: state.progress.currentStreak,
        longestStreak: state.progress.longestStreak,
        lastStudyDate: DateTime.now(),
        surahProgress: updatedSurahList,
        juzProgress: state.progress.juzProgress,
      ),
    );
  }

  void savePlan(HifzPlan plan) {
    state = state.copyWith(activePlan: plan);
  }

  void logSession({
    required int ayahsStudied,
    required int ayahsRevised,
    required int durationMinutes,
    required double accuracyScore,
  }) {
    final session = HifzSessionLog(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      ayahsStudied: ayahsStudied,
      ayahsRevised: ayahsRevised,
      durationMinutes: durationMinutes,
      accuracyScore: accuracyScore,
    );

    // Update streak
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final lastStudy = state.progress.lastStudyDate;
    final isConsecutive = lastStudy != null &&
        lastStudy.year == yesterday.year &&
        lastStudy.month == yesterday.month &&
        lastStudy.day == yesterday.day;

    final newStreak = isConsecutive
        ? state.progress.currentStreak + 1
        : state.progress.currentStreak;

    final newLongest = newStreak > state.progress.longestStreak
        ? newStreak
        : state.progress.longestStreak;

    state = state.copyWith(
      recentSessions: [...state.recentSessions, session],
      progress: HifzProgress(
        totalMemorizedAyahs:
            state.progress.totalMemorizedAyahs + ayahsStudied,
        currentStreak: newStreak,
        longestStreak: newLongest,
        lastStudyDate: DateTime.now(),
        surahProgress: state.progress.surahProgress,
        juzProgress: state.progress.juzProgress,
      ),
    );
  }

  void incrementStreak() {
    state = state.copyWith(
      progress: HifzProgress(
        totalMemorizedAyahs: state.progress.totalMemorizedAyahs,
        currentStreak: state.progress.currentStreak + 1,
        longestStreak: state.progress.longestStreak,
        lastStudyDate: DateTime.now(),
        surahProgress: state.progress.surahProgress,
        juzProgress: state.progress.juzProgress,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────

/// Main hifz state provider.
final hifzProvider = StateNotifierProvider<HifzNotifier, HifzState>((ref) {
  return HifzNotifier();
});

/// Overall memorization progress percentage.
final hifzProgressPercentProvider = Provider<double>((ref) {
  return ref.watch(hifzProvider).progress.overallPercentage;
});

/// Current streak in days.
final hifzStreakProvider = Provider<int>((ref) {
  return ref.watch(hifzProvider).progress.currentStreak;
});

/// Total ayahs memorized.
final totalMemorizedAyahsProvider = Provider<int>((ref) {
  return ref.watch(hifzProvider).progress.totalMemorizedAyahs;
});

/// Active hifz plan (nullable).
final activePlanProvider = Provider<HifzPlan?>((ref) {
  return ref.watch(hifzProvider).activePlan;
});

/// Per-surah progress list.
final surahProgressListProvider = Provider<List<SurahHifzProgress>>((ref) {
  return ref.watch(hifzProvider).progress.surahProgress;
});

/// Surahs fully memorized.
final memorizedSurahsProvider = Provider<List<SurahHifzProgress>>((ref) {
  return ref
      .watch(surahProgressListProvider)
      .where((s) => s.status == MemorizationStatus.memorized)
      .toList();
});

/// Surahs currently in progress.
final inProgressSurahsProvider = Provider<List<SurahHifzProgress>>((ref) {
  return ref
      .watch(surahProgressListProvider)
      .where((s) => s.status == MemorizationStatus.inProgress)
      .toList();
});

/// Today's goal progress (fraction 0.0 - 1.0).
final todayGoalProgressProvider = StateProvider<double>((ref) => 0.6);

/// Today's studied ayah count.
final todayStudiedAyahsProvider = StateProvider<int>((ref) => 3);
