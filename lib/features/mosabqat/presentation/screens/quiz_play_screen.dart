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

/// Active quiz gameplay screen.
/// Features: animated circular countdown timer, 4-option MCQ,
/// correct/incorrect feedback, progress bar, score counter.
class QuizPlayScreen extends ConsumerStatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedAnswer;
  bool _answered = false;
  int _timeRemaining = 0;
  int _maxTime = 0;
  int _questionStartTime = 0;
  Timer? _timer;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startQuestion();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackController.dispose();
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
        (DateTime.now().millisecondsSinceEpoch - _questionStartTime) ~/ 1000;

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
        final result = ref.read(quizSessionProvider.notifier).buildResult();
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
    final timerFraction = _maxTime > 0 ? _timeRemaining / _maxTime : 0.0;
    final timerColor = timerFraction > 0.5
        ? AppColors.success
        : timerFraction > 0.25
            ? AppColors.warning
            : AppColors.error;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _timer?.cancel();
            ref.read(quizSessionProvider.notifier).reset();
            context.pop();
          },
        ),
        title: _ProgressIndicatorBar(
          current: session.currentIndex,
          total: session.questions.length,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${session.score}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded,
                        color: AppColors.secondary, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              ),
            ),
            const SizedBox(height: 16),

            // ── Question ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.quranPageBackgroundDark
                    : AppColors.quranPageBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
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
            ),
            const SizedBox(height: 20),

            // ── Answers ──
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: question.options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _AnswerOption(
                    index: index,
                    text: question.options[index],
                    isSelected: _selectedAnswer == index,
                    isCorrect: _answered && index == question.correctIndex,
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
                opacity: _answered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Text(
                  question.reference,
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
              if (question.explanation != null)
                AnimatedOpacity(
                  opacity: _answered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      question.explanation!,
                      style: AppTextStyles.arabicCaption.copyWith(
                        color: AppColors.textTertiaryLight,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
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

// ─────────────────────────────────────────────
// Progress Indicator in AppBar
// ─────────────────────────────────────────────

class _ProgressIndicatorBar extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressIndicatorBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${current + 1} / $total',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Circular Timer
// ─────────────────────────────────────────────

class _CircularTimer extends StatelessWidget {
  final double fraction;
  final int seconds;
  final Color color;

  const _CircularTimer({
    required this.fraction,
    required this.seconds,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(72, 72),
            painter: _TimerPainter(
              fraction: fraction,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
          Text(
            '$seconds',
            style: AppTextStyles.headlineMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
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
    final strokeWidth = 5.0;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
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

// ─────────────────────────────────────────────
// Answer Option
// ─────────────────────────────────────────────

class _AnswerOption extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool isAnswered;
  final bool isDark;
  final Animation<double> feedbackAnimation;
  final VoidCallback onTap;

  const _AnswerOption({
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
    Widget? trailingIcon;

    if (isCorrect) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
      trailingIcon = ScaleTransition(
        scale: feedbackAnimation,
        child: const Icon(Icons.check_circle_rounded,
            color: AppColors.success, size: 22),
      );
    } else if (isWrong) {
      borderColor = AppColors.error;
      bgColor = AppColors.error.withValues(alpha: 0.08);
      textColor = AppColors.error;
      trailingIcon = ScaleTransition(
        scale: feedbackAnimation,
        child: const Icon(Icons.cancel_rounded,
            color: AppColors.error, size: 22),
      );
    } else {
      borderColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;
      bgColor = isDark ? AppColors.cardDark : AppColors.cardLight;
      textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    }

    final label = String.fromCharCode(0x0041 + index); // A, B, C, D

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAnswered ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              // Answer label circle
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: borderColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Answer text
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.arabicBody.copyWith(
                    color: textColor,
                    fontWeight:
                        isCorrect || isWrong ? FontWeight.w700 : FontWeight.w400,
                    height: 1.5,
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
