import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/mosabqat_providers.dart';

/// Screen showing quiz results after completion.
/// Features: score display, XP animation, breakdown, share, and play again.
class QuizResultsScreen extends ConsumerStatefulWidget {
  final int score;
  final int total;

  const QuizResultsScreen({
    super.key,
    required this.score,
    required this.total,
  });

  @override
  ConsumerState<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends ConsumerState<QuizResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late AnimationController _xpController;
  late Animation<double> _scoreAnim;
  late Animation<double> _xpScaleAnim;
  late Animation<double> _xpOpacityAnim;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scoreAnim = CurvedAnimation(
      parent: _scoreController,
      curve: Curves.elasticOut,
    );
    _xpScaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _xpController, curve: Curves.bounceOut),
    );
    _xpOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _xpController, curve: Curves.easeIn),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scoreController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _xpController.forward();
    });
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage =
        widget.total > 0 ? (widget.score / widget.total * 100).round() : 0;
    final isDark = context.isDarkMode;
    final result = ref.watch(lastQuizResultProvider);

    final (emoji, message, color) = switch (percentage) {
      >= 90 => ('🌟', 'ممتاز! ما شاء الله', AppColors.secondary),
      >= 70 => ('✨', 'أحسنت! نتيجة جيدة جداً', AppColors.primary),
      >= 50 => ('💪', 'جيد، استمر في التعلم', AppColors.info),
      _ => ('🔄', 'لا بأس، حاول مرة أخرى', AppColors.warning),
    };

    final xp = result?.xpEarned ?? 0;
    final timeTaken = result?.timeTaken;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ── Emoji ──
              Text(emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),

              // ── Animated Score Circle ──
              ScaleTransition(
                scale: _scoreAnim,
                child: _ScoreCircle(
                  score: widget.score,
                  total: widget.total,
                  percentage: percentage,
                  color: color,
                ),
              ),
              const SizedBox(height: 20),

              // ── Message ──
              Text(
                message,
                style: AppTextStyles.arabicHeadline.copyWith(color: color),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'أجبت على ${widget.score} من ${widget.total} سؤال بشكل صحيح',
                style: AppTextStyles.arabicBody.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // ── XP Animation ──
              if (xp > 0)
                FadeTransition(
                  opacity: _xpOpacityAnim,
                  child: ScaleTransition(
                    scale: _xpScaleAnim,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, AppColors.secondaryDark],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+ $xp نقطة XP',
                            style: AppTextStyles.arabicBody.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.emoji_events,
                              color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // ── Stats Breakdown ──
              _BreakdownCard(
                score: widget.score,
                total: widget.total,
                percentage: percentage,
                timeTaken: timeTaken,
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              // ── Action Buttons ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(quizSessionProvider.notifier).reset();
                    context.pushReplacementNamed(RouteNames.quizSetup);
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    'مسابقة جديدة',
                    style: AppTextStyles.arabicBody.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(quizSessionProvider.notifier).reset();
                    context.goNamed(RouteNames.mosabqatHome);
                  },
                  icon: const Icon(Icons.home_outlined, color: AppColors.primary),
                  label: Text(
                    'العودة للمسابقات',
                    style: AppTextStyles.arabicBody.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => _shareResults(context),
                icon: const Icon(Icons.share, size: 18, color: AppColors.primary),
                label: Text(
                  'مشاركة النتيجة',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),

              SizedBox(height: context.bottomPadding + 8),
            ],
          ),
        ),
      ),
    );
  }

  void _shareResults(BuildContext context) {
    final percentage =
        widget.total > 0 ? (widget.score / widget.total * 100).round() : 0;
    context.showSnackBar(
      'حصلت على $percentage% (${widget.score}/${widget.total}) في مسابقة القرآن الكريم 🌟',
      duration: const Duration(seconds: 4),
    );
  }
}

// ─────────────────────────────────────────────
// Score Circle
// ─────────────────────────────────────────────

class _ScoreCircle extends StatelessWidget {
  final int score;
  final int total;
  final int percentage;
  final Color color;

  const _ScoreCircle({
    required this.score,
    required this.total,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score / $total',
            style: AppTextStyles.headlineLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percentage%',
            style: AppTextStyles.headlineSmall.copyWith(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Breakdown Card
// ─────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final int score;
  final int total;
  final int percentage;
  final Duration? timeTaken;
  final bool isDark;

  const _BreakdownCard({
    required this.score,
    required this.total,
    required this.percentage,
    this.timeTaken,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final wrong = total - score;
    final timeStr = timeTaken != null
        ? '${timeTaken!.inMinutes}:${(timeTaken!.inSeconds % 60).toString().padLeft(2, '0')}'
        : '--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BreakdownStat(
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                value: '$score',
                label: 'إجابات صحيحة',
              ),
              Container(
                  width: 1,
                  height: 48,
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight),
              _BreakdownStat(
                icon: Icons.cancel_rounded,
                color: AppColors.error,
                value: '$wrong',
                label: 'إجابات خاطئة',
              ),
              Container(
                  width: 1,
                  height: 48,
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight),
              _BreakdownStat(
                icon: Icons.timer_outlined,
                color: AppColors.info,
                value: timeStr,
                label: 'الوقت',
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor:
                  AppColors.error.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(
                percentage >= 70 ? AppColors.success : AppColors.warning,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'صحيح $score',
                style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success),
              ),
              Text(
                'خاطئ $wrong',
                style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _BreakdownStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.arabicCaption.copyWith(
            color: AppColors.textTertiaryLight,
            fontSize: 11,
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
