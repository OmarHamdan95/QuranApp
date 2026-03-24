import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Home screen for the Mosabqat (Quran quizzes) feature.
class MosabqatHomeScreen extends ConsumerWidget {
  const MosabqatHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'المسابقات',
          style: AppTextStyles.arabicHeadline.copyWith(color: AppColors.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () => context.pushNamed(RouteNames.mosabqatStats),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Daily Challenge Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, AppColors.secondaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                onTap: () => context.pushNamed(RouteNames.dailyChallenge),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تحدي اليوم',
                              style: AppTextStyles.arabicHeadline.copyWith(
                                color: Colors.white,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '١٠ أسئلة - هل يمكنك الإجابة عليها جميعاً؟',
                              style: AppTextStyles.arabicCaption.copyWith(
                                color: Colors.white70,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quiz Categories
            Text(
              'فئات الأسئلة',
              style: AppTextStyles.arabicBody.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),

            _QuizCategoryCard(
              icon: Icons.format_quote,
              title: 'أكمل الآية',
              description: 'اختبر حفظك بإكمال الآيات',
              color: AppColors.primary,
              onTap: () => context.pushNamed(RouteNames.quizSetup),
            ),
            _QuizCategoryCard(
              icon: Icons.menu_book,
              title: 'تعرف على السورة',
              description: 'حدد السورة من الآية المعروضة',
              color: AppColors.info,
              onTap: () => context.pushNamed(RouteNames.quizSetup),
            ),
            _QuizCategoryCard(
              icon: Icons.sort,
              title: 'ترتيب الآيات',
              description: 'رتب الآيات بالترتيب الصحيح',
              color: AppColors.tertiary,
              onTap: () => context.pushNamed(RouteNames.quizSetup),
            ),
            _QuizCategoryCard(
              icon: Icons.translate,
              title: 'معاني الكلمات',
              description: 'تعلم معاني كلمات القرآن',
              color: AppColors.secondary,
              onTap: () => context.pushNamed(RouteNames.quizSetup),
            ),
            _QuizCategoryCard(
              icon: Icons.lightbulb_outline,
              title: 'معلومات عامة',
              description: 'أسئلة متنوعة عن القرآن',
              color: AppColors.maghrib,
              onTap: () => context.pushNamed(RouteNames.quizSetup),
            ),

            SizedBox(height: context.bottomPadding + 16),
          ],
        ),
      ),
    );
  }
}

class _QuizCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _QuizCategoryCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: AppTextStyles.arabicBody.copyWith(fontWeight: FontWeight.w600),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Text(
          description,
          style: AppTextStyles.arabicCaption.copyWith(
            color: AppColors.textTertiaryLight,
          ),
          textDirection: TextDirection.rtl,
        ),
        trailing: Icon(Icons.chevron_left, color: color),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
