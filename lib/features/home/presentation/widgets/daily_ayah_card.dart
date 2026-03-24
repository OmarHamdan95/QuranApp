import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../quran/presentation/providers/quran_providers.dart';

/// A card showing a randomly selected ayah of the day.
///
/// Displayed prominently on the home screen as daily inspiration.
class DailyAyahCard extends ConsumerWidget {
  const DailyAyahCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahAsync = ref.watch(dailyAyahProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
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
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white70, size: 20),
                  onPressed: () {
                    // TODO: Share daily ayah
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ayah text
            ayahAsync.when(
              data: (ayah) => Column(
                children: [
                  Text(
                    ayah.textUthmani,
                    style: AppTextStyles.quranAyah.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'سورة ${ayah.surahNumber} - آية ${ayah.ayahNumber}',
                      style: AppTextStyles.arabicCaption.copyWith(
                        color: Colors.white70,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                  style: AppTextStyles.quranAyah.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
