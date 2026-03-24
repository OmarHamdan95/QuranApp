import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/tafsir.dart';
import '../providers/tafsir_providers.dart';

/// A draggable bottom sheet showing a compact tafsir preview.
///
/// Features:
/// - Displays the ayah text.
/// - Source selector tabs at the top.
/// - Live tafsir preview that loads when source changes.
/// - Swipe-up to expand to ~85 % height.
/// - "قراءة التفسير الكامل" button to navigate to [TafsirViewScreen].
class TafsirBottomSheet extends ConsumerWidget {
  final int surahNumber;
  final int ayahNumber;
  final String ayahText;

  const TafsirBottomSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.ayahText,
  });

  /// Convenience static factory to show the sheet.
  static Future<void> show(
    BuildContext context, {
    required int surahNumber,
    required int ayahNumber,
    required String ayahText,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TafsirBottomSheet(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        ayahText: ayahText,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      maxChildSize: 0.88,
      minChildSize: 0.28,
      expand: false,
      snap: true,
      snapSizes: const [0.48, 0.88],
      builder: (ctx, scrollController) {
        return _SheetContent(
          scrollController: scrollController,
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          ayahText: ayahText,
        );
      },
    );
  }
}

// ── Sheet content (separate widget to watch providers) ───────────────────────

class _SheetContent extends ConsumerWidget {
  final ScrollController scrollController;
  final int surahNumber;
  final int ayahNumber;
  final String ayahText;

  const _SheetContent({
    required this.scrollController,
    required this.surahNumber,
    required this.ayahNumber,
    required this.ayahText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSource = ref.watch(selectedTafsirSourceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tafsirAsync = ref.watch(
      tafsirProvider(
        TafsirKey(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          source: selectedSource,
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Drag handle ──
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiaryLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Source selector ──
          _CompactSourceSelector(
            selected: selectedSource,
            onSelect: (source) =>
                ref.read(selectedTafsirSourceProvider.notifier).state = source,
          ),

          const Divider(height: 1),

          // ── Scrollable body ──
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                // Ayah reference
                Text(
                  'سورة $surahNumber  -  آية $ayahNumber',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: AppColors.textTertiaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),

                // Ayah text
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.quranPageBackgroundDark
                        : AppColors.quranPageBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ayahText,
                    style: AppTextStyles.quranAyah.copyWith(
                      fontSize: 20,
                      color: isDark
                          ? AppColors.quranTextColorDark
                          : AppColors.quranTextColor,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(height: 16),

                // Source name
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedSource.arabicName,
                      style: AppTextStyles.arabicBody.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tafsir preview
                tafsirAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, _) => Text(
                    'تعذّر تحميل التفسير. حاول مرة أخرى.',
                    style: AppTextStyles.arabicCaption.copyWith(
                      color: AppColors.error,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  data: (tafsir) => Text(
                    tafsir.text,
                    style: AppTextStyles.tafsirArabic.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.9,
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 8,
                    overflow: TextOverflow.fade,
                  ),
                ),

                const SizedBox(height: 20),

                // Full tafsir CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
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
                    icon: const Icon(Icons.auto_stories_outlined, size: 18),
                    label: Text(
                      'قراءة التفسير الكامل',
                      style: AppTextStyles.arabicCaption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

// ── Compact source selector ───────────────────────────────────────────────────

class _CompactSourceSelector extends StatelessWidget {
  final TafsirSource selected;
  final ValueChanged<TafsirSource> onSelect;

  const _CompactSourceSelector({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: TafsirSource.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          final source = TafsirSource.values[i];
          final isSelected = source == selected;
          return GestureDetector(
            onTap: () => onSelect(source),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                source.shortLabel,
                style: AppTextStyles.arabicCaption.copyWith(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondaryLight,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
