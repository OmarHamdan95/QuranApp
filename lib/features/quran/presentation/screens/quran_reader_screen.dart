import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/quran_providers.dart';
import '../widgets/ayah_widget.dart';

/// Full-screen Quran reading experience.
///
/// Supports continuous scroll (surah mode) with ayah-by-ayah rendering,
/// adjustable font size, and translation overlay.
class QuranReaderScreen extends ConsumerStatefulWidget {
  final int surahNumber;
  final int? initialAyah;

  const QuranReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
  });

  @override
  ConsumerState<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends ConsumerState<QuranReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showControls = true;
  int? _playingAyahNumber;

  @override
  void initState() {
    super.initState();
    // Immersive mode for reading
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    final surahAsync = ref.watch(surahProvider(widget.surahNumber));
    final ayahsAsync = ref.watch(ayahsBySurahProvider(widget.surahNumber));
    final fontSize = ref.watch(quranFontSizeProvider);
    final showTranslation = ref.watch(showTranslationProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.quranPageBackgroundDark : AppColors.quranPageBackground,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // ── Ayah List ──
            ayahsAsync.when(
              data: (ayahs) {
                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Top safe area padding
                    SliverToBoxAdapter(
                      child: SizedBox(height: context.topPadding + 56),
                    ),

                    // Surah header with Bismillah
                    surahAsync.when(
                      data: (surah) => SliverToBoxAdapter(
                        child: _SurahHeader(surahName: surah.nameArabic),
                      ),
                      loading: () => const SliverToBoxAdapter(child: SizedBox()),
                      error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
                    ),

                    // Bismillah (except for At-Tawbah and Al-Fatihah which has it as ayah 1)
                    if (widget.surahNumber != 9 && widget.surahNumber != 1)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                            style: AppTextStyles.bismillah.copyWith(
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),

                    // Ayahs
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final ayah = ayahs[index];
                          return AyahWidget(
                            ayah: ayah,
                            fontSize: fontSize,
                            showTranslation: showTranslation,
                            isPlaying: _playingAyahNumber == ayah.ayahNumber,
                            onTapPlay: () {
                              setState(() {
                                _playingAyahNumber =
                                    _playingAyahNumber == ayah.ayahNumber
                                        ? null
                                        : ayah.ayahNumber;
                              });
                            },
                            onTapBookmark: () {
                              context.showSuccess(
                                'تم إضافة الإشارة المرجعية',
                              );
                            },
                          );
                        },
                        childCount: ayahs.length,
                      ),
                    ),

                    // Bottom padding
                    SliverToBoxAdapter(
                      child: SizedBox(height: context.bottomPadding + 80),
                    ),
                  ],
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, _) => Center(
                child: Text('Error: $error'),
              ),
            ),

            // ── Top Controls ──
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopBar(
                  surahAsync: surahAsync,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),

            // ── Bottom Controls ──
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BottomControls(
                  fontSize: fontSize,
                  showTranslation: showTranslation,
                  onFontSizeChanged: (size) {
                    ref.read(quranFontSizeProvider.notifier).state = size;
                  },
                  onToggleTranslation: () {
                    ref.read(showTranslationProvider.notifier).state =
                        !showTranslation;
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  final String surahName;

  const _SurahHeader({required this.surahName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        surahName,
        style: AppTextStyles.surahNameArabic.copyWith(
          fontSize: 28,
          color: AppColors.primary,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final AsyncValue surahAsync;
  final VoidCallback onBack;

  const _TopBar({required this.surahAsync, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: context.topPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.quranPageBackground,
            AppColors.quranPageBackground.withValues(alpha: 0),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
            color: AppColors.textPrimaryLight,
          ),
          const Spacer(),
          surahAsync.when(
            data: (surah) => Text(
              surah.nameArabic,
              style: AppTextStyles.arabicHeadline.copyWith(
                color: AppColors.primary,
              ),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
            color: AppColors.textPrimaryLight,
          ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final double fontSize;
  final bool showTranslation;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback onToggleTranslation;

  const _BottomControls({
    required this.fontSize,
    required this.showTranslation,
    required this.onFontSizeChanged,
    required this.onToggleTranslation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: context.bottomPadding + 8,
        top: 12,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.quranPageBackground,
            AppColors.quranPageBackground.withValues(alpha: 0),
          ],
        ),
      ),
      child: Row(
        children: [
          // Font size slider
          const Icon(Icons.text_fields, size: 16, color: AppColors.textTertiaryLight),
          Expanded(
            child: Slider(
              value: fontSize,
              min: 18,
              max: 48,
              onChanged: onFontSizeChanged,
            ),
          ),
          const Icon(Icons.text_fields, size: 24, color: AppColors.textTertiaryLight),
          const SizedBox(width: 12),
          // Translation toggle
          IconButton(
            icon: Icon(
              Icons.translate,
              color: showTranslation ? AppColors.primary : AppColors.textTertiaryLight,
            ),
            onPressed: onToggleTranslation,
          ),
        ],
      ),
    );
  }
}
