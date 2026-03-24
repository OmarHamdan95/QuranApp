import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/ayah.dart';

/// Renders a single Ayah with its Arabic text, optional translation,
/// ayah number ornament, and action buttons (bookmark, share, tafsir, audio).
class AyahWidget extends StatelessWidget {
  final Ayah ayah;
  final double fontSize;
  final bool showTranslation;
  final String? translationText;
  final bool isHighlighted;
  final bool isPlaying;
  final VoidCallback? onTapTafsir;
  final VoidCallback? onTapBookmark;
  final VoidCallback? onTapPlay;
  final VoidCallback? onTapShare;
  final bool isBookmarked;

  const AyahWidget({
    super.key,
    required this.ayah,
    this.fontSize = 28.0,
    this.showTranslation = false,
    this.translationText,
    this.isHighlighted = false,
    this.isPlaying = false,
    this.onTapTafsir,
    this.onTapBookmark,
    this.onTapPlay,
    this.onTapShare,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted
            ? (isDark ? AppColors.ayahHighlightDark : AppColors.ayahHighlight)
            : (ayah.sajdah
                ? AppColors.sajdahHighlight
                : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Ayah Header (number + actions) ──
          _buildHeader(context, isDark),

          // ── Arabic Text ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              ayah.textUthmani,
              style: AppTextStyles.quranAyah.copyWith(
                fontSize: fontSize,
                color: isDark
                    ? AppColors.quranTextColorDark
                    : AppColors.quranTextColor,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),

          // ── Translation (optional) ──
          if (showTranslation && translationText != null) ...[
            const Divider(indent: 40, endIndent: 40, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                translationText!,
                style: AppTextStyles.translationText.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.left,
                textDirection: TextDirection.ltr,
              ),
            ),
          ],

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          // Ayah number badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              ayah.ayahNumber.toString().toArabicNumerals,
              style: AppTextStyles.ayahNumber,
            ),
          ),
          if (ayah.sajdah)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'سجدة',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.secondaryDark,
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
            ),

          const Spacer(),

          // Action buttons
          _ActionIconButton(
            icon: isPlaying ? Icons.pause_circle : Icons.play_circle_outline,
            onTap: onTapPlay,
            color: isPlaying ? AppColors.primary : null,
          ),
          _ActionIconButton(
            icon: isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
            onTap: onTapBookmark,
            color: isBookmarked ? AppColors.secondary : null,
          ),
          _ActionIconButton(
            icon: Icons.auto_stories_outlined,
            onTap: onTapTafsir,
          ),
          _ActionIconButton(
            icon: Icons.share_outlined,
            onTap: onTapShare ??
                () {
                  Clipboard.setData(ClipboardData(text: ayah.textUthmani));
                  context.showSuccess('Ayah copied');
                },
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _ActionIconButton({
    required this.icon,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onTap,
      color: color ?? AppColors.textTertiaryLight,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
