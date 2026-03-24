import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/quran_providers.dart';

/// Names (opening words) of each of the 30 juz.
const _juzNames = <String>[
  'آلم', 'سَيَقُولُ', 'تِلْكَ الرُّسُلُ', 'لَنْ تَنَالُوا',
  'وَالْمُحْصَنَاتُ', 'لَا يُحِبُّ اللَّهُ', 'وَإِذَا سَمِعُوا',
  'وَلَوْ أَنَّنَا', 'قَالَ الْمَلَأُ', 'وَاعْلَمُوا',
  'يَعْتَذِرُونَ', 'وَمَا مِنْ دَابَّةٍ', 'وَمَا أُبَرِّئُ',
  'رُبَمَا', 'سُبْحَانَ الَّذِي', 'قَالَ أَلَمْ',
  'اقْتَرَبَ', 'قَدْ أَفْلَحَ', 'وَقَالَ الَّذِينَ',
  'أَمَّنْ خَلَقَ', 'اتْلُ مَا أُوحِيَ', 'وَمَنْ يَقْنُتْ',
  'وَمَا لِيَ', 'فَمَنْ أَظْلَمُ', 'إِلَيْهِ يُرَدُّ',
  'حم', 'قَالَ فَمَا خَطْبُكُمْ', 'قَدْ سَمِعَ اللَّهُ',
  'تَبَارَكَ الَّذِي', 'عَمَّ',
];

/// Starting surah number for each juz (1-indexed: index 0 = juz 1).
const _juzStartSurah = <int>[
  1, 2, 2, 3, 4, 4, 5, 6, 7, 8, 9, 11, 12, 15, 17, 18, 21, 23, 25, 27,
  29, 33, 36, 39, 41, 46, 51, 58, 67, 78,
];

/// Starting page in the Mushaf for each juz.
const _juzStartPage = <int>[
  1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
  201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
  402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
];

/// Screen showing the index of all 30 Juz of the Quran.
///
/// Displays each juz with its number, opening words, starting surah and
/// Mushaf page. Tapping navigates to the Quran reader at that juz.
class JuzIndexScreen extends ConsumerWidget {
  const JuzIndexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'فهرس الأجزاء',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: 30,
        itemBuilder: (context, index) {
          return _JuzCard(
            index: index,
            isDark: isDark,
            onTap: () {
              // Navigate to the first surah of this juz.
              final surahNumber = _juzStartSurah[index];
              context.pushNamed(
                RouteNames.quranReader,
                pathParameters: {'surahNumber': surahNumber.toString()},
              );
            },
          );
        },
      ),
    );
  }
}

class _JuzCard extends StatelessWidget {
  final int index;
  final bool isDark;
  final VoidCallback onTap;

  const _JuzCard({
    required this.index,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final juzNumber = index + 1;
    final juzName = _juzNames[index];
    final startSurah = _juzStartSurah[index];
    final startPage = _juzStartPage[index];

    // Gradient rotates subtly across the list for visual rhythm.
    final hue = (index * 12) % 360;
    final accentColor = HSLColor.fromAHSL(1, hue.toDouble(), 0.6, 0.45).toColor();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // ── Juz Number Badge ────────────────────────────────────
              _JuzNumberBadge(
                number: juzNumber,
                accentColor: accentColor,
              ),
              const SizedBox(width: 16),

              // ── Juz Info ────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Juz label + opening words
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '« $juzName »',
                          style: AppTextStyles.arabicCaption.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                            fontStyle: FontStyle.italic,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'الجزء ${juzNumber.toString().toArabicNumerals}',
                          style: AppTextStyles.arabicBody.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Metadata row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _MetadataBadge(
                          icon: Icons.menu_book_outlined,
                          label: 'صفحة $startPage',
                          color: AppColors.tertiary,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _MetadataBadge(
                          icon: Icons.layers_outlined,
                          label: 'سورة $startSurah',
                          color: AppColors.primary,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),
              Icon(
                Icons.chevron_left,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JuzNumberBadge extends StatelessWidget {
  final int number;
  final Color accentColor;

  const _JuzNumberBadge({
    required this.number,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.2),
            accentColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: AppTextStyles.headlineSmall.copyWith(
          color: accentColor,
          fontWeight: FontWeight.w800,
          fontFamily: 'Amiri',
        ),
      ),
    );
  }
}

class _MetadataBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _MetadataBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontFamily: 'Amiri',
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 12, color: color),
        ],
      ),
    );
  }
}
