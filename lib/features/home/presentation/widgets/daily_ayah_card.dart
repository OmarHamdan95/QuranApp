import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../quran/presentation/providers/quran_providers.dart';

/// A card showing the daily ayah with beautiful Islamic-themed styling.
///
/// The ayah is randomly selected once per day and cached locally.
/// Tapping the card navigates to the full reader at that ayah.
/// Users can share / copy the ayah text from the action buttons.
class DailyAyahCard extends ConsumerWidget {
  const DailyAyahCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahAsync = ref.watch(dailyAyahProvider);
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  AppColors.primaryDark,
                  const Color(0xFF0A2E0A),
                ]
              : [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.35),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // -- Decorative geometric pattern --
          Positioned(
            top: -25,
            right: -25,
            child: _DecorativeCircle(
              size: 130,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Positioned(
            bottom: -35,
            left: -20,
            child: _DecorativeCircle(
              size: 110,
              color: Colors.white.withValues(alpha: 0.03),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: _DecorativeCircle(
              size: 50,
              color: AppColors.secondary.withValues(alpha: 0.06),
            ),
          ),
          // Small decorative diamond
          Positioned(
            top: 15,
            right: 70,
            child: Transform.rotate(
              angle: 0.785,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // -- Content --
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.secondaryLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'آية اليوم',
                          style: AppTextStyles.arabicHeadline.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'تدبر وتأمل',
                          style: AppTextStyles.arabicCaption.copyWith(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Refresh
                    _GlassIconButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'آية أخرى',
                      onPressed: () => ref.invalidate(dailyAyahProvider),
                    ),
                    const SizedBox(width: 6),

                    // Share
                    ayahAsync.whenOrNull(
                          data: (ayah) => _GlassIconButton(
                            icon: Icons.share_rounded,
                            tooltip: 'مشاركة',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text:
                                      '${ayah.textUthmani}\n\n— ${ayah.reference}',
                                ),
                              );
                              context.showSuccess('تم نسخ الآية');
                            },
                          ),
                        ) ??
                        const SizedBox.shrink(),
                  ],
                ),
                const SizedBox(height: 18),

                // Golden divider
                _GoldenDivider(),

                const SizedBox(height: 16),

                // Ayah content
                ayahAsync.when(
                  data: (ayah) => Column(
                    children: [
                      // Arabic text
                      GestureDetector(
                        onTap: () => context.pushNamed(
                          RouteNames.quranReader,
                          pathParameters: {
                            'surahNumber': ayah.surahNumber.toString(),
                          },
                          queryParameters: {
                            'ayah': ayah.ayahNumber.toString(),
                          },
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            ayah.textUthmani,
                            style: AppTextStyles.quranAyah.copyWith(
                              color: Colors.white,
                              fontSize: 23,
                              height: 2.0,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reference badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.library_books_rounded,
                              color: AppColors.secondaryLight
                                  .withValues(alpha: 0.8),
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'سورة ${ayah.surahNumber} — الآية ${ayah.ayahNumber.toString().toArabicNumerals}',
                              style: AppTextStyles.arabicCaption.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  error: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Text(
                          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                          style: AppTextStyles.quranAyah.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () =>
                              ref.invalidate(dailyAyahProvider),
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                          label: Text(
                            'إعادة التحميل',
                            style: AppTextStyles.arabicCaption.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -- Glass Icon Button -------------------------------------------------------

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white60, size: 18),
          ),
        ),
      ),
    );
  }
}

// -- Decorative Circle -------------------------------------------------------

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// -- Golden Divider ----------------------------------------------------------

class _GoldenDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryLight.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
