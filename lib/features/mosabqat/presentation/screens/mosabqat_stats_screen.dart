import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Providers for quiz statistics.
final totalQuizzesPlayedProvider = StateProvider<int>((ref) => 42);
final totalCorrectAnswersProvider = StateProvider<int>((ref) => 312);
final totalQuestionsAnsweredProvider = StateProvider<int>((ref) => 420);
final bestStreakProvider = StateProvider<int>((ref) => 15);
final averageScoreProvider = StateProvider<double>((ref) => 74.3);
final dailyChallengesCompletedProvider = StateProvider<int>((ref) => 12);

/// Statistics screen showing the user's quiz performance history.
class MosabqatStatsScreen extends ConsumerWidget {
  const MosabqatStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalPlayed = ref.watch(totalQuizzesPlayedProvider);
    final totalCorrect = ref.watch(totalCorrectAnswersProvider);
    final totalQuestions = ref.watch(totalQuestionsAnsweredProvider);
    final bestStreak = ref.watch(bestStreakProvider);
    final avgScore = ref.watch(averageScoreProvider);
    final dailyChallenges = ref.watch(dailyChallengesCompletedProvider);
    final isDark = context.isDarkMode;

    final accuracy = totalQuestions > 0
        ? (totalCorrect / totalQuestions * 100).round()
        : 0;

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
            // Overall score card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    'الأداء العام',
                    style: AppTextStyles.arabicBody.copyWith(
                      color: Colors.white70,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _BigStat(
                        value: '$accuracy%',
                        label: 'دقة الإجابات',
                      ),
                      Container(
                        width: 1,
                        height: 48,
                        color: Colors.white24,
                      ),
                      _BigStat(
                        value: '${avgScore.round()}%',
                        label: 'متوسط النتيجة',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.quiz,
                    value: '$totalPlayed',
                    label: 'مسابقة',
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle,
                    value: '$totalCorrect',
                    label: 'إجابة صحيحة',
                    color: AppColors.success,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department,
                    value: '$bestStreak',
                    label: 'أفضل سلسلة',
                    color: AppColors.secondary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.emoji_events,
                    value: '$dailyChallenges',
                    label: 'تحدي يومي',
                    color: AppColors.info,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Category breakdown
            Text(
              'الأداء حسب الفئة',
              style: AppTextStyles.arabicBody.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),

            _CategoryProgress(
              title: 'أكمل الآية',
              percentage: 85,
              color: AppColors.primary,
              isDark: isDark,
            ),
            _CategoryProgress(
              title: 'تعرف على السورة',
              percentage: 72,
              color: AppColors.info,
              isDark: isDark,
            ),
            _CategoryProgress(
              title: 'ترتيب الآيات',
              percentage: 65,
              color: AppColors.tertiary,
              isDark: isDark,
            ),
            _CategoryProgress(
              title: 'معاني الكلمات',
              percentage: 58,
              color: AppColors.secondary,
              isDark: isDark,
            ),
            _CategoryProgress(
              title: 'معلومات عامة',
              percentage: 80,
              color: AppColors.maghrib,
              isDark: isDark,
            ),

            SizedBox(height: context.bottomPadding + 16),
          ],
        ),
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
          style: AppTextStyles.arabicCaption.copyWith(
            color: Colors.white60,
          ),
          textDirection: TextDirection.rtl,
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
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

class _CategoryProgress extends StatelessWidget {
  final String title;
  final int percentage;
  final Color color;
  final bool isDark;

  const _CategoryProgress({
    required this.title,
    required this.percentage,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(width: 12),
            Text(
              '$percentage%',
              style: AppTextStyles.labelLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
