import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Provider tracking overall hifz progress (percentage of Quran memorized).
final hifzProgressProvider = StateProvider<double>((ref) => 0.12);

/// Provider tracking daily streak.
final hifzStreakProvider = StateProvider<int>((ref) => 7);

/// Provider tracking total ayahs memorized.
final totalAyahsMemorizedProvider = StateProvider<int>((ref) => 750);

/// Dashboard for the Hifz (memorization) feature.
class HifzDashboardScreen extends ConsumerWidget {
  const HifzDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(hifzProgressProvider);
    final streak = ref.watch(hifzStreakProvider);
    final totalMemorized = ref.watch(totalAyahsMemorizedProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الحفظ',
          style: AppTextStyles.arabicHeadline.copyWith(color: AppColors.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress overview card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    'تقدم الحفظ',
                    style: AppTextStyles.arabicBody.copyWith(
                      color: Colors.white70,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation(AppColors.secondaryLight),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: AppTextStyles.displayMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        value: totalMemorized.toString(),
                        label: 'آية محفوظة',
                      ),
                      _StatItem(
                        value: '$streak',
                        label: 'يوم متتالي',
                      ),
                      _StatItem(
                        value: '${(totalMemorized / 6236 * 30).toStringAsFixed(1)}',
                        label: 'جزء',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            _ActionCard(
              icon: Icons.add_circle_outline,
              title: 'خطة حفظ جديدة',
              subtitle: 'أنشئ خطة مخصصة لحفظ القرآن',
              color: AppColors.primary,
              onTap: () => context.pushNamed(RouteNames.hifzPlanSetup),
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.quiz_outlined,
              title: 'اختبر نفسك',
              subtitle: 'راجع ما حفظته',
              color: AppColors.secondary,
              onTap: () => context.pushNamed(RouteNames.selfTest),
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.emoji_events_outlined,
              title: 'المسابقات',
              subtitle: 'تحدى نفسك في مسابقات قرآنية',
              color: AppColors.info,
              onTap: () => context.pushNamed(RouteNames.mosabqatHome),
            ),

            const SizedBox(height: 20),

            // Today's goal
            Text(
              'هدف اليوم',
              style: AppTextStyles.arabicBody.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حفظ ٥ آيات من سورة البقرة',
                          style: AppTextStyles.arabicBody.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'الآيات ١٥٠-١٥٤',
                          style: AppTextStyles.arabicCaption.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: 0.6,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '٣/٥',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.primary,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.bottomPadding + 80),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.arabicCaption.copyWith(
            color: Colors.white60,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w600),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.arabicCaption.copyWith(
            color: AppColors.textTertiaryLight,
          ),
          textDirection: TextDirection.rtl,
        ),
        trailing: Icon(Icons.chevron_left, color: color),
      ),
    );
  }
}
