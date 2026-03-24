import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Full-screen tafsir view for a specific ayah.
class TafsirViewScreen extends ConsumerWidget {
  final int surahNumber;
  final int ayahNumber;

  const TafsirViewScreen({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'التفسير',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.primary,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.auto_stories),
            onSelected: (value) {
              // TODO: Switch tafsir source
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'ibn_kathir', child: Text('تفسير ابن كثير')),
              const PopupMenuItem(value: 'tabari', child: Text('تفسير الطبري')),
              const PopupMenuItem(value: 'qurtubi', child: Text('تفسير القرطبي')),
              const PopupMenuItem(value: 'saadi', child: Text('تفسير السعدي')),
              const PopupMenuItem(value: 'muyassar', child: Text('التفسير الميسر')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ayah reference
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'سورة $surahNumber - آية $ayahNumber',
                    style: AppTextStyles.arabicBody.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  // Placeholder ayah text
                  Text(
                    'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                    style: AppTextStyles.quranAyah.copyWith(
                      fontSize: 22,
                      color: isDark
                          ? AppColors.quranTextColorDark
                          : AppColors.quranTextColor,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tafsir source label
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'تفسير ابن كثير',
                  style: AppTextStyles.arabicBody.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tafsir text (placeholder)
            Text(
              'هذا موضع نص التفسير. سيتم تحميل التفسير من قاعدة البيانات المحلية. '
              'يحتوي التفسير على شرح مفصل للآية مع ذكر أسباب النزول والأحكام الفقهية '
              'والفوائد اللغوية والبلاغية.\n\n'
              'يمكن للمستخدم التبديل بين عدة تفاسير مختلفة من القائمة أعلاه.',
              style: AppTextStyles.tafsirArabic.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textDirection: TextDirection.rtl,
            ),

            const SizedBox(height: 24),

            // Navigation between ayahs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (ayahNumber > 1)
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to previous ayah tafsir
                    },
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(
                      'الآية السابقة',
                      style: AppTextStyles.arabicCaption,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to next ayah tafsir
                  },
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(
                    'الآية التالية',
                    style: AppTextStyles.arabicCaption,
                  ),
                ),
              ],
            ),

            SizedBox(height: context.bottomPadding + 16),
          ],
        ),
      ),
    );
  }
}
