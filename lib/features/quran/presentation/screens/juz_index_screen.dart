import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Names of the 30 juz of the Quran.
const _juzNames = <String>[
  'آلم', 'سَيَقُولُ', 'تِلْكَ الرُّسُلُ', 'لَنْ تَنَالُوا', 'وَالْمُحْصَنَاتُ',
  'لَا يُحِبُّ اللَّهُ', 'وَإِذَا سَمِعُوا', 'وَلَوْ أَنَّنَا', 'قَالَ الْمَلَأُ', 'وَاعْلَمُوا',
  'يَعْتَذِرُونَ', 'وَمَا مِنْ دَابَّةٍ', 'وَمَا أُبَرِّئُ', 'رُبَمَا', 'سُبْحَانَ الَّذِي',
  'قَالَ أَلَمْ', 'اقْتَرَبَ', 'قَدْ أَفْلَحَ', 'وَقَالَ الَّذِينَ', 'أَمَّنْ خَلَقَ',
  'اتْلُ مَا أُوحِيَ', 'وَمَنْ يَقْنُتْ', 'وَمَا لِيَ', 'فَمَنْ أَظْلَمُ', 'إِلَيْهِ يُرَدُّ',
  'حم', 'قَالَ فَمَا خَطْبُكُمْ', 'قَدْ سَمِعَ اللَّهُ', 'تَبَارَكَ الَّذِي', 'عَمَّ',
];

/// Screen showing the index of all 30 Juz of the Quran.
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
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: 30,
        itemBuilder: (context, index) {
          final juzNumber = index + 1;
          final juzName = _juzNames[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InkWell(
              onTap: () {
                // TODO: Navigate to juz reader
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Juz number badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.15),
                            AppColors.secondary.withValues(alpha: 0.08),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        juzNumber.toString().toArabicNumerals,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Juz info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الجزء ${'$juzNumber'.toArabicNumerals}',
                            style: AppTextStyles.arabicBody.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            juzName,
                            style: AppTextStyles.arabicCaption.copyWith(
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.chevron_left,
                      color: AppColors.textTertiaryLight,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
