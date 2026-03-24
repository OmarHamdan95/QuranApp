import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
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

/// Provider for the next prayer info. Returns placeholder data until
/// prayer time calculation is initialized.
final nextPrayerProvider = StateProvider<NextPrayerInfo>((ref) {
  // Placeholder: next prayer at the upcoming hour mark.
  final now = DateTime.now();
  final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
  return NextPrayerInfo(
    name: 'Dhuhr',
    nameArabic: 'الظهر',
    time: nextHour,
    color: AppColors.dhuhr,
  );
});

/// A compact widget showing a live countdown to the next prayer time.
class PrayerCountdownWidget extends ConsumerStatefulWidget {
  const PrayerCountdownWidget({super.key});

  @override
  ConsumerState<PrayerCountdownWidget> createState() =>
      _PrayerCountdownWidgetState();
}

class _PrayerCountdownWidgetState extends ConsumerState<PrayerCountdownWidget> {
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
    setState(() {
      _remaining = nextPrayer.time.difference(now);
      if (_remaining.isNegative) {
        _remaining = Duration.zero;
      }
    });
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: nextPrayer.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Prayer icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: nextPrayer.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.mosque_outlined,
              color: nextPrayer.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Prayer name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الصلاة القادمة',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 2),
                Text(
                  nextPrayer.nameArabic,
                  style: AppTextStyles.arabicBody.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nextPrayer.color,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),

          // Countdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: nextPrayer.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CountdownUnit(value: hours, label: 'س'),
                _CountdownSeparator(color: nextPrayer.color),
                _CountdownUnit(value: minutes, label: 'د'),
                _CountdownSeparator(color: nextPrayer.color),
                _CountdownUnit(value: seconds, label: 'ث'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  final int value;
  final String label;

  const _CountdownUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontFamily: 'Amiri',
            color: AppColors.textTertiaryLight,
          ),
        ),
      ],
    );
  }
}

class _CountdownSeparator extends StatelessWidget {
  final Color color;

  const _CountdownSeparator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: AppTextStyles.headlineMedium.copyWith(
          color: color.withValues(alpha: 0.5),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
