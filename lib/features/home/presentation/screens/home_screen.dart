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
/// Shows daily ayah, last reading position, prayer countdown,
/// and quick-access grid for all features.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            snap: true,
            title: Text(
              'القرآن الكريم',
              style: AppTextStyles.arabicHeadline.copyWith(
                color: AppColors.primary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => context.pushNamed(RouteNames.search),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.pushNamed(RouteNames.settings),
              ),
            ],
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // Daily Ayah
                const DailyAyahCard(),
                const SizedBox(height: 4),

                // Prayer Countdown
                const PrayerCountdownWidget(),
                const SizedBox(height: 4),

                // Last Read
                const LastReadCard(),
                const SizedBox(height: 16),

                // Quick Actions Section Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'الوصول السريع',
                    style: AppTextStyles.arabicBody.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Access Grid
                _QuickAccessGrid(),

                const SizedBox(height: 100), // Bottom nav padding
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final _items = const <_QuickAccessItem>[
    _QuickAccessItem(
      icon: Icons.menu_book,
      label: 'القرآن',
      route: RouteNames.surahIndex,
      color: AppColors.primary,
    ),
    _QuickAccessItem(
      icon: Icons.headphones,
      label: 'الاستماع',
      route: RouteNames.audioPlayer,
      color: AppColors.tertiary,
    ),
    _QuickAccessItem(
      icon: Icons.mosque,
      label: 'الصلاة',
      route: RouteNames.prayerTimes,
      color: AppColors.fajr,
    ),
    _QuickAccessItem(
      icon: Icons.explore,
      label: 'القبلة',
      route: RouteNames.qibla,
      color: AppColors.maghrib,
    ),
    _QuickAccessItem(
      icon: Icons.school,
      label: 'الحفظ',
      route: RouteNames.hifzDashboard,
      color: AppColors.secondary,
    ),
    _QuickAccessItem(
      icon: Icons.quiz,
      label: 'مسابقات',
      route: RouteNames.mosabqatHome,
      color: AppColors.info,
    ),
    _QuickAccessItem(
      icon: Icons.bookmark,
      label: 'الإشارات',
      route: RouteNames.bookmarks,
      color: AppColors.error,
    ),
    _QuickAccessItem(
      icon: Icons.download,
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
          final item = _items[index];
          return _QuickAccessTile(item: item);
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

    return InkWell(
      onTap: () => context.pushNamed(item.route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
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
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: AppTextStyles.arabicCaption.copyWith(
                fontWeight: FontWeight.w600,
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
    );
  }
}
