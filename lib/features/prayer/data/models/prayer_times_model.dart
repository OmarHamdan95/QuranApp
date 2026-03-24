import 'dart:math' as math;

import '../../domain/entities/prayer_time_entity.dart';

/// Calculation parameters for a given method.
class _CalcParams {
  final double fajrAngle;
  final double ishaAngle;
  final int? ishaMinutes; // for Umm Al-Qura fixed offset

  const _CalcParams({
    required this.fajrAngle,
    this.ishaAngle = 0,
    this.ishaMinutes,
  });
}

/// Data model that computes prayer times using astronomical formulas.
///
/// Implements the standard prayer time calculation algorithm based on:
/// - Solar declination and equation of time
/// - Chosen Fajr/Isha angle or fixed offset (Umm Al-Qura)
/// - Asr shadow ratio (1x for Shafi/Maliki/Hanbali, 2x for Hanafi)
class PrayerTimesModel {
  final DateTime date;
  final double latitude;
  final double longitude;
  final String calculationMethod;
  final String madhab;

  // ── Calculation method parameters ──
  static const _methods = <String, _CalcParams>{
    'UmmAlQura': _CalcParams(fajrAngle: 18.5, ishaMinutes: 90),
    'ISNA': _CalcParams(fajrAngle: 15.0, ishaAngle: 15.0),
    'MuslimWorldLeague': _CalcParams(fajrAngle: 18.0, ishaAngle: 17.0),
    'Egyptian': _CalcParams(fajrAngle: 19.5, ishaAngle: 17.5),
    'Karachi': _CalcParams(fajrAngle: 18.0, ishaAngle: 18.0),
    'NorthAmerica': _CalcParams(fajrAngle: 15.0, ishaAngle: 15.0),
    'MoonsightingCommittee': _CalcParams(fajrAngle: 18.0, ishaAngle: 18.0),
  };

  late final DateTime fajr;
  late final DateTime sunrise;
  late final DateTime dhuhr;
  late final DateTime asr;
  late final DateTime maghrib;
  late final DateTime isha;

  PrayerTimesModel({
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.calculationMethod,
    required this.madhab,
  }) {
    _calculate();
  }

  void _calculate() {
    final jd = _julianDay(date.year, date.month, date.day) - longitude / (15.0 * 24.0);
    final d = jd - 2451545.0;

    // Solar coordinates
    final g = (357.529 + 0.98560028 * d) % 360;
    final q = (280.459 + 0.98564736 * d) % 360;
    final l = (q + 1.915 * _sin(g) + 0.020 * _sin(2 * g)) % 360;

    final e = 23.439 - 0.00000036 * d;
    final ra = math.atan2(_cos(e) * _sin(l), _cos(l)) * 180 / math.pi;
    final decl = math.asin(_sin(e) * _sin(l)) * 180 / math.pi;
    final eqt = q / 15.0 - _fixAngle(ra) / 15.0;

    // Solar noon
    final transit = 12.0 + (longitude / -15.0) - eqt;

    // Sunrise / Sunset
    final sunriseHour = _hourAngle(latitude, decl, -0.8333);
    final sunriseTime = transit - sunriseHour / 15.0;
    final sunsetTime = transit + sunriseHour / 15.0;

    // Asr
    final shadowRatio = madhab == 'Hanafi' ? 2.0 : 1.0;
    final asrHour = _asrHourAngle(shadowRatio, latitude, decl);
    final asrTime = transit + asrHour / 15.0;

    // Fajr / Isha
    final params = _methods[calculationMethod] ?? _methods['MuslimWorldLeague']!;
    final fajrHour = _hourAngle(latitude, decl, -params.fajrAngle);
    final fajrTime = transit - fajrHour / 15.0;

    double ishaTime;
    if (params.ishaMinutes != null) {
      ishaTime = sunsetTime + params.ishaMinutes! / 60.0;
    } else {
      final ishaHour = _hourAngle(latitude, decl, -params.ishaAngle);
      ishaTime = transit + ishaHour / 15.0;
    }

    fajr = _toDateTime(fajrTime);
    sunrise = _toDateTime(sunriseTime);
    dhuhr = _toDateTime(transit + (1 / 60.0)); // add 1 min past solar noon
    asr = _toDateTime(asrTime);
    maghrib = _toDateTime(sunsetTime + (2 / 60.0)); // 2 mins after sunset
    isha = _toDateTime(ishaTime);
  }

  DateTime _toDateTime(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).floor();
    final s = (((hours - h) * 60 - m) * 60).round();
    // Clamp hour to valid range
    final clampedH = h.clamp(0, 23);
    return DateTime(date.year, date.month, date.day, clampedH, m.clamp(0, 59), s.clamp(0, 59));
  }

  /// Convert to list of [PrayerTimeEntity] with current/next highlighting.
  List<PrayerTimeEntity> toPrayerEntities({
    Map<String, bool> adhanEnabled = const {},
  }) {
    final prayers = [
      PrayerTimeEntity(
        name: 'Fajr',
        nameArabic: 'الفجر',
        time: fajr,
        isAdhanEnabled: adhanEnabled['Fajr'] ?? true,
      ),
      PrayerTimeEntity(
        name: 'Sunrise',
        nameArabic: 'الشروق',
        time: sunrise,
        isAdhanEnabled: false, // No adhan for sunrise
      ),
      PrayerTimeEntity(
        name: 'Dhuhr',
        nameArabic: 'الظهر',
        time: dhuhr,
        isAdhanEnabled: adhanEnabled['Dhuhr'] ?? true,
      ),
      PrayerTimeEntity(
        name: 'Asr',
        nameArabic: 'العصر',
        time: asr,
        isAdhanEnabled: adhanEnabled['Asr'] ?? true,
      ),
      PrayerTimeEntity(
        name: 'Maghrib',
        nameArabic: 'المغرب',
        time: maghrib,
        isAdhanEnabled: adhanEnabled['Maghrib'] ?? true,
      ),
      PrayerTimeEntity(
        name: 'Isha',
        nameArabic: 'العشاء',
        time: isha,
        isAdhanEnabled: adhanEnabled['Isha'] ?? true,
      ),
    ];
    return prayers;
  }

  // ── Math helpers ──

  static double _julianDay(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5;
  }

  static double _sin(double d) => math.sin(d * math.pi / 180);
  static double _cos(double d) => math.cos(d * math.pi / 180);
  static double _arccos(double x) => math.acos(x) * 180 / math.pi;
  static double _arctan2(double y, double x) => math.atan2(y, x) * 180 / math.pi;

  static double _fixAngle(double a) {
    a = a - 360.0 * (a / 360.0).floor();
    return a < 0 ? a + 360.0 : a;
  }

  static double _hourAngle(double lat, double decl, double angle) {
    final num = _cos(90 - angle) - _sin(decl) * _sin(lat);
    final den = _cos(decl) * _cos(lat);
    if (den == 0) return 0;
    final ratio = num / den;
    if (ratio < -1 || ratio > 1) return 0;
    return _arccos(ratio);
  }

  static double _asrHourAngle(double shadowRatio, double lat, double decl) {
    final targetAngle = _arctan2(1.0, shadowRatio + math.tan((lat - decl) * math.pi / 180).abs());
    return _hourAngle(lat, decl, targetAngle);
  }
}
