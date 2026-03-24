import 'package:equatable/equatable.dart';

/// Enum representing memorization status for a specific range.
enum MemorizationStatus {
  notStarted,
  inProgress,
  memorized,
  needsRevision,
}

/// Domain entity representing a user's hifz (memorization) progress for one surah.
class SurahHifzProgress extends Equatable {
  final int surahNumber;
  final String surahName;
  final int totalAyahs;
  final int memorizedAyahs;
  final MemorizationStatus status;
  final DateTime? lastReviewed;
  final int reviewCount;

  const SurahHifzProgress({
    required this.surahNumber,
    required this.surahName,
    required this.totalAyahs,
    required this.memorizedAyahs,
    this.status = MemorizationStatus.notStarted,
    this.lastReviewed,
    this.reviewCount = 0,
  });

  double get completionPercentage =>
      totalAyahs > 0 ? memorizedAyahs / totalAyahs : 0.0;

  bool get isComplete => memorizedAyahs >= totalAyahs;

  @override
  List<Object?> get props => [surahNumber, memorizedAyahs, status];
}

/// Domain entity representing a user's overall hifz progress.
class HifzProgress extends Equatable {
  final int totalMemorizedAyahs;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudyDate;
  final List<SurahHifzProgress> surahProgress;
  final Map<int, int> juzProgress; // juzNumber -> memorizedAyahs

  const HifzProgress({
    required this.totalMemorizedAyahs,
    required this.currentStreak,
    required this.longestStreak,
    this.lastStudyDate,
    this.surahProgress = const [],
    this.juzProgress = const {},
  });

  /// Overall percentage of Quran memorized (6236 total ayahs).
  double get overallPercentage => totalMemorizedAyahs / 6236;

  /// Total juz memorized (approximate).
  double get juzMemorized => totalMemorizedAyahs / 6236 * 30;

  @override
  List<Object?> get props => [totalMemorizedAyahs, currentStreak];
}

/// Domain entity representing a single hifz study session log.
class HifzSessionLog extends Equatable {
  final String id;
  final DateTime date;
  final int ayahsStudied;
  final int ayahsRevised;
  final int durationMinutes;
  final double accuracyScore;

  const HifzSessionLog({
    required this.id,
    required this.date,
    required this.ayahsStudied,
    required this.ayahsRevised,
    required this.durationMinutes,
    required this.accuracyScore,
  });

  @override
  List<Object?> get props => [id, date];
}
