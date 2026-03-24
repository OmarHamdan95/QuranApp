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
/// Uses a subtle gradient / glassmorphism effect with the primary color.
/// When no previous reading exists, encourages the user to start reading.
class LastReadCard extends ConsumerWidget {
  const LastReadCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRead = ref.watch(lastReadPositionProvider);
    final isDark = context.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  AppColors.secondary.withValues(alpha: 0.15),
                  AppColors.cardDark,
                ]
              : [
                  AppColors.secondaryContainer.withValues(alpha: 0.6),
                  AppColors.cardLight,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.secondary.withValues(alpha: 0.2)
              : AppColors.secondary.withValues(alpha: 0.15),
          width: 0.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
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
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // -- Icon --
                _BookIcon(isDark: isDark),
                const SizedBox(width: 14),

                // -- Reading Info --
                Expanded(
                  child: _ReadingInfo(
                    lastRead: lastRead,
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),
                ),

                // -- Continue Button --
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
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withValues(alpha: isDark ? 0.3 : 0.2),
            AppColors.secondary.withValues(alpha: isDark ? 0.12 : 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: const Icon(
        Icons.menu_book_rounded,
        color: AppColors.secondary,
        size: 28,
      ),
    );
  }
}

class _ReadingInfo extends StatelessWidget {
  final ReadingPosition? lastRead;
  final bool isDark;
  final ColorScheme colorScheme;

  const _ReadingInfo({
    required this.lastRead,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = colorScheme.onSurface;
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
              color: AppColors.secondary,
              fontSize: 17,
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
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'آخر قراءة',
            style: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
        const SizedBox(height: 6),

        // Surah name
        Text(
          lastRead!.surahName.isNotEmpty
              ? lastRead!.surahName
              : 'سورة ${lastRead!.surahNumber.toString().toArabicNumerals}',
          style: AppTextStyles.arabicBody.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
            fontSize: 17,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary,
            AppColors.secondaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasProgress
                ? Icons.play_arrow_rounded
                : Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            hasProgress ? 'أكمل' : 'ابدأ',
            style: AppTextStyles.arabicCaption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
