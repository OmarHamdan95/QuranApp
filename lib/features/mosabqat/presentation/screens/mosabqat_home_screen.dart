import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/mosabqat_providers.dart';

/// Home screen for the Mosabqat (Quran quizzes) feature.
/// Shows category grid, daily challenge card, streak counter, and stats summary.
class MosabqatHomeScreen extends ConsumerWidget {
  const MosabqatHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final stats = ref.watch(mosabqatStatsProvider);
    final categories = ref.watch(quizCategoryInfoProvider);
    final dailyDone = ref.watch(dailyChallengeCompletedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'المسابقات',
          style: AppTextStyles.arabicHeadline.copyWith(color: AppColors.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'الإحصائيات',
            onPressed: () => context.pushNamed(RouteNames.mosabqatStats),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Stats Summary Bar ──
            _StatsSummaryBar(stats: stats, isDark: isDark),
            const SizedBox(height: 16),

            // ── Daily Challenge Card ──
            _DailyChallengeCard(
              streak: stats.currentStreak,
              isCompleted: dailyDone,
              onTap: () => context.pushNamed(RouteNames.dailyChallenge),
            ),
            const SizedBox(height: 20),

            // ── Categories Grid ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.grid_view_rounded,
                    color: AppColors.textTertiaryLight, size: 18),
                Text(
                  'فئات المسابقات',
                  style: AppTextStyles.arabicBody.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final cat = categories[i];
                return _CategoryCard(
                  info: cat,
                  isDark: isDark,
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).state =
                        cat.category;
                    context.pushNamed(RouteNames.quizSetup);
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // ── Recent Activity Teaser ──
            if (stats.recentResults.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () =>
                        context.pushNamed(RouteNames.mosabqatStats),
                    child: Text(
                      'عرض الكل',
                      style: AppTextStyles.arabicCaption.copyWith(
                        color: AppColors.primary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  Text(
                    'آخر النتائج',
                    style: AppTextStyles.arabicBody.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...stats.recentResults.take(3).map((r) => _RecentResultTile(
                    result: r,
                    isDark: isDark,
                    categories: categories,
                  )),
            ],

            SizedBox(height: context.bottomPadding + 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stats Summary Bar
// ─────────────────────────────────────────────

class _StatsSummaryBar extends StatelessWidget {
  final MosabqatStats stats;
  final bool isDark;

  const _StatsSummaryBar({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MiniStat(
            icon: Icons.emoji_events,
            iconColor: AppColors.secondary,
            value: '${stats.totalXP}',
            label: 'نقطة XP',
          ),
          _VerticalDivider(),
          _MiniStat(
            icon: Icons.local_fire_department,
            iconColor: AppColors.warning,
            value: '${stats.currentStreak}',
            label: 'أيام متتالية',
          ),
          _VerticalDivider(),
          _MiniStat(
            icon: Icons.percent,
            iconColor: AppColors.success,
            value: '${stats.accuracy}%',
            label: 'الدقة',
          ),
          _VerticalDivider(),
          _MiniStat(
            icon: Icons.school,
            iconColor: AppColors.primary,
            value: stats.levelTitle,
            label: 'المستوى',
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.dividerLight);
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.arabicCaption.copyWith(
            color: AppColors.textTertiaryLight,
            fontSize: 11,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Daily Challenge Card
// ─────────────────────────────────────────────

class _DailyChallengeCard extends StatelessWidget {
  final int streak;
  final bool isCompleted;
  final VoidCallback onTap;

  const _DailyChallengeCard({
    required this.streak,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isCompleted
              ? [
                  AppColors.success.withValues(alpha: 0.8),
                  AppColors.success,
                ]
              : [AppColors.secondary, AppColors.secondaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? AppColors.success : AppColors.secondary)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCompleted ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Play/Completed icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'تحدي اليوم',
                        style: AppTextStyles.arabicHeadline.copyWith(
                          color: Colors.white,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCompleted
                            ? 'أتممت تحدي اليوم! أحسنت'
                            : '١٠ أسئلة متنوعة — هل يمكنك إجابتها جميعاً؟',
                        style: AppTextStyles.arabicCaption.copyWith(
                          color: Colors.white70,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      if (streak > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '$streak يوم',
                              style: AppTextStyles.arabicCaption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(width: 4),
                            const Text('🔥', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Category Card
// ─────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final dynamic info;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.info,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = info.color as Color;
    final accuracy = info.accuracyPercent as double;

    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Accuracy badge
                  if (accuracy > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${accuracy.round()}%',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(info.icon as IconData, color: color, size: 22),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                info.titleAr as String,
                style: AppTextStyles.arabicBody.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontSize: 16,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 2),
              Text(
                '${info.totalQuestions} سؤال',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: AppColors.textTertiaryLight,
                  fontSize: 12,
                ),
                textDirection: TextDirection.rtl,
              ),
              if (accuracy > 0) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: accuracy / 100,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Recent Result Tile
// ─────────────────────────────────────────────

class _RecentResultTile extends StatelessWidget {
  final dynamic result;
  final bool isDark;
  final List categories;

  const _RecentResultTile({
    required this.result,
    required this.isDark,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final score = result.score as int;
    final total = result.totalQuestions as int;
    final pct = result.percentage as int;

    final catInfo = categories.firstWhere(
      (c) => c.category == result.category,
      orElse: () => categories.first,
    );

    final color = pct >= 70 ? AppColors.success : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Score
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$pct%',
              style: AppTextStyles.labelLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  catInfo.titleAr as String,
                  style: AppTextStyles.arabicCaption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                Text(
                  '$score / $total إجابة صحيحة',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: AppColors.textTertiaryLight,
                    fontSize: 12,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
