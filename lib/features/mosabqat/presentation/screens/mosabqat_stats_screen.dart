import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/mosabqat_providers.dart';

/// Statistics screen showing the user's quiz performance history,
/// category breakdown, badges, and level progression.
class MosabqatStatsScreen extends ConsumerWidget {
  const MosabqatStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(mosabqatStatsProvider);
    final categories = ref.watch(quizCategoryInfoProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إحصائيات المسابقات',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Level & XP ──
            _LevelCard(stats: stats, isDark: isDark),
            const SizedBox(height: 16),

            // ── Overall Performance ──
            _PerformanceCard(stats: stats),
            const SizedBox(height: 16),

            // ── Stats Grid ──
            _StatsGrid(stats: stats, isDark: isDark),
            const SizedBox(height: 20),

            // ── Category Breakdown ──
            _SectionTitle(title: 'الأداء حسب الفئة', isDark: isDark),
            const SizedBox(height: 10),
            ...categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CategoryBar(
                    title: cat.titleAr,
                    percentage: cat.accuracyPercent.round(),
                    color: cat.color,
                    isDark: isDark,
                  ),
                )),

            const SizedBox(height: 20),

            // ── Strongest / Weakest ──
            _StrengthsCard(
              categories: categories,
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // ── Badges Grid ──
            _SectionTitle(title: 'الشارات', isDark: isDark),
            const SizedBox(height: 10),
            _BadgesGrid(stats: stats, isDark: isDark),
            const SizedBox(height: 20),

            // ── Level Progression ──
            _SectionTitle(title: 'مسار المستويات', isDark: isDark),
            const SizedBox(height: 10),
            _LevelProgressionRow(currentXP: stats.totalXP, isDark: isDark),

            SizedBox(height: context.bottomPadding + 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Level Card
// ─────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  final MosabqatStats stats;
  final bool isDark;

  const _LevelCard({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final nextLevelXP = _nextLevelXP(stats.totalXP);
    final currentLevelXP = _currentLevelXP(stats.totalXP);
    final progress = nextLevelXP > currentLevelXP
        ? (stats.totalXP - currentLevelXP) / (nextLevelXP - currentLevelXP)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // XP badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${stats.totalXP} XP',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded,
                        color: AppColors.secondaryLight, size: 16),
                  ],
                ),
              ),
              // Level title
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stats.levelTitle,
                    style: AppTextStyles.arabicHeadline.copyWith(
                      color: Colors.white,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  Text(
                    'المستوى الحالي',
                    style: AppTextStyles.arabicCaption
                        .copyWith(color: Colors.white70),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.secondaryLight),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$nextLevelXP XP',
                style: AppTextStyles.labelSmall
                    .copyWith(color: Colors.white60),
              ),
              Text(
                '$currentLevelXP XP',
                style: AppTextStyles.labelSmall
                    .copyWith(color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _currentLevelXP(int xp) {
    if (xp < 500) return 0;
    if (xp < 1500) return 500;
    if (xp < 3000) return 1500;
    if (xp < 6000) return 3000;
    return 6000;
  }

  int _nextLevelXP(int xp) {
    if (xp < 500) return 500;
    if (xp < 1500) return 1500;
    if (xp < 3000) return 3000;
    if (xp < 6000) return 6000;
    return 10000;
  }
}

// ─────────────────────────────────────────────
// Performance Card
// ─────────────────────────────────────────────

class _PerformanceCard extends StatelessWidget {
  final MosabqatStats stats;

  const _PerformanceCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BigStat(
            value: '${stats.accuracy}%',
            label: 'دقة الإجابات',
          ),
          Container(width: 1, height: 48, color: Colors.white24),
          _BigStat(
            value: '${stats.averageScore.round()}%',
            label: 'متوسط النتيجة',
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String value;
  final String label;

  const _BigStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.displayMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.arabicCaption.copyWith(color: Colors.white60),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Stats Grid
// ─────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final MosabqatStats stats;
  final bool isDark;

  const _StatsGrid({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          icon: Icons.quiz_rounded,
          value: '${stats.totalQuizzes}',
          label: 'مسابقة',
          color: AppColors.primary,
          isDark: isDark,
        ),
        _StatCard(
          icon: Icons.check_circle_rounded,
          value: '${stats.totalCorrect}',
          label: 'إجابة صحيحة',
          color: AppColors.success,
          isDark: isDark,
        ),
        _StatCard(
          icon: Icons.local_fire_department,
          value: '${stats.bestStreak}',
          label: 'أطول سلسلة',
          color: AppColors.warning,
          isDark: isDark,
        ),
        _StatCard(
          icon: Icons.emoji_events,
          value: '${stats.dailyChallengesCompleted}',
          label: 'تحدي يومي',
          color: AppColors.secondary,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Category Bar
// ─────────────────────────────────────────────

class _CategoryBar extends StatelessWidget {
  final String title;
  final int percentage;
  final Color color;
  final bool isDark;

  const _CategoryBar({
    required this.title,
    required this.percentage,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Text(
            '$percentage%',
            style: AppTextStyles.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: AppTextStyles.arabicCaption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
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

// ─────────────────────────────────────────────
// Strengths Card
// ─────────────────────────────────────────────

class _StrengthsCard extends StatelessWidget {
  final List categories;
  final bool isDark;

  const _StrengthsCard({required this.categories, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sorted = [...categories]
      ..sort((a, b) => (b.accuracyPercent as double)
          .compareTo(a.accuracyPercent as double));

    if (sorted.isEmpty) return const SizedBox();

    final strongest = sorted.first;
    final weakest = sorted.last;

    return Container(
      padding: const EdgeInsets.all(16),
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
          _StrengthRow(
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
            label: 'الأقوى',
            category: strongest.titleAr as String,
            percentage: (strongest.accuracyPercent as double).round(),
          ),
          const Divider(height: 16),
          _StrengthRow(
            icon: Icons.trending_down_rounded,
            color: AppColors.warning,
            label: 'يحتاج تطوير',
            category: weakest.titleAr as String,
            percentage: (weakest.accuracyPercent as double).round(),
          ),
        ],
      ),
    );
  }
}

class _StrengthRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String category;
  final int percentage;

  const _StrengthRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.category,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$percentage%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: color, size: 18),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              category,
              style: AppTextStyles.arabicCaption.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textDirection: TextDirection.rtl,
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
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Badges Grid
// ─────────────────────────────────────────────

class _BadgesGrid extends StatelessWidget {
  final MosabqatStats stats;
  final bool isDark;

  const _BadgesGrid({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final badges = [
      (
        icon: Icons.local_fire_department,
        color: AppColors.warning,
        label: 'محارب النار',
        desc: 'سلسلة ٣ أيام',
        unlocked: stats.bestStreak >= 3,
      ),
      (
        icon: Icons.emoji_events,
        color: AppColors.secondary,
        label: 'بطل الأسبوع',
        desc: 'سلسلة ٧ أيام',
        unlocked: stats.bestStreak >= 7,
      ),
      (
        icon: Icons.stars,
        color: AppColors.primary,
        label: 'نجم المسابقات',
        desc: '١٠ مسابقات',
        unlocked: stats.totalQuizzes >= 10,
      ),
      (
        icon: Icons.school,
        color: AppColors.info,
        label: 'طالب علم',
        desc: '٥٠٠ XP',
        unlocked: stats.totalXP >= 500,
      ),
      (
        icon: Icons.psychology,
        color: AppColors.tertiary,
        label: 'العارف',
        desc: 'دقة ٨٠%+',
        unlocked: stats.accuracy >= 80,
      ),
      (
        icon: Icons.military_tech,
        color: AppColors.error,
        label: 'خبير القرآن',
        desc: '١٠٠٠ XP',
        unlocked: stats.totalXP >= 1000,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: badges.length,
      itemBuilder: (context, i) {
        final b = badges[i];
        return _BadgeTile(
          icon: b.icon,
          color: b.color,
          label: b.label,
          desc: b.desc,
          unlocked: b.unlocked,
          isDark: isDark,
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String desc;
  final bool unlocked;
  final bool isDark;

  const _BadgeTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.desc,
    required this.unlocked,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: unlocked
            ? color.withValues(alpha: 0.08)
            : (isDark ? AppColors.cardDark : AppColors.cardLight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked
              ? color.withValues(alpha: 0.3)
              : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: unlocked
                      ? color.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(
                icon,
                size: 26,
                color: unlocked ? color : Colors.grey,
              ),
              if (!unlocked)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock,
                        size: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.arabicCaption.copyWith(
              color: unlocked
                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                  : AppColors.textTertiaryLight,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            desc,
            style: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.textTertiaryLight,
              fontSize: 10,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Level Progression Row
// ─────────────────────────────────────────────

class _LevelProgressionRow extends StatelessWidget {
  final int currentXP;
  final bool isDark;

  const _LevelProgressionRow({required this.currentXP, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const levels = [
      (title: 'مبتدئ', xp: 0, color: AppColors.textTertiaryLight),
      (title: 'متعلم', xp: 500, color: AppColors.info),
      (title: 'متقدم', xp: 1500, color: AppColors.primary),
      (title: 'خبير', xp: 3000, color: AppColors.secondary),
      (title: 'عالم', xp: 6000, color: AppColors.warning),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: levels.map((level) {
          final isReached = currentXP >= level.xp;
          final isActive = currentXP >= level.xp &&
              (level == levels.last ||
                  currentXP < levels[levels.indexOf(level) + 1].xp);

          return Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isReached
                        ? level.color
                        : level.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: isActive
                        ? Border.all(color: Colors.white, width: 2.5)
                        : null,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: level.color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.school,
                    size: 18,
                    color: isReached ? Colors.white : level.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  level.title,
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: isReached ? level.color : AppColors.textTertiaryLight,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 11,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${level.xp}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryLight,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.arabicBody.copyWith(
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      textDirection: TextDirection.rtl,
    );
  }
}
