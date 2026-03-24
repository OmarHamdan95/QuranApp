import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/surah.dart';

/// A list tile displaying surah information with Arabic name,
/// English name, revelation type, and ayah count.
class SurahListTile extends StatelessWidget {
  final Surah surah;
  final VoidCallback? onTap;

  const SurahListTile({
    super.key,
    required this.surah,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: onTap ??
          () => context.pushNamed(
                RouteNames.quranReader,
                pathParameters: {'surahNumber': surah.number.toString()},
              ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Surah number in decorative container
            _SurahNumberBadge(number: surah.number),
            const SizedBox(width: 16),

            // Surah info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameEnglish,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${surah.revelationType} - ${surah.ayahCount} Ayahs',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // Arabic name
            Text(
              surah.nameArabic,
              style: AppTextStyles.surahNameArabic.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahNumberBadge extends StatelessWidget {
  final int number;

  const _SurahNumberBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
