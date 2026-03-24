import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/mosabqat_providers.dart';

/// Daily challenge screen with gamified modern design.
/// Features animated counters, streak displays, gradient hero banner,
/// and tappable challenge cards.
class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final stats = ref.watch(mosabqatStatsProvider);
    final isCompleted = ref.watch(dailyChallengeCompletedProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing hero header ──
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor:
                isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroBanner(
                  isCompleted: isCompleted, isDark: isDark),
            ),
            title: Text(
              'تحدي اليوم',
              style: AppTextStyles.arabicBody.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              textDirection: TextDirection.rtl,
            ),
            centerTitle: true,
          ),

          // ── Content ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Streak stats ──
                _StreakStatsRow(
                  streak: stats.currentStreak,
                  bestStreak: stats.bestStreak,
                  dailyCompleted: stats.dailyChallengesCompleted,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // ── Challenge details ──
                _ChallengeDetailsCard(isDark: isDark),
                const SizedBox(height: 20),

                // ── Streak bonus progress ──
                _StreakBonusCard(
                    streak: stats.currentStreak, isDark: isDark),
                const SizedBox(height: 28),

                // ── Action button ──
                if (!isCompleted)
                  _StartButton(
                    onPressed: () {
                      ref
                          .read(quizSessionProvider.notifier)
                          .startDailyChallenge();
                      context.pushNamed(RouteNames.quizPlay);
                    },
                  )
                else
                  _CompletedButton(
                    onPressed: () => context.pop(),
                  ),

                SizedBox(height: context.bottomPadding + 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final bool isCompleted;
  final bool isDark;

  const _HeroBanner({required this.isCompleted, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.secondary, AppColors.secondaryDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.emoji_events_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isCompleted ? 'أتممت تحدي اليوم!' : 'تحدي اليوم',
                style: AppTextStyles.arabicHeadline.copyWith(
                  color: Colors.white,
                  fontSize: 22,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                isCompleted
                    ? 'ارجع غداً للتحدي الجديد'
                    : '١٠ أسئلة متنوعة — هل يمكنك الإجابة عليها جميعاً؟',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Streak Stats Row ─────────────────────────────────────────────────────────

class _StreakStatsRow extends StatelessWidget {
  final int streak;
  final int bestStreak;
  final int dailyCompleted;
  final bool isDark;

  const _StreakStatsRow({
    required this.streak,
    required this.bestStreak,
    required this.dailyCompleted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.warning,
            value: '$streak',
            label: 'السلسلة الحالية',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events_rounded,
            iconColor: AppColors.secondary,
            value: '$bestStreak',
            label: 'أفضل سلسلة',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.success,
            value: '$dailyCompleted',
            label: 'مكتمل',
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.arabicCaption.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
              fontSize: 11,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Challenge Details Card ───────────────────────────────────────────────────

class _ChallengeDetailsCard extends StatelessWidget {
  final bool isDark;

  const _ChallengeDetailsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final details = [
      (
        icon: Icons.quiz_rounded,
        label: '${AppConstants.dailyChallengeQuestionCount} أسئلة متنوعة',
        color: AppColors.primary,
      ),
      (
        icon: Icons.category_rounded,
        label: 'جميع الفئات مجتمعة',
        color: AppColors.info,
      ),
      (
        icon: Icons.timer_rounded,
        label: '١٥ ثانية لكل سؤال',
        color: AppColors.warning,
      ),
      (
        icon: Icons.star_rounded,
        label: 'مكافأة سلسلة إضافية',
        color: AppColors.secondary,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'تفاصيل التحدي',
            style: AppTextStyles.arabicBody.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 14),
          ...details.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                    const SizedBox(width: 12),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: d.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(d.icon, color: d.color, size: 20),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Streak Bonus Card ────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.secondary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+ $bonusXP XP',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    'مكافأة السلسلة',
                    style: AppTextStyles.arabicBody.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.local_fire_department_rounded,
                      color: AppColors.secondary, size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.secondary,
                        AppColors.secondaryLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'أكمل $nextMilestone يومًا متتاليًا للحصول على $bonusXP نقطة XP إضافية',
            style: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.secondary.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

// ── Buttons ──────────────────────────────────────────────────────────────────

class _StartButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _StartButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.secondary, AppColors.secondaryDark],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ابدأ التحدي',
              style: AppTextStyles.arabicBody.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 26),
          ],
        ),
      ),
    );
  }
}

class _CompletedButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CompletedButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_forward_ios_rounded,
          color: AppColors.secondary, size: 18),
      label: Text(
        'عد غداً للتحدي الجديد',
        style: AppTextStyles.arabicBody.copyWith(
          color: AppColors.secondary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.secondary),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
