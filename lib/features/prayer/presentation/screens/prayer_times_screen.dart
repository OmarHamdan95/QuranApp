import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/prayer_providers.dart';

/// Maps prayer names to their themed colors.
const _prayerColors = {
  'Fajr': AppColors.fajr,
  'Sunrise': AppColors.sunrise,
  'Dhuhr': AppColors.dhuhr,
  'Asr': AppColors.asr,
  'Maghrib': AppColors.maghrib,
  'Isha': AppColors.isha,
};

/// Maps prayer names to icons.
const _prayerIcons = {
  'Fajr': Icons.dark_mode_outlined,
  'Sunrise': Icons.wb_sunny_outlined,
  'Dhuhr': Icons.wb_sunny,
  'Asr': Icons.wb_twilight,
  'Maghrib': Icons.nights_stay_outlined,
  'Isha': Icons.nights_stay,
};

/// Screen showing today's prayer times for the user's location.
class PrayerTimesScreen extends ConsumerWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerTimes = ref.watch(dailyPrayerTimesProvider);
    final isDark = context.isDarkMode;
    final timeFormat = DateFormat.jm();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مواقيت الصلاة',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            onPressed: () => context.pushNamed(RouteNames.qibla),
            tooltip: 'القبلة',
          ),
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            onPressed: () {
              // TODO: Open location picker
            },
            tooltip: 'الموقع',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Location header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.tertiary.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  prayerTimes.locationName,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat.yMMMd('ar').format(prayerTimes.date),
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Prayer time cards
          ...prayerTimes.prayers.map((prayer) {
            final color = _prayerColors[prayer.name] ?? AppColors.primary;
            final icon = _prayerIcons[prayer.name] ?? Icons.access_time;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(14),
                border: prayer.isNext
                    ? Border.all(color: color, width: 1.5)
                    : Border.all(
                        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                        width: 0.5,
                      ),
                boxShadow: prayer.isNext
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: prayer.isNext ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                title: Text(
                  prayer.nameArabic,
                  style: AppTextStyles.arabicBody.copyWith(
                    fontWeight: prayer.isNext ? FontWeight.w700 : FontWeight.w400,
                    color: prayer.isNext
                        ? color
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight),
                  ),
                  textDirection: TextDirection.rtl,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeFormat.format(prayer.time),
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: prayer.isNext ? FontWeight.w700 : FontWeight.w400,
                        color: prayer.isNext ? color : null,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                    if (prayer.isNext) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'التالية',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: color,
                            fontFamily: 'Amiri',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Qibla compass shortcut
          Card(
            child: ListTile(
              onTap: () => context.pushNamed(RouteNames.qibla),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.explore, color: AppColors.secondary, size: 22),
              ),
              title: Text(
                'اتجاه القبلة',
                style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w600),
                textDirection: TextDirection.rtl,
              ),
              subtitle: Text(
                'البوصلة لتحديد اتجاه الكعبة',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                textDirection: TextDirection.rtl,
              ),
              trailing: const Icon(Icons.chevron_left),
            ),
          ),
        ],
      ),
    );
  }
}
