import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/quran_providers.dart';
import '../widgets/ayah_widget.dart';

/// Full-screen Quran reading experience.
///
/// Features:
/// - Continuous scroll (surah mode) with individual ayah rendering
/// - Auto-saves last-read position as the user scrolls
/// - Ayah highlighting (tapping an ayah highlights it)
/// - Adjustable Arabic font size via bottom slider
/// - Translation / tafsir toggles
/// - Immersive edge-to-edge display with overlay controls
class QuranReaderScreen extends ConsumerStatefulWidget {
  final int surahNumber;
  final int? initialAyah;

  const QuranReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
  });

  @override
  ConsumerState<QuranReaderScreen> createState() =>
      _QuranReaderScreenState();
}

class _QuranReaderScreenState extends ConsumerState<QuranReaderScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _showControls = true;
  int? _playingAyahNumber;
  int? _highlightedAyahNumber;

  // Track the approximate "current" ayah from scroll position.
  int _visibleAyahIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Restore scroll to initial ayah after first frame.
    if (widget.initialAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToAyah(widget.initialAyah!);
      });
    }

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveCurrentPosition();
    }
  }

  void _onScroll() {
    // Estimate which ayah index is at the top of the viewport.
    // Each ayah is roughly 140 dp tall on average.
    const estimatedAyahHeight = 140.0;
    final headerOffset = 200.0; // header + bismillah height estimate
    final offset = _scrollController.offset - headerOffset;
    if (offset > 0) {
      final newIndex =
          (offset / estimatedAyahHeight).floor().clamp(0, 9999);
      if (newIndex != _visibleAyahIndex) {
        _visibleAyahIndex = newIndex;
        // Debounced save — save every 5 ayahs scrolled.
        if (_visibleAyahIndex % 5 == 0) {
          _saveCurrentPosition();
        }
      }
    }
  }

  void _scrollToAyah(int ayahNumber) {
    // Approximate scroll offset for the target ayah.
    const estimatedAyahHeight = 140.0;
    const headerOffset = 200.0;
    final offset = headerOffset + (ayahNumber - 1) * estimatedAyahHeight;
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _saveCurrentPosition() {
    final ayahsAsync =
        ref.read(ayahsBySurahProvider(widget.surahNumber));
    ayahsAsync.whenData((ayahs) {
      if (ayahs.isEmpty) return;
      final idx = _visibleAyahIndex.clamp(0, ayahs.length - 1);
      final ayah = ayahs[idx];
      ref.read(lastReadPositionProvider.notifier).save(
            surahNumber: widget.surahNumber,
            ayahNumber: ayah.ayahNumber,
            page: ayah.page,
          );
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _toggleAyahHighlight(int ayahNumber) {
    setState(() {
      _highlightedAyahNumber =
          _highlightedAyahNumber == ayahNumber ? null : ayahNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final surahAsync =
        ref.watch(surahProvider(widget.surahNumber));
    final ayahsAsync =
        ref.watch(ayahsBySurahProvider(widget.surahNumber));
    final fontSize = ref.watch(quranFontSizeProvider);
    final showTranslation = ref.watch(showTranslationProvider);
    final isDark = context.isDarkMode;

    final bgColor = isDark
        ? AppColors.quranPageBackgroundDark
        : AppColors.quranPageBackground;

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // ── Main Ayah List ────────────────────────────────────────
            ayahsAsync.when(
              data: (ayahs) {
                return CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                          height: context.topPadding + 64),
                    ),

                    // Surah decorative header
                    surahAsync.when(
                      data: (surah) => SliverToBoxAdapter(
                        child: _SurahHeader(
                          surahName: surah.nameArabic,
                          surahNameEnglish: surah.nameEnglish,
                          ayahCount: surah.ayahCount,
                          revelationType: surah.revelationType,
                          isDark: isDark,
                        ),
                      ),
                      loading: () =>
                          const SliverToBoxAdapter(child: SizedBox()),
                      error: (_, __) =>
                          const SliverToBoxAdapter(child: SizedBox()),
                    ),

                    // Bismillah (except At-Tawbah #9 and Al-Fatihah #1
                    // which already begins with bismillah as verse 1)
                    if (widget.surahNumber != 9 &&
                        widget.surahNumber != 1)
                      SliverToBoxAdapter(
                        child: _BismillahBanner(
                          isDark: isDark,
                        ),
                      ),

                    // Ayahs list
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final ayah = ayahs[index];
                          final isHighlighted =
                              _highlightedAyahNumber ==
                                  ayah.ayahNumber;
                          final isPlaying =
                              _playingAyahNumber == ayah.ayahNumber;

                          return AyahWidget(
                            ayah: ayah,
                            fontSize: fontSize,
                            showTranslation: showTranslation,
                            isHighlighted: isHighlighted,
                            isPlaying: isPlaying,
                            onTapPlay: () {
                              setState(() {
                                _playingAyahNumber =
                                    isPlaying ? null : ayah.ayahNumber;
                              });
                            },
                            onTapBookmark: () {
                              ref
                                  .read(bookmarkedAyahsProvider.notifier)
                                  .toggle(
                                    surahNumber: ayah.surahNumber,
                                    ayahNumber: ayah.ayahNumber,
                                    page: ayah.page,
                                  );
                              context.showSuccess(
                                isHighlighted
                                    ? 'تمت إزالة الإشارة المرجعية'
                                    : 'تم حفظ الإشارة المرجعية',
                              );
                            },
                            onTapTafsir: () {
                              context.pushNamed(
                                RouteNames.tafsir,
                                pathParameters: {
                                  'surahNumber':
                                      ayah.surahNumber.toString(),
                                  'ayahNumber':
                                      ayah.ayahNumber.toString(),
                                },
                              );
                            },
                            onTapShare: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text:
                                      '${ayah.textUthmani}\n\n— ${ayah.reference}',
                                ),
                              );
                              context.showSuccess('تم نسخ الآية');
                            },
                            onTap: () =>
                                _toggleAyahHighlight(ayah.ayahNumber),
                          );
                        },
                        childCount: ayahs.length,
                      ),
                    ),

                    // Bottom safe area padding
                    SliverToBoxAdapter(
                      child: SizedBox(
                          height: context.bottomPadding + 100),
                    ),
                  ],
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 56,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'تعذّر تحميل السورة\n$error',
                        style: AppTextStyles.arabicBody.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(
                            ayahsBySurahProvider(widget.surahNumber)),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Top Controls Overlay ──────────────────────────────────
            AnimatedSlide(
              offset: _showControls
                  ? Offset.zero
                  : const Offset(0, -1),
              duration: AppConstants.animNormal,
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: AppConstants.animNormal,
                child: _TopBar(
                  surahAsync: surahAsync,
                  onBack: () => context.pop(),
                  isDark: isDark,
                ),
              ),
            ),

            // ── Bottom Controls Overlay ───────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                offset: _showControls
                    ? Offset.zero
                    : const Offset(0, 1),
                duration: AppConstants.animNormal,
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: AppConstants.animNormal,
                  child: _BottomControls(
                    fontSize: fontSize,
                    showTranslation: showTranslation,
                    isDark: isDark,
                    onFontSizeChanged: (size) {
                      ref
                          .read(quranFontSizeProvider.notifier)
                          .setSize(size);
                    },
                    onToggleTranslation: () {
                      ref
                          .read(showTranslationProvider.notifier)
                          .toggle();
                    },
                    bgColor: bgColor,
                    bottomPadding: context.bottomPadding,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Surah Decorative Header ───────────────────────────────────────────────────

class _SurahHeader extends StatelessWidget {
  final String surahName;
  final String surahNameEnglish;
  final int ayahCount;
  final String revelationType;
  final bool isDark;

  const _SurahHeader({
    required this.surahName,
    required this.surahNameEnglish,
    required this.ayahCount,
    required this.revelationType,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isMeccan = revelationType == 'Meccan';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding:
          const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
            AppColors.secondary.withValues(alpha: isDark ? 0.1 : 0.04),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Arabic name
          Text(
            surahName,
            style: AppTextStyles.surahNameArabic.copyWith(
              fontSize: 32,
              color: isDark
                  ? AppColors.quranTextColorDark
                  : AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),

          // English name
          Text(
            surahNameEnglish,
            style: AppTextStyles.titleSmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Metadata pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SurahPill(
                label:
                    '$ayahCount آية',
                color: AppColors.primary,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _SurahPill(
                label: isMeccan ? 'مكية' : 'مدنية',
                color:
                    isMeccan ? AppColors.secondary : AppColors.tertiary,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SurahPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _SurahPill({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.arabicCaption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

// ── Bismillah Banner ──────────────────────────────────────────────────────────

class _BismillahBanner extends StatelessWidget {
  final bool isDark;

  const _BismillahBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      child: Column(
        children: [
          // Decorative divider
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.star_rounded,
                  size: 14,
                  color:
                      AppColors.secondary.withValues(alpha: 0.6),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.bismillah,
            style: AppTextStyles.bismillah.copyWith(
              color: isDark
                  ? AppColors.primaryLight
                  : AppColors.primary,
              fontSize: 30,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.star_rounded,
                  size: 14,
                  color:
                      AppColors.secondary.withValues(alpha: 0.6),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final AsyncValue surahAsync;
  final VoidCallback onBack;
  final bool isDark;

  const _TopBar({
    required this.surahAsync,
    required this.onBack,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? AppColors.quranPageBackgroundDark
        : AppColors.quranPageBackground;

    return Container(
      padding: EdgeInsets.only(top: context.topPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bgColor,
            bgColor.withValues(alpha: 0.95),
            bgColor.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: onBack,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          const Spacer(),
          surahAsync.when(
            data: (surah) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  surah.nameArabic,
                  style: AppTextStyles.arabicHeadline.copyWith(
                    color: isDark
                        ? AppColors.primaryLight
                        : AppColors.primary,
                    fontSize: 20,
                  ),
                ),
                Text(
                  surah.nameEnglish,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onPressed: () {},
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ],
      ),
    );
  }
}

// ── Bottom Controls ───────────────────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  final double fontSize;
  final bool showTranslation;
  final bool isDark;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback onToggleTranslation;
  final Color bgColor;
  final double bottomPadding;

  const _BottomControls({
    required this.fontSize,
    required this.showTranslation,
    required this.isDark,
    required this.onFontSizeChanged,
    required this.onToggleTranslation,
    required this.bgColor,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: bottomPadding + 12,
        top: 12,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            bgColor,
            bgColor.withValues(alpha: 0.95),
            bgColor.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Font size row
          Row(
            children: [
              const Icon(
                Icons.text_fields_rounded,
                size: 16,
                color: AppColors.textTertiaryLight,
              ),
              Expanded(
                child: Slider(
                  value: fontSize,
                  min: AppConstants.minFontSize,
                  max: AppConstants.maxFontSize,
                  divisions: 15,
                  activeColor: AppColors.primary,
                  inactiveColor:
                      AppColors.primary.withValues(alpha: 0.2),
                  onChanged: onFontSizeChanged,
                ),
              ),
              const Icon(
                Icons.text_fields_rounded,
                size: 24,
                color: AppColors.textTertiaryLight,
              ),
              const SizedBox(width: 12),

              // Translation toggle
              _ControlButton(
                icon: Icons.translate_rounded,
                isActive: showTranslation,
                label: 'ترجمة',
                onTap: onToggleTranslation,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ControlButton({
    required this.icon,
    required this.isActive,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  isActive ? AppColors.primary : AppColors.textTertiaryLight,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive
                    ? AppColors.primary
                    : AppColors.textTertiaryLight,
                fontFamily: 'Amiri',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
