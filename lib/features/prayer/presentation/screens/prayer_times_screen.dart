import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/prayer_time_entity.dart';
import '../providers/prayer_providers.dart';

// ── Prayer theme data ──────────────────────────────────────────────────────

const _prayerColors = <String, Color>{
  'Fajr': AppColors.fajr,
  'Sunrise': AppColors.sunrise,
  'Dhuhr': AppColors.dhuhr,
  'Asr': AppColors.asr,
  'Maghrib': AppColors.maghrib,
  'Isha': AppColors.isha,
};

const _prayerGradients = <String, List<Color>>{
  'Fajr': [Color(0xFF283593), Color(0xFF1565C0)],
  'Sunrise': [Color(0xFFF57F17), Color(0xFFFF8F00)],
  'Dhuhr': [Color(0xFFFF8F00), Color(0xFFFFA000)],
  'Asr': [Color(0xFFEF6C00), Color(0xFFE65100)],
  'Maghrib': [Color(0xFFD84315), Color(0xFFBF360C)],
  'Isha': [Color(0xFF1A237E), Color(0xFF283593)],
};

const _prayerIcons = <String, IconData>{
  'Fajr': Icons.dark_mode_outlined,
  'Sunrise': Icons.wb_sunny_outlined,
  'Dhuhr': Icons.wb_sunny,
  'Asr': Icons.wb_twilight,
  'Maghrib': Icons.nights_stay_outlined,
  'Isha': Icons.nights_stay,
};

// ── Main Screen ────────────────────────────────────────────────────────────

/// Production-quality prayer times screen showing today's 5 prayers + sunrise,
/// real-time countdown to next prayer, monthly calendar toggle, location
/// auto-detect, and calculation method / madhab selectors.
class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen>
    with SingleTickerProviderStateMixin {
  bool _showCalendar = false;
  late final TabController _calendarTabController;
  late DateTime _calendarMonth;

  @override
  void initState() {
    super.initState();
    _calendarMonth = DateTime.now();
    _calendarTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _calendarTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayerSchedule = ref.watch(dailyPrayerTimesProvider);
    final nextPrayer = ref.watch(upcomingPrayerProvider);
    final countdown = ref.watch(nextPrayerCountdownProvider);
    final isLocationLoading = ref.watch(locationLoadingProvider);
    final locationError = ref.watch(locationErrorProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: _buildAppBar(context, ref, isDark),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: context.bottomPadding + 88,
        ),
        children: [
          // ── Location card ──
          _LocationCard(
            locationName: prayerSchedule.locationName,
            date: prayerSchedule.date,
            isLoading: isLocationLoading,
            error: locationError,
            isDark: isDark,
            onDetect: () => _detectLocation(context, ref),
          ),
          const SizedBox(height: 12),

          // ── Countdown to next prayer ──
          if (nextPrayer != null && countdown != null)
            _CountdownBanner(
              nextPrayer: nextPrayer,
              countdown: countdown,
              isDark: isDark,
            ),

          const SizedBox(height: 12),

          // ── Calendar toggle ──
          _CalendarToggleButton(
            isOpen: _showCalendar,
            onToggle: () => setState(() => _showCalendar = !_showCalendar),
          ),

          if (_showCalendar) ...[
            const SizedBox(height: 8),
            _MonthlyCalendarView(
              month: _calendarMonth,
              onMonthChanged: (m) => setState(() => _calendarMonth = m),
              isDark: isDark,
            ),
          ],

          const SizedBox(height: 12),

          // ── Prayer cards ──
          ...prayerSchedule.prayers.map(
            (prayer) => _PrayerCard(
              prayer: prayer,
              isCurrent: ref.watch(currentPrayerProvider)?.name == prayer.name,
              isNext: nextPrayer?.name == prayer.name,
              isDark: isDark,
            ),
          ),

          const SizedBox(height: 12),

          // ── Settings shortcut row ──
          _SettingsRow(isDark: isDark),

          const SizedBox(height: 12),

          // ── Qibla shortcut ──
          _QiblaShortcut(isDark: isDark),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref, bool isDark) {
    return AppBar(
      title: Text(
        'مواقيت الصلاة',
        style: AppTextStyles.arabicHeadline.copyWith(color: AppColors.primary),
      ),
      actions: [
        // Calculation method button
        IconButton(
          icon: const Icon(Icons.calculate_outlined),
          tooltip: 'طريقة الحساب',
          onPressed: () => _showCalculationMethodSheet(context, ref),
        ),
        // Location detect button
        IconButton(
          icon: const Icon(Icons.my_location_outlined),
          tooltip: 'تحديد الموقع تلقائياً',
          onPressed: () => _detectLocation(context, ref),
        ),
        // Qibla button
        IconButton(
          icon: const Icon(Icons.explore_outlined),
          tooltip: 'القبلة',
          onPressed: () => context.pushNamed(RouteNames.qibla),
        ),
      ],
    );
  }

  Future<void> _detectLocation(BuildContext context, WidgetRef ref) async {
    await ref.read(locationNotifierProvider.notifier).detectLocation();
    final error = ref.read(locationErrorProvider);
    if (error != null && mounted) {
      final isPermanent = error.contains('دائم');
      if (isPermanent) {
        _showPermissionDialog(context, ref);
      } else {
        context.showSnackBar(error);
      }
    }
  }

  void _showPermissionDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'إذن الموقع',
          style: AppTextStyles.arabicHeadline,
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'يرجى السماح بالوصول إلى الموقع من إعدادات التطبيق لتحديد أوقات الصلاة بدقة.',
          style: AppTextStyles.arabicBody,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('لاحقاً'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(locationNotifierProvider.notifier).openSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  void _showCalculationMethodSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(calculationMethodProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, controller) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'طريقة الحساب',
                style: AppTextStyles.arabicHeadline,
                textDirection: TextDirection.rtl,
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    for (final method in CalculationMethod.values)
                      RadioListTile<String>(
                        title: Text(
                          method.labelArabic,
                          style: AppTextStyles.arabicBody,
                          textDirection: TextDirection.rtl,
                        ),
                        value: method.key,
                        groupValue: current,
                        activeColor: AppColors.primary,
                        onChanged: (v) {
                          if (v != null) {
                            ref.read(calculationMethodProvider.notifier).state = v;
                          }
                          Navigator.of(ctx).pop();
                        },
                      ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'المذهب (وقت العصر)',
                        style: AppTextStyles.arabicCaption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    for (final madhab in Madhab.values)
                      RadioListTile<String>(
                        title: Text(
                          madhab.labelArabic,
                          style: AppTextStyles.arabicBody,
                          textDirection: TextDirection.rtl,
                        ),
                        value: madhab.key,
                        groupValue: ref.watch(madhabProvider),
                        activeColor: AppColors.primary,
                        onChanged: (v) {
                          if (v != null) {
                            ref.read(madhabProvider.notifier).state = v;
                          }
                          Navigator.of(ctx).pop();
                        },
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final String locationName;
  final DateTime date;
  final bool isLoading;
  final String? error;
  final bool isDark;
  final VoidCallback onDetect;

  const _LocationCard({
    required this.locationName,
    required this.date,
    required this.isLoading,
    required this.error,
    required this.isDark,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.tertiary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onDetect,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.my_location, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  error != null ? 'موقع افتراضي' : locationName,
                  style: AppTextStyles.arabicBody.copyWith(
                    color: error != null ? AppColors.warning : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                ),
                if (error != null)
                  Text(
                    'اضغط لإعادة المحاولة',
                    style: AppTextStyles.arabicCaption.copyWith(
                      color: AppColors.textTertiaryLight,
                      fontSize: 12,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat.yMMMd('ar').format(date),
            style: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

class _CountdownBanner extends StatelessWidget {
  final PrayerTimeEntity nextPrayer;
  final Duration countdown;
  final bool isDark;

  const _CountdownBanner({
    required this.nextPrayer,
    required this.countdown,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = _prayerColors[nextPrayer.name] ?? AppColors.primary;
    final gradients = _prayerGradients[nextPrayer.name] ??
        [AppColors.primary, AppColors.primaryLight];

    final hours = countdown.inHours;
    final minutes = countdown.inMinutes.remainder(60);
    final seconds = countdown.inSeconds.remainder(60);

    String countdownStr;
    if (hours > 0) {
      countdownStr =
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      countdownStr =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: gradients,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: countdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الوقت المتبقي',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                countdownStr,
                style: AppTextStyles.displayMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          // Right: next prayer name
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'الصلاة التالية',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 2),
              Text(
                nextPrayer.nameArabic,
                style: AppTextStyles.arabicHeadline.copyWith(
                  color: Colors.white,
                  fontSize: 26,
                ),
                textDirection: TextDirection.rtl,
              ),
              Text(
                DateFormat.jm().format(nextPrayer.time),
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarToggleButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;

  const _CalendarToggleButton({required this.isOpen, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedRotation(
              turns: isOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.expand_more, color: AppColors.primary, size: 20),
            ),
            Text(
              isOpen ? 'إخفاء تقويم الشهر' : 'عرض تقويم الشهر',
              style: AppTextStyles.arabicBody.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              textDirection: TextDirection.rtl,
            ),
            const Icon(Icons.calendar_month_outlined, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MonthlyCalendarView extends ConsumerWidget {
  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;
  final bool isDark;

  const _MonthlyCalendarView({
    required this.month,
    required this.onMonthChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(
      monthlyPrayerTimesProvider((year: month.year, month: month.month)),
    );

    final today = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Month header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () => onMonthChanged(
                    DateTime(month.year, month.month + 1),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Text(
                  DateFormat.yMMMM('ar').format(month),
                  style: AppTextStyles.arabicBody.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: month.month > 1 || month.year > today.year
                      ? () => onMonthChanged(
                            DateTime(month.year, month.month - 1),
                          )
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                for (final label in ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء', 'اليوم'])
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.arabicCaption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Days
          if (schedules.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: schedules.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                final isToday = schedule.date.day == today.day &&
                    schedule.date.month == today.month &&
                    schedule.date.year == today.year;

                final times = schedule.prayers
                    .where((p) => p.name != 'Sunrise')
                    .toList();

                return Container(
                  color: isToday
                      ? AppColors.primary.withValues(alpha: 0.06)
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Row(
                    children: [
                      // Prayer times (reversed for RTL: Fajr, Dhuhr, Asr, Maghrib, Isha)
                      for (final prayer in times)
                        Expanded(
                          child: Text(
                            DateFormat('HH:mm').format(prayer.time),
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 10,
                              color: isToday
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      // Day number
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: isToday
                              ? BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Text(
                            '${schedule.date.day}',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 11,
                              color: isToday
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight),
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final PrayerTimeEntity prayer;
  final bool isCurrent;
  final bool isNext;
  final bool isDark;

  const _PrayerCard({
    required this.prayer,
    required this.isCurrent,
    required this.isNext,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = _prayerColors[prayer.name] ?? AppColors.primary;
    final gradients = _prayerGradients[prayer.name] ??
        [AppColors.primary, AppColors.primaryLight];
    final icon = _prayerIcons[prayer.name] ?? Icons.access_time;
    final isHighlighted = isCurrent || isNext;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: isHighlighted
            ? Border.all(color: color, width: 1.5)
            : Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                width: 0.5,
              ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Gradient accent strip on right edge
            if (isHighlighted)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: gradients,
                    ),
                  ),
                ),
              ),
            ListTile(
              contentPadding: const EdgeInsets.only(
                left: 12,
                right: 16,
                top: 4,
                bottom: 4,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isHighlighted
                      ? LinearGradient(
                          colors: gradients.map((c) => c.withValues(alpha: 0.15)).toList(),
                        )
                      : null,
                  color: isHighlighted ? null : color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              title: Text(
                prayer.nameArabic,
                style: AppTextStyles.arabicBody.copyWith(
                  fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
                  color: isHighlighted
                      ? color
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
                textDirection: TextDirection.rtl,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat.jm().format(prayer.time),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
                      color: isHighlighted
                          ? color
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isCurrent)
                    _PrayerBadge(label: 'الآن', color: AppColors.success)
                  else if (isNext)
                    _PrayerBadge(label: 'التالية', color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PrayerBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontFamily: 'Amiri',
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SettingsRow extends ConsumerWidget {
  final bool isDark;

  const _SettingsRow({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = ref.watch(calculationMethodProvider);
    final madhab = ref.watch(madhabProvider);

    final methodLabel = CalculationMethod.fromKey(method).labelArabic;
    final madhabLabel = Madhab.fromKey(madhab).labelArabic;

    return Row(
      children: [
        Expanded(
          child: _InfoChip(
            icon: Icons.calculate_outlined,
            label: methodLabel,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InfoChip(
            icon: Icons.access_time,
            label: madhabLabel,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoChip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.arabicCaption.copyWith(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textDirection: TextDirection.rtl,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 14, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _QiblaShortcut extends StatelessWidget {
  final bool isDark;

  const _QiblaShortcut({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: () => context.pushNamed(RouteNames.qibla),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.explore, color: AppColors.secondary, size: 24),
        ),
        title: Text(
          'اتجاه القبلة',
          style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w600),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Text(
          'البوصلة لتحديد اتجاه الكعبة المشرفة',
          style: AppTextStyles.arabicCaption.copyWith(
            color: AppColors.textTertiaryLight,
          ),
          textDirection: TextDirection.rtl,
        ),
        trailing: const Icon(Icons.chevron_left),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
