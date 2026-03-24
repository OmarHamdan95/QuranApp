import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Screen for configuring quiz settings before starting.
class QuizSetupScreen extends ConsumerStatefulWidget {
  const QuizSetupScreen({super.key});

  @override
  ConsumerState<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends ConsumerState<QuizSetupScreen> {
  int _questionCount = AppConstants.defaultQuizQuestions;
  QuizDifficulty _difficulty = QuizDifficulty.medium;
  Set<int> _selectedSurahs = {}; // empty = all surahs

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إعداد المسابقة',
          style: AppTextStyles.arabicHeadline.copyWith(color: AppColors.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question count
            Text(
              'عدد الأسئلة',
              style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w700),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [5, 10, 15, 20, 30].map((count) {
                final isSelected = _questionCount == count;
                return ChoiceChip(
                  label: Text(
                    '$count',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _questionCount = count),
                  selectedColor: AppColors.primary,
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Difficulty
            Text(
              'مستوى الصعوبة',
              style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w700),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: QuizDifficulty.values.map((difficulty) {
                final isSelected = _difficulty == difficulty;
                final label = switch (difficulty) {
                  QuizDifficulty.easy => 'سهل',
                  QuizDifficulty.medium => 'متوسط',
                  QuizDifficulty.hard => 'صعب',
                  QuizDifficulty.expert => 'خبير',
                };
                final color = switch (difficulty) {
                  QuizDifficulty.easy => AppColors.success,
                  QuizDifficulty.medium => AppColors.info,
                  QuizDifficulty.hard => AppColors.warning,
                  QuizDifficulty.expert => AppColors.error,
                };

                return ChoiceChip(
                  label: Text(
                    label,
                    style: AppTextStyles.arabicCaption.copyWith(
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _difficulty = difficulty),
                  selectedColor: color,
                  avatar: isSelected
                      ? null
                      : CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          radius: 10,
                        ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Surah scope
            Text(
              'نطاق الأسئلة',
              style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w700),
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
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: Text(
                      'القرآن كاملاً',
                      style: AppTextStyles.arabicBody,
                      textDirection: TextDirection.rtl,
                    ),
                    value: true,
                    groupValue: _selectedSurahs.isEmpty,
                    onChanged: (_) => setState(() => _selectedSurahs = {}),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<bool>(
                    title: Text(
                      'سور محددة',
                      style: AppTextStyles.arabicBody,
                      textDirection: TextDirection.rtl,
                    ),
                    value: false,
                    groupValue: _selectedSurahs.isEmpty,
                    onChanged: (_) {
                      // TODO: Show surah selector
                      setState(() => _selectedSurahs = {1, 2, 3});
                    },
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<bool>(
                    title: Text(
                      'الآيات المحفوظة فقط',
                      style: AppTextStyles.arabicBody,
                      textDirection: TextDirection.rtl,
                    ),
                    subtitle: Text(
                      'أسئلة من الأجزاء التي حفظتها',
                      style: AppTextStyles.arabicCaption.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    value: false,
                    groupValue: true,
                    onChanged: (_) {},
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Start button
            ElevatedButton(
              onPressed: () => context.pushNamed(RouteNames.quizPlay),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'ابدأ المسابقة',
                style: AppTextStyles.arabicBody.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),

            SizedBox(height: context.bottomPadding + 16),
          ],
        ),
      ),
    );
  }
}
