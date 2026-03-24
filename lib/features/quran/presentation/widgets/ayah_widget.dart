import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/ayah.dart';

/// Renders a single Ayah with beautiful Arabic typography.
///
/// Features:
/// - Uthmani-script Arabic text with customisable font size
/// - Optional translation overlay
/// - Sajdah indicator badge
/// - Per-ayah action bar (play, bookmark, tafsir, copy/share)
/// - Tap-to-highlight support
/// - Smooth highlight animation
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
      containerColor = AppColors.primary.withValues(alpha: 0.06);
    } else if (ayah.sajdah) {
      containerColor = AppColors.sajdahHighlight;
    } else {
      containerColor = Colors.transparent;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(14),
          border: isHighlighted
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Ayah Header ──────────────────────────────────────────
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

            // ── Arabic Text ──────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                ayah.textUthmani,
                style: AppTextStyles.quranAyah.copyWith(
                  fontSize: fontSize,
                  color: isDark
                      ? AppColors.quranTextColorDark
                      : AppColors.quranTextColor,
                  height: 2.0,
                ),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                locale: const Locale('ar'),
              ),
            ),

            // ── Translation (optional) ────────────────────────────────
            if (showTranslation && translationText != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Divider(
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight,
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
              const SizedBox(height: 4),
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

// ── Ayah Header ───────────────────────────────────────────────────────────────

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
      padding:
          const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          // ── Ayah Number Badge ─────────────────────────────────────
          _AyahNumberBadge(
            number: ayah.ayahNumber,
            isDark: isDark,
          ),
          const SizedBox(width: 8),

          // ── Sajdah indicator ──────────────────────────────────────
          if (ayah.sajdah)
            _SajdahBadge(isDark: isDark),

          const Spacer(),

          // ── Action Buttons ────────────────────────────────────────
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
    );
  }
}

// ── Ayah Number Badge ─────────────────────────────────────────────────────────

class _AyahNumberBadge extends StatelessWidget {
  final int number;
  final bool isDark;

  const _AyahNumberBadge({
    required this.number,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
            AppColors.primary.withValues(alpha: isDark ? 0.05 : 0.04),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString().toArabicNumerals,
        style: AppTextStyles.ayahNumber.copyWith(
          fontSize: 13,
          color: isDark ? AppColors.primaryLight : AppColors.primary,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

// ── Sajdah Badge ──────────────────────────────────────────────────────────────

class _SajdahBadge extends StatelessWidget {
  final bool isDark;

  const _SajdahBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_downward_rounded,
            size: 10,
            color: AppColors.secondaryDark,
          ),
          const SizedBox(width: 3),
          Text(
            'سجدة',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.secondaryDark,
              fontFamily: 'Amiri',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Icon Button ────────────────────────────────────────────────────────

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 19, color: iconColor),
        ),
      ),
    );
  }
}
