import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Self-test screen for reviewing memorized ayahs.
///
/// Shows the beginning of an ayah and asks the user to recite
/// the continuation, then reveals the full text for self-verification.
class SelfTestScreen extends ConsumerStatefulWidget {
  const SelfTestScreen({super.key});

  @override
  ConsumerState<SelfTestScreen> createState() => _SelfTestScreenState();
}

class _SelfTestScreenState extends ConsumerState<SelfTestScreen> {
  bool _isRevealed = false;
  int _currentIndex = 0;
  int _correctCount = 0;

  // Placeholder test items. In production, these come from the user's
  // memorized ayahs in the database.
  static const _testItems = [
    (
      prompt: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ ﴿١﴾ ...',
      answer: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
      reference: 'الفاتحة : ٢',
    ),
    (
      prompt: 'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ ﴿٣﴾ ...',
      answer: 'مَـٰلِكِ يَوْمِ ٱلدِّينِ',
      reference: 'الفاتحة : ٤',
    ),
    (
      prompt: 'إِيَّاكَ نَعْبُدُ ...',
      answer: 'وَإِيَّاكَ نَسْتَعِينُ',
      reference: 'الفاتحة : ٥',
    ),
  ];

  void _reveal() {
    setState(() => _isRevealed = true);
  }

  void _markCorrect() {
    setState(() {
      _correctCount++;
      _isRevealed = false;
      _currentIndex++;
    });
  }

  void _markIncorrect() {
    setState(() {
      _isRevealed = false;
      _currentIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isFinished = _currentIndex >= _testItems.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'اختبر نفسك',
          style: AppTextStyles.arabicHeadline.copyWith(color: AppColors.primary),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                '${_currentIndex + 1}/${_testItems.length}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isFinished
          ? _ResultsView(
              correct: _correctCount,
              total: _testItems.length,
              onRetry: () {
                setState(() {
                  _currentIndex = 0;
                  _correctCount = 0;
                  _isRevealed = false;
                });
              },
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress
                  LinearProgressIndicator(
                    value: _currentIndex / _testItems.length,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 24),

                  // Prompt
                  Text(
                    'أكمل الآية التالية:',
                    style: AppTextStyles.arabicBody.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.quranPageBackgroundDark
                          : AppColors.quranPageBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _testItems[_currentIndex].prompt,
                      style: AppTextStyles.quranAyah.copyWith(
                        fontSize: 24,
                        color: isDark
                            ? AppColors.quranTextColorDark
                            : AppColors.quranTextColor,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Answer area
                  if (_isRevealed)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _testItems[_currentIndex].answer,
                            style: AppTextStyles.quranAyah.copyWith(
                              fontSize: 24,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _testItems[_currentIndex].reference,
                            style: AppTextStyles.arabicCaption.copyWith(
                              color: AppColors.textTertiaryLight,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // Action buttons
                  if (!_isRevealed)
                    ElevatedButton(
                      onPressed: _reveal,
                      child: Text(
                        'كشف الإجابة',
                        style: AppTextStyles.arabicBody.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _markIncorrect,
                            icon: const Icon(Icons.close, color: AppColors.error),
                            label: Text(
                              'لم أتذكر',
                              style: AppTextStyles.arabicCaption.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _markCorrect,
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: Text(
                              'تذكرت',
                              style: AppTextStyles.arabicCaption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: context.bottomPadding + 16),
                ],
              ),
            ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  final int correct;
  final int total;
  final VoidCallback onRetry;

  const _ResultsView({
    required this.correct,
    required this.total,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (correct / total * 100).round();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              percentage >= 70 ? Icons.emoji_events : Icons.refresh,
              size: 64,
              color: percentage >= 70 ? AppColors.secondary : AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '$percentage%',
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correct من $total إجابة صحيحة',
              style: AppTextStyles.arabicBody.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 24),
            Text(
              percentage >= 70 ? 'أحسنت! استمر في المراجعة' : 'لا بأس، حاول مرة أخرى',
              style: AppTextStyles.arabicBody.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(
                'إعادة الاختبار',
                style: AppTextStyles.arabicBody.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
