import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/daily_ayah_card.dart';
import '../widgets/last_read_card.dart';
import '../widgets/prayer_countdown_widget.dart';

/// Home screen / dashboard of the Quran App.
///
/// Displays:
/// - Gradient header with greeting and date
/// - Last-read resume card
/// - Daily Ayah card
/// - Prayer countdown
/// - Quick-access feature grid
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = context.isDarkMode;
    final now = DateTime.now();
    final greeting = _greeting(now.hour);

    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -- Gradient Header --
            _GradientHeader(
              greeting: greeting,
              isDark: isDark,
              colorScheme: colorScheme,
              onSearchTap: () => context.pushNamed(RouteNames.search),
              onSettingsTap: () => context.pushNamed(RouteNames.settings),
            ).animate().fadeIn(duration: 500.ms).slideY(
                  begin: -0.1,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOut,
                ),

            const SizedBox(height: 8),

            // -- Last Read Card --
            const LastReadCard()
                .animate()
                .fadeIn(delay: 150.ms, duration: 450.ms)
                .slideX(begin: 0.05, end: 0, duration: 450.ms),

            // -- Daily Ayah --
            const DailyAyahCard()
                .animate()
                .fadeIn(delay: 250.ms, duration: 450.ms)
                .slideY(begin: 0.05, end: 0, duration: 450.ms),

            // -- Prayer Countdown --
            const PrayerCountdownWidget()
                .animate()
                .fadeIn(delay: 350.ms, duration: 450.ms)
                .slideX(begin: -0.05, end: 0, duration: 450.ms),

            const SizedBox(height: 24),

            // -- Quick Actions Section Header --
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'الوصول السريع',
                    style: AppTextStyles.arabicBody.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      fontSize: 17,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 450.ms, duration: 400.ms),

            const SizedBox(height: 14),

            // -- Quick Access Grid --
            _QuickAccessGrid()
                .animate()
                .fadeIn(delay: 500.ms, duration: 450.ms)
                .slideY(begin: 0.08, end: 0, duration: 450.ms),

            // Bottom padding for safe area / bottom nav
            SizedBox(height: context.bottomPadding + 100),
          ],
        ),
      ),
    );
  }

  String _greeting(int hour) {
    if (hour >= 5 && hour < 12) return 'صباح الخير';
    if (hour >= 12 && hour < 17) return 'مساء الخير';
    if (hour >= 17 && hour < 21) return 'مساء النور';
    return 'مرحباً بك';
  }
}

// -- Gradient Header ---------------------------------------------------------

class _GradientHeader extends StatelessWidget {
  final String greeting;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onSearchTap;
  final VoidCallback onSettingsTap;

  const _GradientHeader({
    required this.greeting,
    required this.isDark,
    required this.colorScheme,
    required this.onSearchTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = context.topPadding;
    final now = DateTime.now();
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    final days = [
      'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
      'الجمعة', 'السبت', 'الأحد',
    ];
    final dayName = days[now.weekday - 1];
    final dateString =
        '$dayName، ${now.day.toString().toArabicNumerals} ${months[now.month - 1]}';

    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 16,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryDark,
                  const Color(0xFF0A2E0A),
                  AppColors.backgroundDark,
                ]
              : [
                  AppColors.primary,
                  AppColors.primaryLight,
                  AppColors.primaryContainer,
                ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _HeaderIconButton(
                    icon: Icons.search_rounded,
                    tooltip: 'بحث',
                    onPressed: onSearchTap,
                  ),
                  const SizedBox(width: 8),
                  _HeaderIconButton(
                    icon: Icons.settings_outlined,
                    tooltip: 'الإعدادات',
                    onPressed: onSettingsTap,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Greeting
              Text(
                'السلام عليكم',
                style: AppTextStyles.arabicHeadline.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 4),

              // Sub-greeting
              Text(
                greeting,
                style: AppTextStyles.arabicBody.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 10),

              // Date
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateString,
                      style: AppTextStyles.arabicCaption.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

// -- Quick Access Grid -------------------------------------------------------

class _QuickAccessGrid extends StatelessWidget {
  static const _items = <_QuickAccessItem>[
    _QuickAccessItem(
      icon: Icons.menu_book_rounded,
      label: 'القرآن',
      route: RouteNames.surahIndex,
      color: AppColors.primary,
    ),
    _QuickAccessItem(
      icon: Icons.headphones_rounded,
      label: 'الاستماع',
      route: RouteNames.audioPlayer,
      color: AppColors.tertiary,
    ),
    _QuickAccessItem(
      icon: Icons.mosque_rounded,
      label: 'الصلاة',
      route: RouteNames.prayerTimes,
      color: AppColors.fajr,
    ),
    _QuickAccessItem(
      icon: Icons.explore_rounded,
      label: 'القبلة',
      route: RouteNames.qibla,
      color: AppColors.maghrib,
    ),
    _QuickAccessItem(
      icon: Icons.school_rounded,
      label: 'الحفظ',
      route: RouteNames.hifzDashboard,
      color: AppColors.secondary,
    ),
    _QuickAccessItem(
      icon: Icons.quiz_rounded,
      label: 'مسابقات',
      route: RouteNames.mosabqatHome,
      color: AppColors.info,
    ),
    _QuickAccessItem(
      icon: Icons.bookmark_rounded,
      label: 'الإشارات',
      route: RouteNames.bookmarks,
      color: AppColors.error,
    ),
    _QuickAccessItem(
      icon: Icons.download_rounded,
      label: 'التحميل',
      route: RouteNames.downloads,
      color: AppColors.success,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return _QuickAccessTile(item: _items[index])
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 550 + (index * 60)),
                duration: 350.ms,
              )
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                delay: Duration(milliseconds: 550 + (index * 60)),
                duration: 350.ms,
                curve: Curves.easeOut,
              );
        },
      ),
    );
  }
}

class _QuickAccessItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}

class _QuickAccessTile extends StatelessWidget {
  final _QuickAccessItem item;

  const _QuickAccessTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(18),
      elevation: isDark ? 0 : 1,
      shadowColor: item.color.withValues(alpha: 0.2),
      child: InkWell(
        onTap: () => context.pushNamed(item.route),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? AppColors.dividerDark
                  : item.color.withValues(alpha: 0.12),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      item.color.withValues(alpha: isDark ? 0.2 : 0.12),
                      item.color.withValues(alpha: isDark ? 0.08 : 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Text(
                  item.label,
                  style: AppTextStyles.arabicCaption.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: colorScheme.onSurface,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
