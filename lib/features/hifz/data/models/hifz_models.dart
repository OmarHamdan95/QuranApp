import '../../domain/entities/hifz_plan.dart';
import '../../domain/entities/hifz_progress.dart';

/// Data model for [SurahHifzProgress] with serialization.
class SurahHifzProgressModel extends SurahHifzProgress {
  const SurahHifzProgressModel({
    required super.surahNumber,
    required super.surahName,
    required super.totalAyahs,
    required super.memorizedAyahs,
    super.status,
    super.lastReviewed,
    super.reviewCount,
  });

  factory SurahHifzProgressModel.fromMap(Map<String, dynamic> map) {
    return SurahHifzProgressModel(
      surahNumber: map['surah_number'] as int,
      surahName: map['surah_name'] as String,
      totalAyahs: map['total_ayahs'] as int,
      memorizedAyahs: map['memorized_ayahs'] as int,
      status: MemorizationStatus.values[map['status'] as int? ?? 0],
      lastReviewed: map['last_reviewed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_reviewed'] as int)
          : null,
      reviewCount: map['review_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'surah_number': surahNumber,
      'surah_name': surahName,
      'total_ayahs': totalAyahs,
      'memorized_ayahs': memorizedAyahs,
      'status': status.index,
      'last_reviewed': lastReviewed?.millisecondsSinceEpoch,
      'review_count': reviewCount,
    };
  }

  SurahHifzProgressModel copyWith({
    int? memorizedAyahs,
    MemorizationStatus? status,
    DateTime? lastReviewed,
    int? reviewCount,
  }) {
    return SurahHifzProgressModel(
      surahNumber: surahNumber,
      surahName: surahName,
      totalAyahs: totalAyahs,
      memorizedAyahs: memorizedAyahs ?? this.memorizedAyahs,
      status: status ?? this.status,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}

/// Data model for [HifzPlan] with serialization.
class HifzPlanModel extends HifzPlan {
  const HifzPlanModel({
    required super.id,
    required super.name,
    required super.dailyAyahGoal,
    required super.scheduleType,
    required super.rangeType,
    required super.startSurah,
    required super.startAyah,
    super.endSurah,
    super.endAyah,
    required super.includeRevision,
    super.revisionAyahsPerDay,
    super.remindersEnabled,
    super.reminderTime,
    required super.createdAt,
    super.targetCompletionDate,
    super.isActive,
  });

  factory HifzPlanModel.fromMap(Map<String, dynamic> map) {
    return HifzPlanModel(
      id: map['id'] as String,
      name: map['name'] as String,
      dailyAyahGoal: map['daily_ayah_goal'] as int,
      scheduleType: HifzScheduleType.values[map['schedule_type'] as int? ?? 0],
      rangeType: HifzRangeType.values[map['range_type'] as int? ?? 0],
      startSurah: map['start_surah'] as int,
      startAyah: map['start_ayah'] as int,
      endSurah: map['end_surah'] as int?,
      endAyah: map['end_ayah'] as int?,
      includeRevision: (map['include_revision'] as int? ?? 1) == 1,
      revisionAyahsPerDay: map['revision_ayahs_per_day'] as int? ?? 0,
      remindersEnabled: (map['reminders_enabled'] as int? ?? 0) == 1,
      reminderTime: map['reminder_time'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      targetCompletionDate: map['target_completion_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['target_completion_date'] as int)
          : null,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'daily_ayah_goal': dailyAyahGoal,
      'schedule_type': scheduleType.index,
      'range_type': rangeType.index,
      'start_surah': startSurah,
      'start_ayah': startAyah,
      'end_surah': endSurah,
      'end_ayah': endAyah,
      'include_revision': includeRevision ? 1 : 0,
      'revision_ayahs_per_day': revisionAyahsPerDay,
      'reminders_enabled': remindersEnabled ? 1 : 0,
      'reminder_time': reminderTime,
      'created_at': createdAt.millisecondsSinceEpoch,
      'target_completion_date': targetCompletionDate?.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }
}

/// Data model for [HifzSessionLog] with serialization.
class HifzSessionLogModel extends HifzSessionLog {
  const HifzSessionLogModel({
    required super.id,
    required super.date,
    required super.ayahsStudied,
    required super.ayahsRevised,
    required super.durationMinutes,
    required super.accuracyScore,
  });

  factory HifzSessionLogModel.fromMap(Map<String, dynamic> map) {
    return HifzSessionLogModel(
      id: map['id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      ayahsStudied: map['ayahs_studied'] as int,
      ayahsRevised: map['ayahs_revised'] as int,
      durationMinutes: map['duration_minutes'] as int,
      accuracyScore: (map['accuracy_score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'ayahs_studied': ayahsStudied,
      'ayahs_revised': ayahsRevised,
      'duration_minutes': durationMinutes,
      'accuracy_score': accuracyScore,
    };
  }
}
