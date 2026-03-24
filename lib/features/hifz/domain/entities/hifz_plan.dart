import 'package:equatable/equatable.dart';

/// Enum for the hifz plan schedule type.
enum HifzScheduleType {
  daily,
  fiveDays,
  custom,
}

/// Enum for the hifz plan range type.
enum HifzRangeType {
  fullQuran,
  byJuz,
  bySurah,
  custom,
}

/// Enum for memorization difficulty.
enum HifzDifficulty {
  beginner,  // 1-3 ayahs/day
  moderate,  // 4-7 ayahs/day
  intensive, // 8-15 ayahs/day
  advanced,  // 16-30 ayahs/day
}

/// Domain entity representing a hifz (memorization) plan.
class HifzPlan extends Equatable {
  final String id;
  final String name;
  final int dailyAyahGoal;
  final HifzScheduleType scheduleType;
  final HifzRangeType rangeType;
  final int startSurah;
  final int startAyah;
  final int? endSurah;
  final int? endAyah;
  final bool includeRevision;
  final int revisionAyahsPerDay;
  final bool remindersEnabled;
  final String? reminderTime; // HH:mm format
  final DateTime createdAt;
  final DateTime? targetCompletionDate;
  final bool isActive;

  const HifzPlan({
    required this.id,
    required this.name,
    required this.dailyAyahGoal,
    required this.scheduleType,
    required this.rangeType,
    required this.startSurah,
    required this.startAyah,
    this.endSurah,
    this.endAyah,
    required this.includeRevision,
    this.revisionAyahsPerDay = 0,
    this.remindersEnabled = false,
    this.reminderTime,
    required this.createdAt,
    this.targetCompletionDate,
    this.isActive = true,
  });

  HifzDifficulty get difficulty {
    if (dailyAyahGoal <= 3) return HifzDifficulty.beginner;
    if (dailyAyahGoal <= 7) return HifzDifficulty.moderate;
    if (dailyAyahGoal <= 15) return HifzDifficulty.intensive;
    return HifzDifficulty.advanced;
  }

  /// Estimated days to complete memorization from current position.
  int estimatedDaysToComplete(int remainingAyahs) {
    if (dailyAyahGoal <= 0) return 0;
    final studyDays = scheduleType == HifzScheduleType.fiveDays ? 5 / 7 : 1.0;
    return (remainingAyahs / dailyAyahGoal / studyDays).ceil();
  }

  @override
  List<Object?> get props => [id, dailyAyahGoal, startSurah, isActive];
}
