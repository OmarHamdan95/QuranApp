import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/repositories/prayer_repository_impl.dart';
import '../../domain/entities/prayer_time_entity.dart';
import '../../domain/repositories/prayer_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Supporting types (kept here for easy widget consumption)
// ─────────────────────────────────────────────────────────────────────────────

/// User location value object.
typedef UserLocation = ({double lat, double lng, String name});

/// Prayer adhan settings (one flag per prayer).
class AdhanSettings {
  final bool fajr;
  final bool dhuhr;
  final bool asr;
  final bool maghrib;
  final bool isha;

  const AdhanSettings({
    this.fajr = true,
    this.dhuhr = true,
    this.asr = true,
    this.maghrib = true,
    this.isha = true,
  });

  AdhanSettings copyWith({
    bool? fajr,
    bool? dhuhr,
    bool? asr,
    bool? maghrib,
    bool? isha,
  }) {
    return AdhanSettings(
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
    );
  }

  Map<String, bool> toMap() => {
        'Fajr': fajr,
        'Dhuhr': dhuhr,
        'Asr': asr,
        'Maghrib': maghrib,
        'Isha': isha,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Enums & labels
// ─────────────────────────────────────────────────────────────────────────────

/// Supported prayer calculation methods.
enum CalculationMethod {
  ummAlQura('UmmAlQura', 'أم القرى'),
  isna('ISNA', 'الجمعية الإسلامية لأمريكا الشمالية'),
  muslimWorldLeague('MuslimWorldLeague', 'رابطة العالم الإسلامي'),
  egyptian('Egyptian', 'الهيئة المصرية'),
  karachi('Karachi', 'جامعة العلوم الإسلامية، كراتشي'),
  northAmerica('NorthAmerica', 'أمريكا الشمالية (ISNA)'),
  moonsightingCommittee('MoonsightingCommittee', 'لجنة رؤية الهلال');

  final String key;
  final String labelArabic;

  const CalculationMethod(this.key, this.labelArabic);

  static CalculationMethod fromKey(String key) =>
      CalculationMethod.values.firstWhere(
        (m) => m.key == key,
        orElse: () => CalculationMethod.muslimWorldLeague,
      );
}

/// Supported Madhabs for Asr calculation.
enum Madhab {
  shafi('Shafi', 'الشافعي / المالكي / الحنبلي'),
  hanafi('Hanafi', 'الحنفي');

  final String key;
  final String labelArabic;

  const Madhab(this.key, this.labelArabic);

  static Madhab fromKey(String key) =>
      Madhab.values.firstWhere((m) => m.key == key, orElse: () => Madhab.shafi);
}

// ─────────────────────────────────────────────────────────────────────────────
// Service providers
// ─────────────────────────────────────────────────────────────────────────────

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return PrayerRepositoryImpl();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ─────────────────────────────────────────────────────────────────────────────
// State providers (user preferences)
// ─────────────────────────────────────────────────────────────────────────────

/// Currently selected prayer calculation method.
final calculationMethodProvider = StateProvider<String>(
  (ref) => AppConstants.defaultCalculationMethod,
);

/// Currently selected Madhab.
final madhabProvider = StateProvider<String>(
  (ref) => AppConstants.defaultMadhab,
);

/// User location (lat/lng/name). Defaults to Makkah.
final userLocationProvider = StateProvider<UserLocation>(
  (ref) => (lat: 21.4225, lng: 39.8262, name: 'مكة المكرمة'),
);

/// Whether location auto-detection is in progress.
final locationLoadingProvider = StateProvider<bool>((ref) => false);

/// Most recent location error message (null if none).
final locationErrorProvider = StateProvider<String?>((ref) => null);

/// Per-prayer adhan toggle settings.
final adhanSettingsProvider = StateProvider<AdhanSettings>(
  (ref) => const AdhanSettings(),
);

// ─────────────────────────────────────────────────────────────────────────────
// Computed providers
// ─────────────────────────────────────────────────────────────────────────────

/// Today's daily prayer schedule, recalculated when location/method changes.
final dailyPrayerTimesProvider = Provider<DailyPrayerSchedule>((ref) {
  final location = ref.watch(userLocationProvider);
  final method = ref.watch(calculationMethodProvider);
  final madhab = ref.watch(madhabProvider);
  final adhan = ref.watch(adhanSettingsProvider);
  final repo = ref.watch(prayerRepositoryProvider);

  final result = repo.getPrayerTimes(
    date: DateTime.now(),
    latitude: location.lat,
    longitude: location.lng,
    locationName: location.name,
    calculationMethod: method,
    madhab: madhab,
    adhanEnabled: adhan.toMap(),
  );

  return result.fold(
    (failure) => _fallbackSchedule(location),
    (schedule) => schedule,
  );
});

/// Monthly prayer times for the calendar toggle view.
final monthlyPrayerTimesProvider = Provider.family<List<DailyPrayerSchedule>, ({int year, int month})>(
  (ref, params) {
    final location = ref.watch(userLocationProvider);
    final method = ref.watch(calculationMethodProvider);
    final madhab = ref.watch(madhabProvider);
    final repo = ref.watch(prayerRepositoryProvider);

    final result = repo.getMonthlyPrayerTimes(
      year: params.year,
      month: params.month,
      latitude: location.lat,
      longitude: location.lng,
      locationName: location.name,
      calculationMethod: method,
      madhab: madhab,
    );

    return result.fold(
      (failure) => [],
      (schedules) => schedules,
    );
  },
);

/// Calculated Qibla bearing from the user's location.
final qiblaDirectionProvider = Provider<double>((ref) {
  final location = ref.watch(userLocationProvider);
  final repo = ref.watch(prayerRepositoryProvider);

  final result = repo.getQiblaDirection(
    latitude: location.lat,
    longitude: location.lng,
  );

  return result.fold((failure) => 0.0, (bearing) => bearing);
});

/// Distance to Makkah in km.
final distanceToMakkahProvider = Provider<double>((ref) {
  final location = ref.watch(userLocationProvider);
  final repo = ref.watch(prayerRepositoryProvider);

  final result = repo.getDistanceToMakkah(
    latitude: location.lat,
    longitude: location.lng,
  );

  return result.fold((failure) => 0.0, (distance) => distance);
});

// ─────────────────────────────────────────────────────────────────────────────
// Countdown timer provider (auto-updates every second)
// ─────────────────────────────────────────────────────────────────────────────

/// A ticker that fires every second, used to drive countdown displays.
final countdownTickerProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// Time remaining until next prayer, updated every second.
final nextPrayerCountdownProvider = Provider<Duration?>((ref) {
  ref.watch(countdownTickerProvider); // subscribe to ticks
  final schedule = ref.watch(dailyPrayerTimesProvider);
  return schedule.timeUntilNextPrayer;
});

/// The next prayer entity (from calculated schedule).
final upcomingPrayerProvider = Provider<PrayerTimeEntity?>((ref) {
  ref.watch(countdownTickerProvider);
  final schedule = ref.watch(dailyPrayerTimesProvider);
  return schedule.nextPrayer;
});

/// The currently active prayer entity.
final currentPrayerProvider = Provider<PrayerTimeEntity?>((ref) {
  ref.watch(countdownTickerProvider);
  final schedule = ref.watch(dailyPrayerTimesProvider);
  return schedule.currentPrayer;
});

// ─────────────────────────────────────────────────────────────────────────────
// Location auto-detect action
// ─────────────────────────────────────────────────────────────────────────────

/// Notifier that handles GPS location detection.
class LocationNotifier extends StateNotifier<AsyncValue<UserLocation?>> {
  final LocationService _service;
  final Ref _ref;

  LocationNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  Future<void> detectLocation() async {
    state = const AsyncValue.loading();
    _ref.read(locationLoadingProvider.notifier).state = true;
    _ref.read(locationErrorProvider.notifier).state = null;

    final result = await _service.getCurrentLocation();

    _ref.read(locationLoadingProvider.notifier).state = false;

    if (result.result != null) {
      final loc = result.result!;
      final location = (lat: loc.latitude, lng: loc.longitude, name: loc.locationName);
      _ref.read(userLocationProvider.notifier).state = location;
      state = AsyncValue.data(location);
    } else {
      final msg = result.failure?.message ?? 'تعذر تحديد الموقع';
      _ref.read(locationErrorProvider.notifier).state = msg;
      state = AsyncValue.error(msg, StackTrace.current);
    }
  }

  Future<void> openSettings() => _service.openSettings();
}

final locationNotifierProvider =
    StateNotifierProvider<LocationNotifier, AsyncValue<UserLocation?>>(
  (ref) {
    final service = ref.watch(locationServiceProvider);
    return LocationNotifier(service, ref);
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

DailyPrayerSchedule _fallbackSchedule(UserLocation location) {
  final now = DateTime.now();
  return DailyPrayerSchedule(
    date: now,
    locationName: location.name,
    latitude: location.lat,
    longitude: location.lng,
    calculationMethod: AppConstants.defaultCalculationMethod,
    madhab: AppConstants.defaultMadhab,
    prayers: [
      PrayerTimeEntity(name: 'Fajr', nameArabic: 'الفجر', time: DateTime(now.year, now.month, now.day, 5, 0)),
      PrayerTimeEntity(name: 'Sunrise', nameArabic: 'الشروق', time: DateTime(now.year, now.month, now.day, 6, 30)),
      PrayerTimeEntity(name: 'Dhuhr', nameArabic: 'الظهر', time: DateTime(now.year, now.month, now.day, 12, 0)),
      PrayerTimeEntity(name: 'Asr', nameArabic: 'العصر', time: DateTime(now.year, now.month, now.day, 15, 30)),
      PrayerTimeEntity(name: 'Maghrib', nameArabic: 'المغرب', time: DateTime(now.year, now.month, now.day, 18, 0)),
      PrayerTimeEntity(name: 'Isha', nameArabic: 'العشاء', time: DateTime(now.year, now.month, now.day, 19, 30)),
    ],
  );
}
