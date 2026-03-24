import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Active quiz gameplay screen with timer, questions, and answer selection.
class QuizPlayScreen extends ConsumerStatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen> {
  int _currentQuestion = 0;
  int _score = 0;
  int _timeRemaining = AppConstants.quizTimePerQuestionSeconds;
  Timer? _timer;
  int? _selectedAnswer;
  bool _answered = false;

  // Placeholder questions. In production, loaded from quiz bank DB.
  static const _questions = [
    _QuizQuestion(
      text: 'أكمل الآية: "ٱلْحَمْدُ لِلَّهِ رَبِّ ..."',
      options: ['ٱلْعَـٰلَمِينَ', 'ٱلنَّاسِ', 'ٱلْمُؤْمِنِينَ', 'ٱلْمُسْلِمِينَ'],
      correctIndex: 0,
      reference: 'الفاتحة : ٢',
    ),
    _QuizQuestion(
      text: 'من أي سورة هذه الآية: "ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ"؟',
      options: ['آل عمران', 'البقرة', 'النساء', 'المائدة'],
      correctIndex: 1,
      reference: 'البقرة : ٢٥٥',
    ),
    _QuizQuestion(
      text: 'كم عدد آيات سورة الفاتحة؟',
      options: ['٥', '٦', '٧', '٨'],
      correctIndex: 2,
      reference: 'الفاتحة',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeRemaining = AppConstants.quizTimePerQuestionSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining <= 0) {
        timer.cancel();
        _handleTimeout();
      } else {
        setState(() => _timeRemaining--);
      }
    });
  }

  void _handleTimeout() {
    if (!_answered) {
      setState(() {
        _answered = true;
        _selectedAnswer = -1; // no answer
      });
      _proceedAfterDelay();
    }
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    _timer?.cancel();

    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == _questions[_currentQuestion].correctIndex) {
        _score++;
      }
    });

    _proceedAfterDelay();
  }

  void _proceedAfterDelay() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_currentQuestion + 1 >= _questions.length) {
        // Quiz finished
        context.pushReplacementNamed(
          RouteNames.quizResults,
          queryParameters: {
            'score': _score.toString(),
            'total': _questions.length.toString(),
          },
        );
      } else {
        setState(() {
          _currentQuestion++;
          _answered = false;
          _selectedAnswer = null;
        });
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestion];
    final isDark = context.isDarkMode;
    final timerProgress = _timeRemaining / AppConstants.quizTimePerQuestionSeconds;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_currentQuestion + 1} / ${_questions.length}',
          style: AppTextStyles.titleMedium,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(
              child: Text(
                'النقاط: $_score',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timer bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: timerProgress,
                backgroundColor: AppColors.dividerLight,
                valueColor: AlwaysStoppedAnimation(
                  _timeRemaining <= 5 ? AppColors.error : AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_timeRemaining}s',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _timeRemaining <= 5
                        ? AppColors.error
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Question
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.quranPageBackgroundDark
                    : AppColors.quranPageBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                question.text,
                style: AppTextStyles.arabicBody.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),

            const SizedBox(height: 24),

            // Answer options
            ...List.generate(question.options.length, (index) {
              final isSelected = _selectedAnswer == index;
              final isCorrect = index == question.correctIndex;
              final showCorrect = _answered && isCorrect;
              final showWrong = _answered && isSelected && !isCorrect;

              Color borderColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;
              Color bgColor = isDark ? AppColors.cardDark : AppColors.cardLight;

              if (showCorrect) {
                borderColor = AppColors.success;
                bgColor = AppColors.success.withValues(alpha: 0.1);
              } else if (showWrong) {
                borderColor = AppColors.error;
                bgColor = AppColors.error.withValues(alpha: 0.1);
              } else if (isSelected) {
                borderColor = AppColors.primary;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: _answered ? null : () => _selectAnswer(index),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: borderColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: _answered
                              ? Icon(
                                  showCorrect
                                      ? Icons.check
                                      : (showWrong ? Icons.close : null),
                                  size: 18,
                                  color: showCorrect ? AppColors.success : AppColors.error,
                                )
                              : Text(
                                  String.fromCharCode(65 + index), // A, B, C, D
                                  style: AppTextStyles.labelLarge,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            question.options[index],
                            style: AppTextStyles.arabicBody.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            if (_answered) ...[
              const SizedBox(height: 8),
              Text(
                question.reference,
                style: AppTextStyles.arabicCaption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuizQuestion {
  final String text;
  final List<String> options;
  final int correctIndex;
  final String reference;

  const _QuizQuestion({
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.reference,
  });
}
