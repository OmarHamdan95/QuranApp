import 'dart:math' as math;

import 'package:dartz/dartz.dart';

import '../../domain/entities/prayer_time_entity.dart';
import '../../domain/repositories/prayer_repository.dart';
import '../models/prayer_times_model.dart';

/// Concrete implementation of [PrayerRepository] using local calculation.
class PrayerRepositoryImpl implements PrayerRepository {
  @override
  Either<PrayerFailure, DailyPrayerSchedule> getPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    required String locationName,
    required String calculationMethod,
    required String madhab,
    Map<String, bool> adhanEnabled = const {},
  }) {
    try {
      final model = PrayerTimesModel(
        date: date,
        latitude: latitude,
        longitude: longitude,
        calculationMethod: calculationMethod,
        madhab: madhab,
      );

      final prayers = model.toPrayerEntities(adhanEnabled: adhanEnabled);

      return Right(
        DailyPrayerSchedule(
          date: date,
          locationName: locationName,
          latitude: latitude,
          longitude: longitude,
          calculationMethod: calculationMethod,
          madhab: madhab,
          prayers: prayers,
        ),
      );
    } catch (e) {
      return Left(PrayerFailure('Failed to calculate prayer times: $e'));
    }
  }

  @override
  Either<PrayerFailure, List<DailyPrayerSchedule>> getMonthlyPrayerTimes({
    required int year,
    required int month,
    required double latitude,
    required double longitude,
    required String locationName,
    required String calculationMethod,
    required String madhab,
  }) {
    try {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final schedules = <DailyPrayerSchedule>[];

      for (var day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        final result = getPrayerTimes(
          date: date,
          latitude: latitude,
          longitude: longitude,
          locationName: locationName,
          calculationMethod: calculationMethod,
          madhab: madhab,
        );
        result.fold(
          (failure) => throw Exception(failure.message),
          schedules.add,
        );
      }

      return Right(schedules);
    } catch (e) {
      return Left(PrayerFailure('Failed to calculate monthly prayer times: $e'));
    }
  }

  @override
  Either<PrayerFailure, double> getQiblaDirection({
    required double latitude,
    required double longitude,
  }) {
    try {
      const kaabaLat = 21.4225 * (math.pi / 180);
      const kaabaLng = 39.8262 * (math.pi / 180);
      final lat = latitude * (math.pi / 180);
      final lng = longitude * (math.pi / 180);

      final dLng = kaabaLng - lng;

      final y = math.sin(dLng) * math.cos(kaabaLat);
      final x = math.cos(lat) * math.sin(kaabaLat) -
          math.sin(lat) * math.cos(kaabaLat) * math.cos(dLng);

      var bearing = math.atan2(y, x) * (180 / math.pi);
      bearing = (bearing + 360) % 360;

      return Right(bearing);
    } catch (e) {
      return Left(PrayerFailure('Failed to calculate Qibla direction: $e'));
    }
  }

  @override
  Either<PrayerFailure, double> getDistanceToMakkah({
    required double latitude,
    required double longitude,
  }) {
    try {
      const earthRadiusKm = 6371.0;
      const kaabaLat = 21.4225;
      const kaabaLng = 39.8262;

      final lat1 = latitude * (math.pi / 180);
      final lat2 = kaabaLat * (math.pi / 180);
      final dLat = (kaabaLat - latitude) * (math.pi / 180);
      final dLng = (kaabaLng - longitude) * (math.pi / 180);

      final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

      return Right(earthRadiusKm * c);
    } catch (e) {
      return Left(PrayerFailure('Failed to calculate distance to Makkah: $e'));
    }
  }
}
