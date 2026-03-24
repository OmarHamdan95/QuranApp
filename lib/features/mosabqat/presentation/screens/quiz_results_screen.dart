import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Screen showing quiz results after completion.
class QuizResultsScreen extends ConsumerWidget {
  final int score;
  final int total;

  const QuizResultsScreen({
    super.key,
    required this.score,
    required this.total,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percentage = total > 0 ? (score / total * 100).round() : 0;
    final isDark = context.isDarkMode;

    final (icon, message, color) = switch (percentage) {
      >= 90 => (Icons.emoji_events, 'ممتاز! ما شاء الله', AppColors.secondary),
      >= 70 => (Icons.star, 'أحسنت! نتيجة جيدة جداً', AppColors.primary),
      >= 50 => (Icons.thumb_up, 'جيد، استمر في التعلم', AppColors.info),
      _ => (Icons.refresh, 'لا بأس، حاول مرة أخرى', AppColors.warning),
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Result icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 56, color: color),
              ),
              const SizedBox(height: 24),

              // Score
              Text(
                '$score / $total',
                style: AppTextStyles.displayLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 48,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$percentage%',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                message,
                style: AppTextStyles.arabicHeadline.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'أجبت على $score من $total سؤال بشكل صحيح',
                style: AppTextStyles.arabicBody.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.goNamed(RouteNames.quizSetup);
                  },
                  child: Text(
                    'مسابقة جديدة',
                    style: AppTextStyles.arabicBody.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.goNamed(RouteNames.mosabqatHome);
                  },
                  child: Text(
                    'العودة للمسابقات',
                    style: AppTextStyles.arabicBody.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // TODO: Share results
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.share, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'مشاركة النتيجة',
                      style: AppTextStyles.arabicCaption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
