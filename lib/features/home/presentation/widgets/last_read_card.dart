import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../quran/presentation/providers/quran_providers.dart';

/// Card showing the user's last reading position with a "Continue" action.
class LastReadCard extends ConsumerWidget {
  const LastReadCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRead = ref.watch(lastReadPositionProvider);
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (lastRead != null) {
            context.pushNamed(
              RouteNames.quranReader,
              pathParameters: {
                'surahNumber': lastRead.surahNumber.toString(),
              },
              queryParameters: {
                'ayah': lastRead.ayahNumber.toString(),
              },
            );
          } else {
            context.pushNamed(RouteNames.surahIndex);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Book icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.15),
                      AppColors.secondary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),

              // Reading info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'آخر قراءة',
                      style: AppTextStyles.arabicCaption.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    if (lastRead != null) ...[
                      Text(
                        'سورة ${lastRead.surahNumber} - آية ${lastRead.ayahNumber}',
                        style: AppTextStyles.arabicBody.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      Text(
                        'صفحة ${lastRead.page}',
                        style: AppTextStyles.arabicCaption.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ] else
                      Text(
                        'ابدأ القراءة الآن',
                        style: AppTextStyles.arabicBody.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                  ],
                ),
              ),

              // Continue arrow
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
