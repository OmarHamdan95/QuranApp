import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Data class representing the next prayer for the countdown.
class NextPrayerInfo {
  final String name;
  final String nameArabic;
  final DateTime time;
  final Color color;

  const NextPrayerInfo({
    required this.name,
    required this.nameArabic,
    required this.time,
    required this.color,
  });
}

/// Generates realistic placeholder prayer times based on the current time.
NextPrayerInfo _buildPlaceholderNextPrayer() {
  final now = DateTime.now();

  // Approximate prayer schedule (hours in 24-hour format).
  final prayers = [
    (name: 'Fajr',    nameAr: 'الفجر',   hour: 5,  minute: 15, color: AppColors.fajr),
    (name: 'Dhuhr',   nameAr: 'الظهر',   hour: 12, minute: 30, color: AppColors.dhuhr),
    (name: 'Asr',     nameAr: 'العصر',   hour: 15, minute: 45, color: AppColors.asr),
    (name: 'Maghrib', nameAr: 'المغرب',  hour: 18, minute: 20, color: AppColors.maghrib),
    (name: 'Isha',    nameAr: 'العشاء',  hour: 20, minute: 0,  color: AppColors.isha),
  ];

  for (final p in prayers) {
    final prayerTime = DateTime(
        now.year, now.month, now.day, p.hour, p.minute);
    if (prayerTime.isAfter(now)) {
      return NextPrayerInfo(
        name: p.name,
        nameArabic: p.nameAr,
        time: prayerTime,
        color: p.color,
      );
    }
  }

  // All prayers passed today -- return tomorrow's Fajr.
  final fajr = prayers.first;
  final tomorrowFajr = DateTime(
    now.year, now.month, now.day + 1, fajr.hour, fajr.minute);
  return NextPrayerInfo(
    name: fajr.name,
    nameArabic: fajr.nameAr,
    time: tomorrowFajr,
    color: fajr.color,
  );
}

/// Provider for the next prayer info.
///
/// Returns placeholder data based on approximate prayer times until a proper
/// prayer-time calculation library is configured with the user's location.
final nextPrayerProvider = StateProvider<NextPrayerInfo>((ref) {
  return _buildPlaceholderNextPrayer();
});

/// A compact widget showing a live countdown to the next prayer time.
///
/// Updates every second and refreshes the prayer info automatically
/// when the target prayer time is reached.
class PrayerCountdownWidget extends ConsumerStatefulWidget {
  const PrayerCountdownWidget({super.key});

  @override
  ConsumerState<PrayerCountdownWidget> createState() =>
      _PrayerCountdownWidgetState();
}

class _PrayerCountdownWidgetState
    extends ConsumerState<PrayerCountdownWidget> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final nextPrayer = ref.read(nextPrayerProvider);
    final now = DateTime.now();
    var remaining = nextPrayer.time.difference(now);

    if (remaining.isNegative || remaining == Duration.zero) {
      // Prayer time passed -- recalculate next prayer.
      ref.read(nextPrayerProvider.notifier).state =
          _buildPlaceholderNextPrayer();
      remaining = ref.read(nextPrayerProvider).time.difference(now);
    }

    if (mounted) {
      setState(() {
        _remaining = remaining.isNegative ? Duration.zero : remaining;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayer = ref.watch(nextPrayerProvider);
    final isDark = context.isDarkMode;

    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return GestureDetector(
      onTap: () => context.pushNamed(RouteNames.prayerTimes),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: nextPrayer.color.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: nextPrayer.color.withValues(alpha: 0.08),
                    blurRadius: 16,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Subtle colored accent in the corner
            Positioned(
              top: -20,
              left: -20,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: nextPrayer.color.withValues(alpha: isDark ? 0.06 : 0.04),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  // -- Prayer Icon --
                  _PrayerIcon(color: nextPrayer.color, isDark: isDark),
                  const SizedBox(width: 14),

                  // -- Prayer Info --
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'الصلاة القادمة',
                          style: AppTextStyles.arabicCaption.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                            fontSize: 11,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          nextPrayer.nameArabic,
                          style: AppTextStyles.arabicBody.copyWith(
                            fontWeight: FontWeight.w800,
                            color: nextPrayer.color,
                            fontSize: 18,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // -- Countdown --
                  _CountdownDisplay(
                    hours: hours,
                    minutes: minutes,
                    seconds: seconds,
                    color: nextPrayer.color,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Prayer Icon -------------------------------------------------------------

class _PrayerIcon extends StatelessWidget {
  final Color color;
  final bool isDark;

  const _PrayerIcon({required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.25 : 0.15),
            color.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Icon(
        Icons.mosque_rounded,
        color: color,
        size: 26,
      ),
    );
  }
}

// -- Countdown Display -------------------------------------------------------

class _CountdownDisplay extends StatelessWidget {
  final int hours;
  final int minutes;
  final int seconds;
  final Color color;
  final bool isDark;

  const _CountdownDisplay({
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.18 : 0.1),
            color.withValues(alpha: isDark ? 0.08 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TimeUnit(value: hours, label: 'س', color: color),
          _Colon(color: color),
          _TimeUnit(value: minutes, label: 'د', color: color),
          _Colon(color: color),
          _TimeUnit(value: seconds, label: 'ث', color: color),
        ],
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _TimeUnit({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: [const FontFeature.tabularFigures()],
            fontSize: 20,
            height: 1.1,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontFamily: 'Amiri',
            color: color.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _Colon extends StatelessWidget {
  final Color color;

  const _Colon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        ':',
        style: AppTextStyles.headlineMedium.copyWith(
          color: color.withValues(alpha: 0.5),
          fontWeight: FontWeight.w800,
          fontSize: 20,
          height: 1.1,
        ),
      ),
    );
  }
}
