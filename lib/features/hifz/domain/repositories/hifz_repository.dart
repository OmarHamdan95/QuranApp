import '../entities/hifz_plan.dart';
import '../entities/hifz_progress.dart';

/// Abstract repository for hifz (memorization) data operations.
abstract class HifzRepository {
  /// Get the user's overall hifz progress.
  Future<HifzProgress> getProgress();

  /// Get per-surah hifz progress list.
  Future<List<SurahHifzProgress>> getSurahProgressList();

  /// Update memorized ayahs for a specific surah.
  Future<void> updateSurahProgress(SurahHifzProgress progress);

  /// Get the active hifz plan.
  Future<HifzPlan?> getActivePlan();

  /// Save or update a hifz plan.
  Future<void> savePlan(HifzPlan plan);

  /// Delete a hifz plan.
  Future<void> deletePlan(String planId);

  /// Log a completed study session.
  Future<void> logSession(HifzSessionLog session);

  /// Get session logs for the past [days] days.
  Future<List<HifzSessionLog>> getSessionLogs({int days = 30});

  /// Update the current streak.
  Future<void> updateStreak(int streak);
}
