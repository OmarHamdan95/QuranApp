import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/surah.dart';

/// A polished list tile displaying information about a single Surah.
///
/// Shows:
/// - Number badge (with Islamic-inspired design)
/// - English transliteration + revelation info and ayah count
/// - Arabic calligraphic name
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

    return InkWell(
      onTap: onTap ??
          () => context.pushNamed(
                RouteNames.quranReader,
                pathParameters: {
                  'surahNumber': surah.number.toString(),
                },
              ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Number Badge ──────────────────────────────────────────
            _SurahNumberBadge(number: surah.number, isDark: isDark),
            const SizedBox(width: 14),

            // ── Surah Name & Meta ─────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameEnglish,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Revelation type chip
                      _RevealationChip(
                        isMeccan: surah.isMeccan,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${surah.ayahCount.toString().toArabicNumerals} آية',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                          fontFamily: 'Amiri',
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ── Arabic Name ───────────────────────────────────────────
            Text(
              surah.nameArabic,
              style: AppTextStyles.surahNameArabic.copyWith(
                fontSize: 22,
                color: isDark
                    ? AppColors.quranTextColorDark
                    : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Surah Number Badge ────────────────────────────────────────────────────────

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
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Octagonal decorative background (Islamic star motif approximated
          // with a rotated square overlapping a circle).
          Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              number.toString(),
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontFamily: 'Amiri',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Revelation Chip ───────────────────────────────────────────────────────────

class _RevealationChip extends StatelessWidget {
  final bool isMeccan;
  final bool isDark;

  const _RevealationChip({
    required this.isMeccan,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isMeccan ? AppColors.secondary : AppColors.tertiary;
    final label = isMeccan ? 'مكية' : 'مدنية';

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontFamily: 'Amiri',
          fontWeight: FontWeight.w600,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
