import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/audio_providers.dart';
import '../widgets/audio_controls_widget.dart';
import '../widgets/reciter_selector.dart';

/// Full-screen audio player with reciter selection, surah picker,
/// and playback controls.
class AudioPlayerScreen extends ConsumerWidget {
  const AudioPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final selectedReciter = ref.watch(selectedReciterProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الاستماع للقرآن',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Reciter display
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.secondary.withValues(alpha: 0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reciter name
                  GestureDetector(
                    onTap: () => ReciterSelector.show(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          selectedReciter.nameArabic,
                          style: AppTextStyles.arabicHeadline.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.textTertiaryLight,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    selectedReciter.nameEnglish,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Current surah info
                  if (audioState.currentSurahNumber != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'سورة ${audioState.currentSurahNumber}',
                        style: AppTextStyles.arabicBody.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    )
                  else
                    Text(
                      'اختر سورة للاستماع',
                      style: AppTextStyles.arabicBody.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                      textDirection: TextDirection.rtl,
                    ),

                  const SizedBox(height: 24),

                  // Surah selection grid
                  _SurahQuickSelect(
                    onSurahSelected: (surahNumber) {
                      ref
                          .read(audioPlayerProvider.notifier)
                          .playSurah(surahNumber);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom audio controls
          const AudioControlsWidget(),
          SizedBox(height: context.bottomPadding),
        ],
      ),
    );
  }
}

/// Quick-select grid for popular/short surahs.
class _SurahQuickSelect extends StatelessWidget {
  final ValueChanged<int> onSurahSelected;

  const _SurahQuickSelect({required this.onSurahSelected});

  static const _popularSurahs = [
    (1, 'الفاتحة'),
    (2, 'البقرة'),
    (18, 'الكهف'),
    (36, 'يس'),
    (55, 'الرحمن'),
    (56, 'الواقعة'),
    (67, 'الملك'),
    (78, 'النبأ'),
    (112, 'الإخلاص'),
    (113, 'الفلق'),
    (114, 'الناس'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _popularSurahs.map((entry) {
        final (number, name) = entry;
        return ActionChip(
          label: Text(
            name,
            style: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.primary,
            ),
          ),
          onPressed: () => onSurahSelected(number),
          avatar: CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              number.toString(),
              style: const TextStyle(fontSize: 9, color: AppColors.primary),
            ),
          ),
        );
      }).toList(),
    );
  }
}
