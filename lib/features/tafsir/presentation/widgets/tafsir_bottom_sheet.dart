import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// A bottom sheet showing a quick tafsir preview with option to
/// expand to full screen.
class TafsirBottomSheet extends StatelessWidget {
  final int surahNumber;
  final int ayahNumber;
  final String ayahText;

  const TafsirBottomSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.ayahText,
  });

  /// Shows the tafsir bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required int surahNumber,
    required int ayahNumber,
    required String ayahText,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TafsirBottomSheet(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        ayahText: ayahText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ayah text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.quranPageBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ayahText,
                  style: AppTextStyles.quranAyah.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'سورة $surahNumber - آية $ayahNumber',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),

              const Divider(height: 24),

              // Quick tafsir heading
              Text(
                'التفسير الميسر',
                style: AppTextStyles.arabicBody.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),

              // Tafsir preview text
              Text(
                'سيتم عرض التفسير المختصر هنا. اضغط "المزيد" للانتقال إلى صفحة التفسير الكامل مع خيارات تبديل المصادر.',
                style: AppTextStyles.tafsirArabic.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textDirection: TextDirection.rtl,
              ),

              const SizedBox(height: 16),

              // Full tafsir button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pushNamed(
                    RouteNames.tafsir,
                    pathParameters: {
                      'surahNumber': surahNumber.toString(),
                      'ayahNumber': ayahNumber.toString(),
                    },
                  );
                },
                child: Text(
                  'قراءة التفسير الكامل',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
