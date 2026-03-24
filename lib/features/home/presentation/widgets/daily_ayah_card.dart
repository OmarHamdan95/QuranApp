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
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Decorative geometric pattern ───────────────────────────
          Positioned(
            top: -20,
            right: -20,
            child: _DecorativeCircle(
              size: 120,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -15,
            child: _DecorativeCircle(
              size: 100,
              color: Colors.white.withValues(alpha: 0.03),
            ),
          ),
          Positioned(
            top: 20,
            left: 30,
            child: _DecorativeCircle(
              size: 60,
              color: AppColors.secondary.withValues(alpha: 0.08),
            ),
          ),

          // ── Content ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.secondaryLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'آية اليوم',
                      style: AppTextStyles.arabicHeadline.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),

                    // Refresh button
                    IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white60,
                        size: 20,
                      ),
                      tooltip: 'آية أخرى',
                      onPressed: () => ref.invalidate(dailyAyahProvider),
                      visualDensity: VisualDensity.compact,
                    ),

                    // Share button
                    ayahAsync.whenOrNull(
                      data: (ayah) => IconButton(
                        icon: const Icon(
                          Icons.share_rounded,
                          color: Colors.white60,
                          size: 20,
                        ),
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
                        visualDensity: VisualDensity.compact,
                      ),
                    ) ?? const SizedBox.shrink(),
                  ],
                ),
                const SizedBox(height: 16),

                // Decorative top divider
                _GoldenDivider(),

                const SizedBox(height: 14),

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
                        child: Text(
                          ayah.textUthmani,
                          style: AppTextStyles.quranAyah.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                            height: 2.0,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Reference badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                Colors.white.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'سورة ${ayah.surahNumber} — الآية ${ayah.ayahNumber.toString().toArabicNumerals}',
                          style: AppTextStyles.arabicCaption.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  error: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(dailyAyahProvider),
                          child: Text(
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

class _GoldenDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.star_rounded,
            size: 10,
            color: AppColors.secondaryLight.withValues(alpha: 0.7),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}
