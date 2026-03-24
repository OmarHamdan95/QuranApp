import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../quran/presentation/providers/quran_providers.dart';
import '../../domain/entities/tafsir.dart';
import '../providers/tafsir_providers.dart';

/// Full-screen tafsir reader for a specific ayah.
///
/// Features:
/// - Displays the ayah text above the tafsir.
/// - Source selector tabs (5 tafsir books).
/// - Font size control.
/// - Copy / share actions.
/// - Previous / next ayah navigation.
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
    final selectedSource = ref.watch(selectedTafsirSourceProvider);
    final fontSize = ref.watch(tafsirFontSizeProvider);
    final isDark = context.isDarkMode;

    final tafsirAsync = ref.watch(
      tafsirProvider(
        TafsirKey(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          source: selectedSource,
        ),
      ),
    );

    final ayahAsync =
        ref.watch(ayahsBySurahProvider(surahNumber));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'التفسير',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.primary,
          ),
        ),
        actions: [
          // Font size decrease
          IconButton(
            icon: const Icon(Icons.text_decrease, size: 20),
            tooltip: 'تصغير الخط',
            onPressed: fontSize > 12
                ? () => ref.read(tafsirFontSizeProvider.notifier).state =
                    fontSize - 1
                : null,
          ),
          // Font size increase
          IconButton(
            icon: const Icon(Icons.text_increase, size: 20),
            tooltip: 'تكبير الخط',
            onPressed: fontSize < 28
                ? () => ref.read(tafsirFontSizeProvider.notifier).state =
                    fontSize + 1
                : null,
          ),
          // Share
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            tooltip: 'مشاركة',
            onPressed: () => _shareContent(context, ref, selectedSource),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Source selector tabs ──
          _SourceTabBar(
            selected: selectedSource,
            onSelect: (source) => ref
                .read(selectedTafsirSourceProvider.notifier)
                .state = source,
          ),

          // ── Main content ──
          Expanded(
            child: tafsirAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(
                  tafsirProvider(
                    TafsirKey(
                      surahNumber: surahNumber,
                      ayahNumber: ayahNumber,
                      source: selectedSource,
                    ),
                  ),
                ),
              ),
              data: (tafsir) => _TafsirContent(
                tafsir: tafsir,
                ayahAsync: ayahAsync,
                ayahNumber: ayahNumber,
                surahNumber: surahNumber,
                fontSize: fontSize,
                isDark: isDark,
                onPrevious: ayahNumber > 1
                    ? () => context.pushReplacementNamed(
                          RouteNames.tafsir,
                          pathParameters: {
                            'surahNumber': surahNumber.toString(),
                            'ayahNumber': (ayahNumber - 1).toString(),
                          },
                        )
                    : null,
                onNext: () => context.pushReplacementNamed(
                  RouteNames.tafsir,
                  pathParameters: {
                    'surahNumber': surahNumber.toString(),
                    'ayahNumber': (ayahNumber + 1).toString(),
                  },
                ),
                onCopy: () => _copyTafsir(context, tafsir),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyTafsir(BuildContext context, Tafsir tafsir) {
    Clipboard.setData(ClipboardData(text: tafsir.text));
    context.showSnackBar('تم نسخ التفسير');
  }

  void _shareContent(
    BuildContext context,
    WidgetRef ref,
    TafsirSource source,
  ) {
    final tafsirState = ref.read(
      tafsirProvider(
        TafsirKey(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          source: source,
        ),
      ),
    );
    tafsirState.whenData((tafsir) {
      Share.share(
        '$surahNumber:$ayahNumber\n\n${source.arabicName}:\n${tafsir.text}',
        subject: 'تفسير آية $surahNumber:$ayahNumber',
      );
    });
  }
}

// ── Source tab bar ────────────────────────────────────────────────────────────

class _SourceTabBar extends StatelessWidget {
  final TafsirSource selected;
  final ValueChanged<TafsirSource> onSelect;

  const _SourceTabBar({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.dividerLight.withValues(alpha: 0.6),
          ),
        ),
      ),
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: TafsirSource.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final source = TafsirSource.values[index];
          final isSelected = source == selected;
          return FilterChip(
            label: Text(
              source.shortLabel,
              style: AppTextStyles.arabicCaption.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            checkmarkColor: Colors.white,
            showCheckmark: false,
            onSelected: (_) => onSelect(source),
          );
        },
      ),
    );
  }
}

// ── Tafsir content ────────────────────────────────────────────────────────────

class _TafsirContent extends StatelessWidget {
  final Tafsir tafsir;
  final AsyncValue<dynamic> ayahAsync;
  final int ayahNumber;
  final int surahNumber;
  final double fontSize;
  final bool isDark;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCopy;

  const _TafsirContent({
    required this.tafsir,
    required this.ayahAsync,
    required this.ayahNumber,
    required this.surahNumber,
    required this.fontSize,
    required this.isDark,
    required this.onPrevious,
    required this.onNext,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Ayah display box ──
          _AyahBox(
            ayahAsync: ayahAsync,
            ayahNumber: ayahNumber,
            surahNumber: surahNumber,
            isDark: isDark,
          ),

          const SizedBox(height: 20),

          // ── Tafsir source header ──
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tafsir.source.arabicName,
                      style: AppTextStyles.arabicBody.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      tafsir.source.authorDescription,
                      style: AppTextStyles.arabicCaption.copyWith(
                        color: AppColors.textTertiaryLight,
                        fontSize: 12,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 20),
                tooltip: 'نسخ التفسير',
                onPressed: onCopy,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Tafsir text ──
          SelectableText(
            tafsir.text,
            style: AppTextStyles.tafsirArabic.copyWith(
              fontSize: fontSize,
              height: 1.9,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),

          const SizedBox(height: 32),

          // ── Navigation buttons ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onPrevious != null)
                OutlinedButton.icon(
                  onPressed: onPrevious,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(
                    'الآية السابقة',
                    style: AppTextStyles.arabicCaption,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                )
              else
                const SizedBox.shrink(),
              OutlinedButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(
                  'الآية التالية',
                  style: AppTextStyles.arabicCaption,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),

          SizedBox(height: context.bottomPadding + 16),
        ],
      ),
    );
  }
}

// ── Ayah display box ──────────────────────────────────────────────────────────

class _AyahBox extends StatelessWidget {
  final AsyncValue<dynamic> ayahAsync;
  final int ayahNumber;
  final int surahNumber;
  final bool isDark;

  const _AyahBox({
    required this.ayahAsync,
    required this.ayahNumber,
    required this.surahNumber,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.quranPageBackgroundDark
            : AppColors.quranPageBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          // Reference
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'سورة $surahNumber  -  آية $ayahNumber',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Ayah text
          ayahAsync.when(
            loading: () => const SizedBox(
              height: 48,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => Text(
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
            data: (ayahs) {
              if (ayahs is! List || ayahs.isEmpty) {
                return Text(
                  '...',
                  style: AppTextStyles.quranAyah.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                );
              }
              final ayah = (ayahs as List).firstWhere(
                (a) => a.ayahNumber == ayahNumber,
                orElse: () => ayahs.first,
              );
              return Text(
                ayah.textUthmani as String,
                style: AppTextStyles.quranAyah.copyWith(
                  fontSize: 22,
                  color: isDark
                      ? AppColors.quranTextColorDark
                      : AppColors.quranTextColor,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'تعذّر تحميل التفسير',
              style: AppTextStyles.arabicBody.copyWith(
                color: AppColors.error,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(
                'إعادة المحاولة',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
