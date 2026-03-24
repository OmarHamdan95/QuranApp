import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/mosabqat_providers.dart';

/// Daily challenge screen - a curated set of 10 mixed questions that refresh daily.
/// Includes streak bonus tracking and completion state.
class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final stats = ref.watch(mosabqatStatsProvider);
    final isCompleted = ref.watch(dailyChallengeCompletedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تحدي اليوم',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.secondary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Banner ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.secondary, AppColors.secondaryDark],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (isCompleted)
                    const Icon(Icons.check_circle_rounded,
                        size: 64, color: Colors.white)
                  else
                    const Icon(Icons.emoji_events,
                        size: 64, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    isCompleted
                        ? 'أتممت تحدي اليوم! 🎉'
                        : 'تحدي اليوم',
                    style: AppTextStyles.arabicHeadline.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCompleted
                        ? 'ارجع غداً للتحدي الجديد'
                        : '١٠ أسئلة متنوعة — هل يمكنك الإجابة عليها جميعاً؟',
                    style: AppTextStyles.arabicBody.copyWith(
                      color: Colors.white70,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Streak Section ──
            _StreakCard(
              streak: stats.currentStreak,
              bestStreak: stats.bestStreak,
              dailyCompleted: stats.dailyChallengesCompleted,
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // ── Challenge Details ──
            _ChallengeDetailsCard(isDark: isDark),
            const SizedBox(height: 20),

            // ── Streak Bonus Info ──
            _StreakBonusCard(streak: stats.currentStreak, isDark: isDark),
            const SizedBox(height: 28),

            // ── Start / Completed Button ──
            if (!isCompleted)
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(quizSessionProvider.notifier)
                      .startDailyChallenge();
                  context.pushNamed(RouteNames.quizPlay);
                },
                icon: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 26),
                label: Text(
                  'ابدأ التحدي',
                  style: AppTextStyles.arabicBody.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_forward_ios,
                    color: AppColors.secondary, size: 18),
                label: Text(
                  'عد غداً للتحدي الجديد',
                  style: AppTextStyles.arabicBody.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.secondary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),

            SizedBox(height: context.bottomPadding + 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Streak Card
// ─────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int streak;
  final int bestStreak;
  final int dailyCompleted;
  final bool isDark;

  const _StreakCard({
    required this.streak,
    required this.bestStreak,
    required this.dailyCompleted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StreakStat(
            icon: Icons.local_fire_department,
            iconColor: AppColors.warning,
            value: '$streak',
            label: 'السلسلة الحالية',
          ),
          Container(
            width: 1,
            height: 48,
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          _StreakStat(
            icon: Icons.emoji_events,
            iconColor: AppColors.secondary,
            value: '$bestStreak',
            label: 'أفضل سلسلة',
          ),
          Container(
            width: 1,
            height: 48,
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          _StreakStat(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.success,
            value: '$dailyCompleted',
            label: 'مكتمل',
          ),
        ],
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StreakStat({
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
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: iconColor,
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
// Challenge Details Card
// ─────────────────────────────────────────────

class _ChallengeDetailsCard extends StatelessWidget {
  final bool isDark;

  const _ChallengeDetailsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final details = [
      (
        icon: Icons.quiz_rounded,
        label: '${AppConstants.dailyChallengeQuestionCount} أسئلة متنوعة',
        color: AppColors.primary
      ),
      (
        icon: Icons.category_rounded,
        label: 'جميع الفئات مجتمعة',
        color: AppColors.info
      ),
      (
        icon: Icons.timer_rounded,
        label: '١٥ ثانية لكل سؤال',
        color: AppColors.warning
      ),
      (
        icon: Icons.star_rounded,
        label: 'مكافأة سلسلة إضافية',
        color: AppColors.secondary
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'تفاصيل التحدي',
            style: AppTextStyles.arabicBody.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          ...details.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      d.label,
                      style: AppTextStyles.arabicCaption.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: d.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(d.icon, color: d.color, size: 18),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Streak Bonus Card
// ─────────────────────────────────────────────

class _StreakBonusCard extends StatelessWidget {
  final int streak;
  final bool isDark;

  const _StreakBonusCard({required this.streak, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final nextMilestone = streak < 3
        ? 3
        : streak < 7
            ? 7
            : streak < 14
                ? 14
                : streak < 30
                    ? 30
                    : 60;
    final progress = streak / nextMilestone;
    final bonusXP = nextMilestone == 3
        ? 30
        : nextMilestone == 7
            ? 70
            : nextMilestone == 14
                ? 150
                : nextMilestone == 30
                    ? 350
                    : 750;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+ $bonusXP XP',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'مكافأة السلسلة',
                style: AppTextStyles.arabicBody.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'أكمل $nextMilestone يومًا متتاليًا للحصول على $bonusXP نقطة XP إضافية',
            style: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.secondary.withValues(alpha: 0.8),
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
