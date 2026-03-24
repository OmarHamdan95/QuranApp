import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/mosabqat_providers.dart';

/// Screen for configuring quiz settings before starting.
class QuizSetupScreen extends ConsumerWidget {
  const QuizSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedDifficulty = ref.watch(selectedDifficultyProvider);
    final selectedCount = ref.watch(selectedQuestionCountProvider);
    final categories = ref.watch(quizCategoryInfoProvider);

    final catInfo = categories.firstWhere(
      (c) => c.category == selectedCategory,
      orElse: () => categories.first,
    );

    final timerSeconds = switch (selectedDifficulty) {
      QuizDifficulty.easy => 20,
      QuizDifficulty.medium => 15,
      QuizDifficulty.hard || QuizDifficulty.expert => 10,
    };

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
            // ── Category Selection ──
            _SectionHeader(title: 'الفئة', isDark: isDark),
            const SizedBox(height: 10),
            ...categories.map((cat) {
              final isSelected = cat.category == selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CategoryOption(
                  info: cat,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () => ref
                      .read(selectedCategoryProvider.notifier)
                      .state = cat.category,
                ),
              );
            }),

            const SizedBox(height: 20),

            // ── Difficulty ──
            _SectionHeader(title: 'مستوى الصعوبة', isDark: isDark),
            const SizedBox(height: 10),
            _DifficultySelector(
              selected: selectedDifficulty,
              timerSeconds: timerSeconds,
              onChanged: (d) =>
                  ref.read(selectedDifficultyProvider.notifier).state = d,
            ),

            const SizedBox(height: 20),

            // ── Question Count ──
            _SectionHeader(title: 'عدد الأسئلة', isDark: isDark),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [5, 10, 15, 20].map((count) {
                final isSelected = selectedCount == count;
                return _CountChip(
                  count: count,
                  isSelected: isSelected,
                  onTap: () => ref
                      .read(selectedQuestionCountProvider.notifier)
                      .state = count,
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Summary Card ──
            _SummaryCard(
              catInfo: catInfo,
              difficulty: selectedDifficulty,
              count: selectedCount,
              timerSeconds: timerSeconds,
              isDark: isDark,
            ),

            const SizedBox(height: 28),

            // ── Start Button ──
            ElevatedButton(
              onPressed: () {
                ref.read(quizSessionProvider.notifier).startQuiz(
                      category: selectedCategory,
                      difficulty: selectedDifficulty,
                      questionCount: selectedCount,
                    );
                context.pushNamed(RouteNames.quizPlay);
              },
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

// ─────────────────────────────────────────────
// Category Option
// ─────────────────────────────────────────────

class _CategoryOption extends StatelessWidget {
  final dynamic info;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryOption({
    required this.info,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = info.color as Color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            if (isSelected)
              Icon(Icons.radio_button_checked, color: color, size: 20)
            else
              Icon(Icons.radio_button_unchecked,
                  color: AppColors.textTertiaryLight, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    info.titleAr as String,
                    style: AppTextStyles.arabicBody.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? color
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  Text(
                    info.descriptionAr as String,
                    style: AppTextStyles.arabicCaption.copyWith(
                      color: AppColors.textTertiaryLight,
                      fontSize: 12,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(info.icon as IconData, color: color, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Difficulty Selector
// ─────────────────────────────────────────────

class _DifficultySelector extends StatelessWidget {
  final QuizDifficulty selected;
  final int timerSeconds;
  final ValueChanged<QuizDifficulty> onChanged;

  const _DifficultySelector({
    required this.selected,
    required this.timerSeconds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        diff: QuizDifficulty.easy,
        label: 'سهل',
        color: AppColors.success,
        icon: Icons.sentiment_satisfied_alt,
        timer: 20,
      ),
      (
        diff: QuizDifficulty.medium,
        label: 'متوسط',
        color: AppColors.info,
        icon: Icons.sentiment_neutral,
        timer: 15,
      ),
      (
        diff: QuizDifficulty.hard,
        label: 'صعب',
        color: AppColors.warning,
        icon: Icons.sentiment_dissatisfied,
        timer: 10,
      ),
      (
        diff: QuizDifficulty.expert,
        label: 'خبير',
        color: AppColors.error,
        icon: Icons.whatshot_rounded,
        timer: 10,
      ),
    ];

    return Row(
      children: items.map((item) {
        final isSelected = selected == item.diff;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: GestureDetector(
              onTap: () => onChanged(item.diff),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? item.color
                      : item.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item.color,
                    width: isSelected ? 0 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected ? Colors.white : item.color,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: AppTextStyles.arabicCaption.copyWith(
                        color: isSelected ? Colors.white : item.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      '${item.timer}ث',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSelected
                            ? Colors.white70
                            : item.color.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Count Chip
// ─────────────────────────────────────────────

class _CountChip extends StatelessWidget {
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CountChip({
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.dividerLight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$count',
          style: AppTextStyles.headlineSmall.copyWith(
            color:
                isSelected ? Colors.white : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Summary Card
// ─────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final dynamic catInfo;
  final QuizDifficulty difficulty;
  final int count;
  final int timerSeconds;
  final bool isDark;

  const _SummaryCard({
    required this.catInfo,
    required this.difficulty,
    required this.count,
    required this.timerSeconds,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final diffLabel = switch (difficulty) {
      QuizDifficulty.easy => 'سهل',
      QuizDifficulty.medium => 'متوسط',
      QuizDifficulty.hard => 'صعب',
      QuizDifficulty.expert => 'خبير',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'ملخص المسابقة',
            style: AppTextStyles.arabicBody.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
            textDirection: TextDirection.rtl,
          ),
          const Divider(height: 16, color: AppColors.dividerLight),
          _SummaryRow(label: 'الفئة', value: catInfo.titleAr as String),
          _SummaryRow(label: 'الصعوبة', value: diffLabel),
          _SummaryRow(label: 'عدد الأسئلة', value: '$count سؤال'),
          _SummaryRow(
            label: 'الوقت لكل سؤال',
            value: '$timerSeconds ثانية',
          ),
          _SummaryRow(
            label: 'الوقت الكلي',
            value:
                '${(count * timerSeconds / 60).toStringAsFixed(1)} دقيقة تقريبًا',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: AppTextStyles.arabicCaption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),
          Text(
            label,
            style: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

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
