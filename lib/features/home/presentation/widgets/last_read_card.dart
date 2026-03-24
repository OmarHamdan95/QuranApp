import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../quran/presentation/providers/quran_providers.dart';

/// Card showing the user's last reading position with a "Continue" button.
///
/// When no previous reading exists, encourages the user to start reading.
/// Displays the surah number, name (if available), ayah number, and page.
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
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
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ── Icon ────────────────────────────────────────────
                _BookIcon(isDark: isDark),
                const SizedBox(width: 14),

                // ── Reading Info ─────────────────────────────────────
                Expanded(
                  child: _ReadingInfo(
                    lastRead: lastRead,
                    isDark: isDark,
                  ),
                ),

                // ── Continue Button ──────────────────────────────────
                _ContinueButton(
                  hasProgress: lastRead != null,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookIcon extends StatelessWidget {
  final bool isDark;

  const _BookIcon({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: isDark ? 0.25 : 0.15),
            AppColors.secondary.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: const Icon(
        Icons.menu_book_rounded,
        color: AppColors.secondary,
        size: 26,
      ),
    );
  }
}

class _ReadingInfo extends StatelessWidget {
  final ReadingPosition? lastRead;
  final bool isDark;

  const _ReadingInfo({
    required this.lastRead,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    if (lastRead == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'ابدأ القراءة',
            style: AppTextStyles.arabicBody.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 16,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 3),
          Text(
            'لم تقرأ بعد، ابدأ من الفاتحة',
            style: AppTextStyles.arabicCaption.copyWith(
              color: subColor,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'آخر قراءة',
          style: AppTextStyles.arabicCaption.copyWith(
            color: subColor,
            fontSize: 11,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 3),

        // Surah name if available, otherwise surah number
        Text(
          lastRead!.surahName.isNotEmpty
              ? lastRead!.surahName
              : 'سورة ${lastRead!.surahNumber.toString().toArabicNumerals}',
          style: AppTextStyles.arabicBody.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
            fontSize: 16,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 2),

        // Ayah + page info
        Text(
          'آية ${lastRead!.ayahNumber.toString().toArabicNumerals} · صفحة ${lastRead!.page.toString().toArabicNumerals}',
          style: AppTextStyles.arabicCaption.copyWith(
            color: subColor,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final bool hasProgress;
  final bool isDark;

  const _ContinueButton({
    required this.hasProgress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Icon(
        hasProgress
            ? Icons.play_arrow_rounded
            : Icons.arrow_forward_rounded,
        color: AppColors.primary,
        size: 20,
      ),
    );
  }
}
