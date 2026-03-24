import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a single prayer time.
class PrayerTime {
  final String name;
  final String nameArabic;
  final DateTime time;
  final bool isNext;

  const PrayerTime({
    required this.name,
    required this.nameArabic,
    required this.time,
    this.isNext = false,
  });
}

/// Holds the prayer times for a given day + location.
class DailyPrayerTimes {
  final DateTime date;
  final String locationName;
  final double latitude;
  final double longitude;
  final List<PrayerTime> prayers;

  const DailyPrayerTimes({
    required this.date,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.prayers,
  });

  PrayerTime? get nextPrayer {
    try {
      return prayers.firstWhere((p) => p.isNext);
    } catch (_) {
      return null;
    }
  }
}

/// Provider for prayer calculation method.
final calculationMethodProvider = StateProvider<String>((ref) => 'MuslimWorldLeague');

/// Provider for madhab (Shafi / Hanafi).
final madhabProvider = StateProvider<String>((ref) => 'Shafi');

/// Provider for user location.
final userLocationProvider = StateProvider<({double lat, double lng, String name})>(
  (ref) => (lat: 21.4225, lng: 39.8262, name: 'Makkah'),
);

/// Provider for daily prayer times.
///
/// In production, this will use adhan_dart to calculate actual prayer times
/// based on the user's location and selected calculation method.
final dailyPrayerTimesProvider = Provider<DailyPrayerTimes>((ref) {
  final location = ref.watch(userLocationProvider);
  final now = DateTime.now();

  // Placeholder prayer times for MVP.
  // Will be replaced with adhan_dart calculations.
  final prayers = [
    PrayerTime(
      name: 'Fajr',
      nameArabic: 'الفجر',
      time: DateTime(now.year, now.month, now.day, 5, 12),
    ),
    PrayerTime(
      name: 'Sunrise',
      nameArabic: 'الشروق',
      time: DateTime(now.year, now.month, now.day, 6, 38),
    ),
    PrayerTime(
      name: 'Dhuhr',
      nameArabic: 'الظهر',
      time: DateTime(now.year, now.month, now.day, 12, 20),
    ),
    PrayerTime(
      name: 'Asr',
      nameArabic: 'العصر',
      time: DateTime(now.year, now.month, now.day, 15, 45),
    ),
    PrayerTime(
      name: 'Maghrib',
      nameArabic: 'المغرب',
      time: DateTime(now.year, now.month, now.day, 18, 30),
    ),
    PrayerTime(
      name: 'Isha',
      nameArabic: 'العشاء',
      time: DateTime(now.year, now.month, now.day, 20, 0),
    ),
  ];

  // Determine next prayer.
  final updatedPrayers = prayers.map((p) {
    final isNext = p.time.isAfter(now) &&
        !prayers.any((other) => other.time.isAfter(now) && other.time.isBefore(p.time));
    return PrayerTime(
      name: p.name,
      nameArabic: p.nameArabic,
      time: p.time,
      isNext: isNext,
    );
  }).toList();

  return DailyPrayerTimes(
    date: now,
    locationName: location.name,
    latitude: location.lat,
    longitude: location.lng,
    prayers: updatedPrayers,
  );
});
