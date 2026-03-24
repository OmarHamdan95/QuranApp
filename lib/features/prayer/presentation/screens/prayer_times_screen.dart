import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(context, ref, theme),
      body: ListView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: context.bottomPadding + 88,
        ),
        children: [
          // ── Date & location header ──
          _DateLocationHeader(
            locationName: prayerSchedule.locationName,
            date: prayerSchedule.date,
            isLoading: isLocationLoading,
            error: locationError,
            onDetect: () => _detectLocation(context, ref),
          ),
          const SizedBox(height: 16),

          // ── Countdown to next prayer ──
          if (nextPrayer != null && countdown != null)
            _CountdownCard(
              nextPrayer: nextPrayer,
              countdown: countdown,
            ),

          const SizedBox(height: 20),

          // ── Prayer cards ──
          ...prayerSchedule.prayers.map(
            (prayer) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PrayerTimeCard(
                prayer: prayer,
                isCurrent: ref.watch(currentPrayerProvider)?.name == prayer.name,
                isNext: nextPrayer?.name == prayer.name,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Calendar toggle ──
          _CalendarToggleButton(
            isOpen: _showCalendar,
            onToggle: () => setState(() => _showCalendar = !_showCalendar),
          ),

          if (_showCalendar) ...[
            const SizedBox(height: 12),
            _MonthlyCalendarView(
              month: _calendarMonth,
              onMonthChanged: (m) => setState(() => _calendarMonth = m),
              isDark: isDark,
            ),
          ],

          const SizedBox(height: 16),

          // ── Settings info row ──
          _SettingsInfoRow(isDark: isDark),

          const SizedBox(height: 12),

          // ── Qibla shortcut ──
          _QiblaShortcut(),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref, ThemeData theme) {
    return AppBar(
      title: Text(
        'مواقيت الصلاة',
        style: AppTextStyles.arabicHeadline.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calculate_outlined),
          tooltip: 'طريقة الحساب',
          onPressed: () => _showCalculationMethodSheet(context, ref),
        ),
        IconButton(
          icon: const Icon(Icons.my_location_outlined),
          tooltip: 'تحديد الموقع تلقائياً',
          onPressed: () => _detectLocation(context, ref),
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          FilledButton(
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'طريقة الحساب',
                style: AppTextStyles.arabicHeadline,
                textDirection: TextDirection.rtl,
              ),
              const Divider(height: 24),
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
                        activeColor: Theme.of(ctx).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onChanged: (v) {
                          if (v != null) {
                            ref.read(calculationMethodProvider.notifier).state = v;
                          }
                          Navigator.of(ctx).pop();
                        },
                      ),
                    const Divider(height: 24),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'المذهب (وقت العصر)',
                        style: AppTextStyles.arabicCaption.copyWith(
                          color: Theme.of(ctx).colorScheme.primary,
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
                        activeColor: Theme.of(ctx).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

// ── Date & Location Header ──────────────────────────────────────────────────

class _DateLocationHeader extends StatelessWidget {
  final String locationName;
  final DateTime date;
  final bool isLoading;
  final String? error;
  final VoidCallback onDetect;

  const _DateLocationHeader({
    required this.locationName,
    required this.date,
    required this.isLoading,
    required this.error,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.tertiary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          // Date row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat.yMMMMEEEEd('ar').format(date),
                style: AppTextStyles.arabicBody.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 10),
          // Location row
          GestureDetector(
            onTap: onDetect,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                else
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: error != null
                        ? AppColors.warning
                        : colorScheme.primary,
                  ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    error != null
                        ? 'موقع افتراضي - اضغط لإعادة المحاولة'
                        : locationName,
                    style: AppTextStyles.arabicCaption.copyWith(
                      color: error != null
                          ? AppColors.warning
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    textDirection: TextDirection.rtl,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Countdown Card ──────────────────────────────────────────────────────────

class _CountdownCard extends StatelessWidget {
  final PrayerTimeEntity nextPrayer;
  final Duration countdown;

  const _CountdownCard({
    required this.nextPrayer,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    final gradients = _prayerGradients[nextPrayer.name] ??
        [AppColors.primary, AppColors.primaryLight];
    final color = _prayerColors[nextPrayer.name] ?? AppColors.primary;

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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: gradients,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: countdown timer
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
              const SizedBox(height: 4),
              Text(
                countdownStr,
                style: AppTextStyles.displayMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 36,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          // Right: next prayer info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'الصلاة التالية',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                nextPrayer.nameArabic,
                style: AppTextStyles.arabicHeadline.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                ),
                textDirection: TextDirection.rtl,
              ),
              Text(
                DateFormat.jm().format(nextPrayer.time),
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Prayer Time Card ────────────────────────────────────────────────────────

class _PrayerTimeCard extends StatelessWidget {
  final PrayerTimeEntity prayer;
  final bool isCurrent;
  final bool isNext;

  const _PrayerTimeCard({
    required this.prayer,
    required this.isCurrent,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = _prayerColors[prayer.name] ?? colorScheme.primary;
    final gradients = _prayerGradients[prayer.name] ??
        [colorScheme.primary, AppColors.primaryLight];
    final icon = _prayerIcons[prayer.name] ?? Icons.access_time;
    final isHighlighted = isCurrent || isNext;

    // Next prayer gets an accent gradient background
    if (isNext) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              gradients[0].withValues(alpha: 0.15),
              gradients[1].withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _buildContent(
          context, color, icon, isHighlighted, isDark, colorScheme,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent
            ? Border.all(
                color: AppColors.success.withValues(alpha: 0.4),
                width: 1.5,
              )
            : Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                width: 0.5,
              ),
      ),
      child: _buildContent(
        context, color, icon, isHighlighted, isDark, colorScheme,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Color color,
    IconData icon,
    bool isHighlighted,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Time & badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCurrent)
                _StatusBadge(label: 'الآن', color: AppColors.success)
              else if (isNext)
                _StatusBadge(label: 'التالية', color: color),
              if (isHighlighted) const SizedBox(width: 8),
              Text(
                DateFormat.jm().format(prayer.time),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                  color: isHighlighted
                      ? color
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Prayer name
          Text(
            prayer.nameArabic,
            style: AppTextStyles.arabicBody.copyWith(
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
              fontSize: 17,
              color: isHighlighted
                  ? color
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 12),
          // Icon container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: isHighlighted
                  ? LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.08),
                      ],
                    )
                  : null,
              color: isHighlighted ? null : color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontFamily: 'Amiri',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Calendar Toggle ─────────────────────────────────────────────────────────

class _CalendarToggleButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;

  const _CalendarToggleButton({required this.isOpen, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedRotation(
                turns: isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.expand_more,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              Text(
                isOpen ? 'إخفاء تقويم الشهر' : 'عرض تقويم الشهر',
                style: AppTextStyles.arabicBody.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textDirection: TextDirection.rtl,
              ),
              Icon(
                Icons.calendar_month_outlined,
                color: colorScheme.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Monthly Calendar View ───────────────────────────────────────────────────

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigation header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                  onPressed: () => onMonthChanged(
                    DateTime(month.year, month.month + 1),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  DateFormat.yMMMM('ar').format(month),
                  style: AppTextStyles.arabicBody.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    fontSize: 16,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                  onPressed: month.month > 1 || month.year > today.year
                      ? () => onMonthChanged(
                            DateTime(month.year, month.month - 1),
                          )
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: colorScheme.primary.withValues(alpha: 0.04),
            child: Row(
              children: [
                for (final label in [
                  'الفجر',
                  'الظهر',
                  'العصر',
                  'المغرب',
                  'العشاء',
                  'اليوم',
                ])
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.arabicCaption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
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
              padding: EdgeInsets.all(24),
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
                      ? colorScheme.primary.withValues(alpha: 0.06)
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      for (final prayer in times)
                        Expanded(
                          child: Text(
                            DateFormat('HH:mm').format(prayer.time),
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 10,
                              color: isToday
                                  ? colorScheme.primary
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                              fontWeight:
                                  isToday ? FontWeight.w700 : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: isToday
                              ? BoxDecoration(
                                  color: colorScheme.primary,
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
                              fontWeight:
                                  isToday ? FontWeight.w700 : FontWeight.w400,
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

// ── Settings Info Row ───────────────────────────────────────────────────────

class _SettingsInfoRow extends ConsumerWidget {
  final bool isDark;

  const _SettingsInfoRow({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = ref.watch(calculationMethodProvider);
    final madhab = ref.watch(madhabProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final methodLabel = CalculationMethod.fromKey(method).labelArabic;
    final madhabLabel = Madhab.fromKey(madhab).labelArabic;

    return Row(
      children: [
        Expanded(
          child: _InfoChip(
            icon: Icons.calculate_outlined,
            label: methodLabel,
            colorScheme: colorScheme,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoChip(
            icon: Icons.access_time,
            label: madhabLabel,
            colorScheme: colorScheme,
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
  final ColorScheme colorScheme;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.arabicCaption.copyWith(
                fontSize: 11,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textDirection: TextDirection.rtl,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 15, color: colorScheme.primary),
        ],
      ),
    );
  }
}

// ── Qibla Shortcut Card ─────────────────────────────────────────────────────

class _QiblaShortcut extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => context.pushNamed(RouteNames.qibla),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.chevron_left,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'اتجاه القبلة',
                    style: AppTextStyles.arabicBody.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'البوصلة لتحديد اتجاه الكعبة المشرفة',
                    style: AppTextStyles.arabicCaption.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.explore,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
