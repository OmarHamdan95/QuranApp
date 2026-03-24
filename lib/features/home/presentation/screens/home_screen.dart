import 'package:flutter/material.dart';
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
/// - Personalised greeting
/// - Daily Ayah card
/// - Prayer countdown
/// - Last-read resume card
/// - Quick-access feature grid
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final now = DateTime.now();
    final greeting = _greeting(now.hour);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, right: 20, bottom: 14),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                        Text(
                          'القرآن الكريم',
                          style: AppTextStyles.arabicHeadline.copyWith(
                            color: AppColors.primary,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                tooltip: 'بحث',
                onPressed: () => context.pushNamed(RouteNames.search),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'الإعدادات',
                onPressed: () => context.pushNamed(RouteNames.settings),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Content ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),

                // Daily Ayah
                const DailyAyahCard(),

                // Prayer Countdown
                const PrayerCountdownWidget(),

                // Last Read
                const LastReadCard(),

                const SizedBox(height: 20),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'الوصول السريع',
                        style: AppTextStyles.arabicBody.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontSize: 16,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                _QuickAccessGrid(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
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

// ── Quick Access Grid ─────────────────────────────────────────────────────────

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
          childAspectRatio: 0.85,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return _QuickAccessTile(item: _items[index]);
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

    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.pushNamed(item.route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.dividerDark
                  : AppColors.dividerLight,
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: AppTextStyles.arabicCaption.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
