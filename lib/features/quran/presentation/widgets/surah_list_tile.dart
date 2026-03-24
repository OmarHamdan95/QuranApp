import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:quran_app/core/extensions/context_extensions.dart';
import 'package:quran_app/core/routing/app_router.dart';
import 'package:quran_app/core/theme/app_colors.dart';
import 'package:quran_app/core/theme/app_text_styles.dart';
import 'package:quran_app/features/quran/domain/entities/surah.dart';

/// A modern card-style list tile for displaying surah information.
///
/// Shows:
/// - Surah number in a decorative octagonal badge
/// - Arabic name (AmiriQuran font, RTL)
/// - English transliteration and meaning
/// - Ayah count and revelation type with subtle icon
///
/// Tapping navigates to the [QuranReaderScreen] for that surah.
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        elevation: isDark ? 0 : 1,
        shadowColor: AppColors.primary.withValues(alpha: 0.08),
        child: InkWell(
          onTap: onTap ??
              () => context.pushNamed(
                    RouteNames.quranReader,
                    pathParameters: {
                      'surahNumber': surah.number.toString(),
                    },
                  ),
          borderRadius: BorderRadius.circular(18),
          splashColor: AppColors.primary.withValues(alpha: 0.06),
          highlightColor: AppColors.primary.withValues(alpha: 0.03),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark.withValues(alpha: 0.4)
                    : AppColors.borderLight.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // -- Surah Number Badge --
                _SurahNumberBadge(number: surah.number, isDark: isDark),
                const SizedBox(width: 14),

                // -- Surah Name & Metadata --
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // English transliteration
                      Text(
                        surah.nameEnglish,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // English meaning
                      Text(
                        surah.nameTranslation,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Metadata row: revelation type + ayah count
                      Row(
                        children: [
                          _RevelationBadge(
                            isMeccan: surah.isMeccan,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.auto_stories_outlined,
                            size: 12,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${surah.ayahCount.toString().toArabicNumerals} آية',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                              fontFamily: 'Amiri',
                              fontSize: 11,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // -- Arabic Name --
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      surah.nameArabic,
                      style: AppTextStyles.surahNameArabic.copyWith(
                        fontSize: 24,
                        color: isDark
                            ? AppColors.quranTextColorDark
                            : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -- Surah Number Badge --

class _SurahNumberBadge extends StatelessWidget {
  final int number;
  final bool isDark;

  const _SurahNumberBadge({
    required this.number,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotated square (Islamic star motif)
          Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                    AppColors.secondary.withValues(alpha: isDark ? 0.15 : 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          // Circle overlay
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.2),
                width: 1.5,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: Text(
              number.toString(),
              style: AppTextStyles.labelMedium.copyWith(
                color: isDark ? AppColors.primaryLight : AppColors.primary,
                fontWeight: FontWeight.w800,
                fontFamily: 'Amiri',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Revelation Badge --

class _RevelationBadge extends StatelessWidget {
  final bool isMeccan;
  final bool isDark;

  const _RevelationBadge({
    required this.isMeccan,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isMeccan ? AppColors.secondary : AppColors.tertiary;
    final label = isMeccan ? 'مكية' : 'مدنية';
    final icon = isMeccan ? Icons.location_city_rounded : Icons.mosque_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontFamily: 'Amiri',
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
