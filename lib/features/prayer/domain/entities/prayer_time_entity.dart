/// Domain entity representing a single prayer time.
class PrayerTimeEntity {
  final String name;
  final String nameArabic;
  final DateTime time;
  final bool isAdhanEnabled;

  const PrayerTimeEntity({
    required this.name,
    required this.nameArabic,
    required this.time,
    this.isAdhanEnabled = true,
  });

  PrayerTimeEntity copyWith({
    String? name,
    String? nameArabic,
    DateTime? time,
    bool? isAdhanEnabled,
  }) {
    return PrayerTimeEntity(
      name: name ?? this.name,
      nameArabic: nameArabic ?? this.nameArabic,
      time: time ?? this.time,
      isAdhanEnabled: isAdhanEnabled ?? this.isAdhanEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerTimeEntity &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          time == other.time;

  @override
  int get hashCode => name.hashCode ^ time.hashCode;
}

/// Domain entity for daily prayer schedule.
class DailyPrayerSchedule {
  final DateTime date;
  final String locationName;
  final double latitude;
  final double longitude;
  final String calculationMethod;
  final String madhab;
  final List<PrayerTimeEntity> prayers;

  const DailyPrayerSchedule({
    required this.date,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.calculationMethod,
    required this.madhab,
    required this.prayers,
  });

  /// Returns the prayer that is currently active (time has passed but next hasn't started).
  PrayerTimeEntity? get currentPrayer {
    final now = DateTime.now();
    PrayerTimeEntity? current;
    for (final p in prayers) {
      if (p.time.isBefore(now) || p.time.isAtSameMomentAs(now)) {
        current = p;
      }
    }
    return current;
  }

  /// Returns the next prayer after now.
  PrayerTimeEntity? get nextPrayer {
    final now = DateTime.now();
    for (final p in prayers) {
      if (p.time.isAfter(now)) {
        return p;
      }
    }
    return null;
  }

  /// Returns time remaining until the next prayer.
  Duration? get timeUntilNextPrayer {
    final next = nextPrayer;
    if (next == null) return null;
    return next.time.difference(DateTime.now());
  }
}
