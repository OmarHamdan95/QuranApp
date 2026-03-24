import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/mosabqat_providers.dart';

/// Active quiz gameplay screen with gamified modern design.
/// Features: animated circular countdown, tappable answer cards with
/// selection animation, progress indicator, score counter.
class QuizPlayScreen extends ConsumerStatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen>
    with TickerProviderStateMixin {
  int? _selectedAnswer;
  bool _answered = false;
  int _timeRemaining = 0;
  int _maxTime = 0;
  int _questionStartTime = 0;
  Timer? _timer;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;
  late AnimationController _timerAnimController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    );
    _timerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startQuestion();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackController.dispose();
    _timerAnimController.dispose();
    super.dispose();
  }

  int _getTimerForDifficulty(QuizDifficulty diff) {
    return switch (diff) {
      QuizDifficulty.easy => 20,
      QuizDifficulty.medium => 15,
      QuizDifficulty.hard || QuizDifficulty.expert => 10,
    };
  }

  void _startQuestion() {
    final session = ref.read(quizSessionProvider);
    if (session == null) return;

    final t = _getTimerForDifficulty(session.difficulty);
    setState(() {
      _maxTime = t;
      _timeRemaining = t;
      _answered = false;
      _selectedAnswer = null;
      _questionStartTime = DateTime.now().millisecondsSinceEpoch;
    });
    _feedbackController.reset();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timeRemaining <= 0) {
        _timer?.cancel();
        _handleTimeout();
      } else {
        setState(() => _timeRemaining--);
      }
    });
  }

  void _handleTimeout() {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedAnswer = -1;
    });
    final timeTaken = (_maxTime * 1000 -
            (DateTime.now().millisecondsSinceEpoch - _questionStartTime))
        .clamp(0, _maxTime * 1000) ~/
        1000;
    ref.read(quizSessionProvider.notifier).answerQuestion(-1, timeTaken);
    _feedbackController.forward();
    _proceedAfterDelay();
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    _timer?.cancel();

    final timeTaken =
        (DateTime.now().millisecondsSinceEpoch - _questionStartTime) ~/
            1000;

    setState(() {
      _selectedAnswer = index;
      _answered = true;
    });

    ref.read(quizSessionProvider.notifier).answerQuestion(index, timeTaken);
    _feedbackController.forward();
    _proceedAfterDelay();
  }

  void _proceedAfterDelay() {
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      final session = ref.read(quizSessionProvider);
      if (session == null) return;

      if (session.isFinished) {
        final result =
            ref.read(quizSessionProvider.notifier).buildResult();
        if (result != null) {
          ref.read(mosabqatStatsProvider.notifier).recordResult(result);
          ref.read(lastQuizResultProvider.notifier).state = result;
        }
        context.pushReplacementNamed(
          RouteNames.quizResults,
          queryParameters: {
            'score': session.score.toString(),
            'total': session.questions.length.toString(),
          },
        );
      } else {
        _startQuestion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(quizSessionProvider);

    if (session == null || session.currentQuestion == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = session.currentQuestion!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timerFraction =
        _maxTime > 0 ? _timeRemaining / _maxTime : 0.0;
    final timerColor = timerFraction > 0.5
        ? AppColors.success
        : timerFraction > 0.25
            ? AppColors.warning
            : AppColors.error;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          onPressed: () {
            _timer?.cancel();
            ref.read(quizSessionProvider.notifier).reset();
            context.pop();
          },
        ),
        title: _ProgressBar(
          current: session.currentIndex,
          total: session.questions.length,
          isDark: isDark,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.15),
                      AppColors.secondary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${session.score}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded,
                        color: AppColors.secondary, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Timer ──
            Center(
              child: _CircularTimer(
                fraction: timerFraction.clamp(0.0, 1.0),
                seconds: _timeRemaining,
                color: timerColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 20),

            // ── Question card ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.quranPageBackgroundDark
                    : AppColors.quranPageBackground,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'السؤال ${session.currentIndex + 1}',
                      style: AppTextStyles.arabicCaption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    question.questionText,
                    style: AppTextStyles.arabicBody.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.8,
                      color: isDark
                          ? AppColors.quranTextColorDark
                          : AppColors.quranTextColor,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Answer options ──
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: question.options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _AnswerCard(
                    index: index,
                    text: question.options[index],
                    isSelected: _selectedAnswer == index,
                    isCorrect:
                        _answered && index == question.correctIndex,
                    isWrong: _answered &&
                        _selectedAnswer == index &&
                        index != question.correctIndex,
                    isAnswered: _answered,
                    isDark: isDark,
                    feedbackAnimation: _feedbackAnimation,
                    onTap: () => _selectAnswer(index),
                  );
                },
              ),
            ),

            // ── Reference (shown after answer) ──
            if (_answered) ...[
              const SizedBox(height: 8),
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        question.reference,
                        style: AppTextStyles.arabicCaption.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      if (question.explanation != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          question.explanation!,
                          style: AppTextStyles.arabicCaption.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Progress Bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final bool isDark;

  const _ProgressBar({
    required this.current,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${current + 1}/$total',
          style: AppTextStyles.labelSmall.copyWith(
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (current + 1) / total,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Circular Timer ───────────────────────────────────────────────────────────

class _CircularTimer extends StatelessWidget {
  final double fraction;
  final int seconds;
  final Color color;
  final bool isDark;

  const _CircularTimer({
    required this.fraction,
    required this.seconds,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.06),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(80, 80),
            painter: _TimerPainter(
              fraction: fraction,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$seconds',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                ),
              ),
              Text(
                'ثانية',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: color.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color backgroundColor;

  _TimerPainter({
    required this.fraction,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const strokeWidth = 5.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_TimerPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}

// ── Answer Card ──────────────────────────────────────────────────────────────

class _AnswerCard extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool isAnswered;
  final bool isDark;
  final Animation<double> feedbackAnimation;
  final VoidCallback onTap;

  const _AnswerCard({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.isAnswered,
    required this.isDark,
    required this.feedbackAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;
    Color textColor;
    Color labelBgColor;
    Widget? trailingIcon;

    if (isCorrect) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withValues(alpha: 0.08);
      textColor = AppColors.success;
      labelBgColor = AppColors.success.withValues(alpha: 0.15);
      trailingIcon = ScaleTransition(
        scale: feedbackAnimation,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.check_rounded,
              color: AppColors.success, size: 18),
        ),
      );
    } else if (isWrong) {
      borderColor = AppColors.error;
      bgColor = AppColors.error.withValues(alpha: 0.06);
      textColor = AppColors.error;
      labelBgColor = AppColors.error.withValues(alpha: 0.15);
      trailingIcon = ScaleTransition(
        scale: feedbackAnimation,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.close_rounded,
              color: AppColors.error, size: 18),
        ),
      );
    } else {
      borderColor =
          isDark ? AppColors.dividerDark : AppColors.dividerLight;
      bgColor = isDark ? AppColors.cardDark : AppColors.cardLight;
      textColor = isDark
          ? AppColors.textPrimaryDark
          : AppColors.textPrimaryLight;
      labelBgColor = isDark
          ? AppColors.surfaceVariantDark
          : AppColors.surfaceVariantLight;
    }

    // Arabic letter labels
    const labels = ['أ', 'ب', 'ج', 'د'];
    final label = index < labels.length ? labels[index] : '${index + 1}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAnswered ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: borderColor,
                width: isCorrect || isWrong ? 2 : 1),
            boxShadow: isSelected && !isAnswered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Answer label
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: labelBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: AppTextStyles.arabicBody.copyWith(
                    color: isCorrect || isWrong
                        ? (isCorrect ? AppColors.success : AppColors.error)
                        : isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(width: 14),

              // Answer text
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.arabicBody.copyWith(
                    color: textColor,
                    fontWeight: isCorrect || isWrong
                        ? FontWeight.w700
                        : FontWeight.w400,
                    height: 1.5,
                    fontSize: 16,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),

              // Trailing icon
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                trailingIcon,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
