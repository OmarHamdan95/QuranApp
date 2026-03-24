import 'package:dartz/dartz.dart';

import '../entities/prayer_time_entity.dart';

/// Failure type for prayer feature errors.
class PrayerFailure {
  final String message;
  const PrayerFailure(this.message);
}

/// Abstract repository for prayer times.
abstract class PrayerRepository {
  /// Calculate prayer times for a given date and location.
  Either<PrayerFailure, DailyPrayerSchedule> getPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    required String locationName,
    required String calculationMethod,
    required String madhab,
    Map<String, bool> adhanEnabled,
  });

  /// Calculate prayer times for an entire month.
  Either<PrayerFailure, List<DailyPrayerSchedule>> getMonthlyPrayerTimes({
    required int year,
    required int month,
    required double latitude,
    required double longitude,
    required String locationName,
    required String calculationMethod,
    required String madhab,
  });

  /// Calculate the Qibla direction from a location.
  Either<PrayerFailure, double> getQiblaDirection({
    required double latitude,
    required double longitude,
  });

  /// Calculate distance to Makkah in km.
  Either<PrayerFailure, double> getDistanceToMakkah({
    required double latitude,
    required double longitude,
  });
}
