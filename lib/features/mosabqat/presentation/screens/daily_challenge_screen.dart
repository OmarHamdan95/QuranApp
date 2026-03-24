import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Daily challenge screen - a curated set of 10 questions that refresh daily.
class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تحدي اليوم',
          style: AppTextStyles.arabicHeadline.copyWith(color: AppColors.secondary),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.15),
                      AppColors.secondary.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 48,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'تحدي اليوم',
                style: AppTextStyles.arabicHeadline.copyWith(
                  color: AppColors.secondary,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              Text(
                '١٠ أسئلة جديدة كل يوم\nاختبر معرفتك بالقرآن الكريم',
                style: AppTextStyles.arabicBody.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // TODO: Start daily challenge quiz
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: Text(
                  'ابدأ التحدي',
                  style: AppTextStyles.arabicBody.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'أفضل نتيجة: ٨/١٠',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
