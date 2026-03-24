import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:quran_app/core/extensions/context_extensions.dart';
import 'package:quran_app/core/theme/app_colors.dart';
import 'package:quran_app/core/theme/app_text_styles.dart';
import 'package:quran_app/features/quran/domain/entities/ayah.dart';

/// Renders a single Ayah with beautiful Arabic typography and modern design.
///
/// Features:
/// - Uthmani-script Arabic text with customisable font size
/// - Decorative ayah number marker
/// - Optional translation overlay
/// - Sajdah indicator badge
/// - Per-ayah action bar (play, bookmark, tafsir, copy/share)
/// - Tap-to-highlight with smooth animation
/// - Generous line height and padding for comfortable reading
class AyahWidget extends StatelessWidget {
  final Ayah ayah;
  final double fontSize;
  final bool showTranslation;
  final String? translationText;
  final bool isHighlighted;
  final bool isPlaying;
  final bool isBookmarked;
  final VoidCallback? onTap;
  final VoidCallback? onTapTafsir;
  final VoidCallback? onTapBookmark;
  final VoidCallback? onTapPlay;
  final VoidCallback? onTapShare;

  const AyahWidget({
    super.key,
    required this.ayah,
    this.fontSize = 28.0,
    this.showTranslation = false,
    this.translationText,
    this.isHighlighted = false,
    this.isPlaying = false,
    this.isBookmarked = false,
    this.onTap,
    this.onTapTafsir,
    this.onTapBookmark,
    this.onTapPlay,
    this.onTapShare,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    Color containerColor;
    if (isHighlighted) {
      containerColor = isDark
          ? AppColors.ayahHighlightDark
          : AppColors.ayahHighlight;
    } else if (isPlaying) {
      containerColor = AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.05);
    } else if (ayah.sajdah) {
      containerColor = AppColors.sajdahHighlight.withValues(alpha: 0.3);
    } else {
      containerColor = Colors.transparent;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(16),
          border: isHighlighted
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.2),
                  width: 1,
                )
              : isPlaying
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 0.5,
                    )
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -- Ayah Header with number and actions --
            _AyahHeader(
              ayah: ayah,
              isPlaying: isPlaying,
              isBookmarked: isBookmarked,
              isDark: isDark,
              onTapPlay: onTapPlay,
              onTapBookmark: onTapBookmark,
              onTapTafsir: onTapTafsir,
              onTapShare: onTapShare ?? _defaultShare(context, ayah),
            ),

            // -- Arabic Text --
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                ayah.textUthmani,
                style: AppTextStyles.quranAyah.copyWith(
                  fontSize: fontSize,
                  color: isDark
                      ? AppColors.quranTextColorDark
                      : AppColors.quranTextColor,
                  height: 2.2,
                  wordSpacing: 6,
                ),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                locale: const Locale('ar'),
              ),
            ),

            // -- Translation (optional) --
            if (showTranslation && translationText != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  height: 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        (isDark ? AppColors.dividerDark : AppColors.dividerLight)
                            .withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
                child: Text(
                  translationText!,
                  style: AppTextStyles.translationText.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.left,
                  textDirection: TextDirection.ltr,
                ),
              ),
            ] else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  VoidCallback _defaultShare(BuildContext context, Ayah ayah) {
    return () {
      Clipboard.setData(
        ClipboardData(
          text: '${ayah.textUthmani}\n\n— ${ayah.reference}',
        ),
      );
      context.showSuccess('تم نسخ الآية');
    };
  }
}

// -- Ayah Header --

class _AyahHeader extends StatelessWidget {
  final Ayah ayah;
  final bool isPlaying;
  final bool isBookmarked;
  final bool isDark;
  final VoidCallback? onTapPlay;
  final VoidCallback? onTapBookmark;
  final VoidCallback? onTapTafsir;
  final VoidCallback? onTapShare;

  const _AyahHeader({
    required this.ayah,
    required this.isPlaying,
    required this.isBookmarked,
    required this.isDark,
    this.onTapPlay,
    this.onTapBookmark,
    this.onTapTafsir,
    this.onTapShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Row(
        children: [
          // -- Ayah Number Marker --
          _AyahNumberMarker(
            number: ayah.ayahNumber,
            isDark: isDark,
            isPlaying: isPlaying,
          ),
          const SizedBox(width: 8),

          // -- Sajdah indicator --
          if (ayah.sajdah) _SajdahBadge(isDark: isDark),

          const Spacer(),

          // -- Action Buttons --
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
                  : AppColors.surfaceVariantLight.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionIconButton(
                  icon: isPlaying
                      ? Icons.pause_circle_rounded
                      : Icons.play_circle_outline_rounded,
                  tooltip: isPlaying ? 'إيقاف' : 'تشغيل',
                  onTap: onTapPlay,
                  color: isPlaying ? AppColors.primary : null,
                  isDark: isDark,
                ),
                _ActionIconButton(
                  icon: isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  tooltip: isBookmarked ? 'إزالة الإشارة' : 'إضافة إشارة',
                  onTap: onTapBookmark,
                  color: isBookmarked ? AppColors.secondary : null,
                  isDark: isDark,
                ),
                _ActionIconButton(
                  icon: Icons.auto_stories_outlined,
                  tooltip: 'التفسير',
                  onTap: onTapTafsir,
                  isDark: isDark,
                ),
                _ActionIconButton(
                  icon: Icons.copy_rounded,
                  tooltip: 'نسخ',
                  onTap: onTapShare,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -- Ayah Number Marker (decorative) --

class _AyahNumberMarker extends StatelessWidget {
  final int number;
  final bool isDark;
  final bool isPlaying;

  const _AyahNumberMarker({
    required this.number,
    required this.isDark,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.primary;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            baseColor.withValues(alpha: isDark ? 0.2 : 0.1),
            baseColor.withValues(alpha: isDark ? 0.06 : 0.03),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: baseColor.withValues(alpha: isDark ? 0.4 : 0.25),
          width: 1.5,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString().toArabicNumerals,
        style: AppTextStyles.ayahNumber.copyWith(
          fontSize: number > 99 ? 11 : 13,
          color: isDark ? AppColors.primaryLight : AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

// -- Sajdah Badge --

class _SajdahBadge extends StatelessWidget {
  final bool isDark;

  const _SajdahBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: isDark ? 0.2 : 0.12),
            AppColors.secondary.withValues(alpha: isDark ? 0.12 : 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_downward_rounded,
            size: 11,
            color: AppColors.secondaryDark,
          ),
          const SizedBox(width: 4),
          Text(
            'سجدة',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.secondaryDark,
              fontFamily: 'Amiri',
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// -- Action Icon Button --

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;
  final bool isDark;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ??
        (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ),
      ),
    );
  }
}
