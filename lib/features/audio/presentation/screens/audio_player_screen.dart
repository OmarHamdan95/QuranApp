import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/audio_providers.dart';
import '../widgets/audio_controls_widget.dart';
import '../widgets/reciter_selector.dart';

/// Full-screen audio player with modern music-player style design:
/// - Large artwork/surah info area at top with animated visualizer
/// - Reciter name display with selector
/// - Now-playing surah/ayah info
/// - Full playback controls at the bottom
class AudioPlayerScreen extends ConsumerWidget {
  const AudioPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final selectedReciter = ref.watch(selectedReciterProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 28,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'الاستماع للقرآن',
                    style: AppTextStyles.arabicBody.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  if (audioState.isBackgroundPlayback)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.headphones_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'الخلفية',
                            style: AppTextStyles.arabicCaption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),

            // ── Scrollable content ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // ── Large artwork area ───────────────────────────
                    _ArtworkArea(
                      audioState: audioState,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 32),

                    // ── Now-playing info ─────────────────────────────
                    _NowPlayingInfo(
                      state: audioState,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 12),

                    // ── Reciter selector pill ─────────────────────────
                    GestureDetector(
                      onTap: () => ReciterSelector.show(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceVariantLight,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                Text(
                                  selectedReciter.nameArabic,
                                  style:
                                      AppTextStyles.arabicCaption.copyWith(
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                Text(
                                  '${selectedReciter.nameEnglish}  ·  ${selectedReciter.style}',
                                  style:
                                      AppTextStyles.bodySmall.copyWith(
                                    color: isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiaryLight,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryLight,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Surah quick-select ────────────────────────────
                    _SurahQuickSelect(
                      currentSurahNumber: audioState.currentSurahNumber,
                      isDark: isDark,
                      onSurahSelected: (number) {
                        ref
                            .read(audioPlayerProvider.notifier)
                            .playSurah(number);
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Full audio controls bar ──────────────────────────────
            const AudioControlsWidget(),
            SizedBox(height: context.bottomPadding),
          ],
        ),
      ),
    );
  }
}

// ── Large artwork/visualizer area ────────────────────────────────────────────

class _ArtworkArea extends StatefulWidget {
  final AudioPlayerState audioState;
  final bool isDark;

  const _ArtworkArea({required this.audioState, required this.isDark});

  @override
  State<_ArtworkArea> createState() => _ArtworkAreaState();
}

class _ArtworkAreaState extends State<_ArtworkArea>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  late final AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    if (widget.audioState.isPlaying) {
      _pulseController.repeat(reverse: true);
      _rotateController.repeat();
    }
  }

  @override
  void didUpdateWidget(_ArtworkArea old) {
    super.didUpdateWidget(old);
    if (widget.audioState.isPlaying != old.audioState.isPlaying) {
      if (widget.audioState.isPlaying) {
        _pulseController.repeat(reverse: true);
        _rotateController.repeat();
      } else {
        _pulseController.stop();
        _pulseController.animateTo(0);
        _rotateController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.audioState.isPlaying;

    return AnimatedBuilder(
      listenable: Listenable.merge([_pulseController, _rotateController]),
      builder: (context, child) {
        return Transform.scale(
          scale: isPlaying ? _pulseAnim.value : 1.0,
          child: SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary
                          .withValues(alpha: isPlaying ? 0.15 : 0.06),
                      width: 2,
                    ),
                  ),
                ),
                // Middle ring
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryLight
                          .withValues(alpha: isPlaying ? 0.2 : 0.08),
                      width: 1.5,
                    ),
                  ),
                ),
                // Rotating dots ring (only when playing)
                if (isPlaying)
                  RotationTransition(
                    turns: _rotateController,
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: _GlowDot(
                                color: AppColors.secondaryLight, size: 8),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child:
                                _GlowDot(color: AppColors.primary, size: 6),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: _GlowDot(
                                color: AppColors.primaryLight, size: 7),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Main circle
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: isPlaying ? 0.45 : 0.2),
                        blurRadius: isPlaying ? 36 : 16,
                        spreadRadius: isPlaying ? 2 : 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPlaying
                            ? Icons.graphic_eq_rounded
                            : Icons.auto_stories_rounded,
                        size: 52,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'القرآن الكريم',
                        style: AppTextStyles.arabicCaption.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlowDot extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}

/// Helper widget that rebuilds when a Listenable changes.
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context, null);
}

// ── Now-playing info ─────────────────────────────────────────────────────────

class _NowPlayingInfo extends StatelessWidget {
  final AudioPlayerState state;
  final bool isDark;

  const _NowPlayingInfo({required this.state, required this.isDark});

  static const _surahNames = {
    1: 'الفاتحة', 2: 'البقرة', 3: 'آل عمران', 4: 'النساء',
    5: 'المائدة', 6: 'الأنعام', 7: 'الأعراف', 8: 'الأنفال',
    9: 'التوبة', 10: 'يونس', 11: 'هود', 12: 'يوسف',
    13: 'الرعد', 14: 'إبراهيم', 15: 'الحجر', 16: 'النحل',
    17: 'الإسراء', 18: 'الكهف', 19: 'مريم', 20: 'طه',
    21: 'الأنبياء', 22: 'الحج', 23: 'المؤمنون', 24: 'النور',
    25: 'الفرقان', 26: 'الشعراء', 27: 'النمل', 28: 'القصص',
    29: 'العنكبوت', 30: 'الروم', 31: 'لقمان', 32: 'السجدة',
    33: 'الأحزاب', 34: 'سبأ', 35: 'فاطر', 36: 'يس',
    37: 'الصافات', 38: 'ص', 39: 'الزمر', 40: 'غافر',
    41: 'فصلت', 42: 'الشورى', 43: 'الزخرف', 44: 'الدخان',
    45: 'الجاثية', 46: 'الأحقاف', 47: 'محمد', 48: 'الفتح',
    49: 'الحجرات', 50: 'ق', 51: 'الذاريات', 52: 'الطور',
    53: 'النجم', 54: 'القمر', 55: 'الرحمن', 56: 'الواقعة',
    57: 'الحديد', 58: 'المجادلة', 59: 'الحشر', 60: 'الممتحنة',
    61: 'الصف', 62: 'الجمعة', 63: 'المنافقون', 64: 'التغابن',
    65: 'الطلاق', 66: 'التحريم', 67: 'الملك', 68: 'القلم',
    69: 'الحاقة', 70: 'المعارج', 71: 'نوح', 72: 'الجن',
    73: 'المزمل', 74: 'المدثر', 75: 'القيامة', 76: 'الإنسان',
    77: 'المرسلات', 78: 'النبأ', 79: 'النازعات', 80: 'عبس',
    81: 'التكوير', 82: 'الانفطار', 83: 'المطففين', 84: 'الانشقاق',
    85: 'البروج', 86: 'الطارق', 87: 'الأعلى', 88: 'الغاشية',
    89: 'الفجر', 90: 'البلد', 91: 'الشمس', 92: 'الليل',
    93: 'الضحى', 94: 'الشرح', 95: 'التين', 96: 'العلق',
    97: 'القدر', 98: 'البينة', 99: 'الزلزلة', 100: 'العاديات',
    101: 'القارعة', 102: 'التكاثر', 103: 'العصر', 104: 'الهمزة',
    105: 'الفيل', 106: 'قريش', 107: 'الماعون', 108: 'الكوثر',
    109: 'الكافرون', 110: 'النصر', 111: 'المسد', 112: 'الإخلاص',
    113: 'الفلق', 114: 'الناس',
  };

  @override
  Widget build(BuildContext context) {
    if (state.isIdle && state.currentSurahNumber == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'اختر سورة للاستماع',
          style: AppTextStyles.arabicBody.copyWith(
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
            fontSize: 16,
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (state.hasError) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                state.errorMessage ?? 'حدث خطأ',
                style: AppTextStyles.arabicCaption.copyWith(
                  color: AppColors.error,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 18),
          ],
        ),
      );
    }

    final surahNumber = state.currentSurahNumber;
    final surahName = surahNumber != null
        ? _surahNames[surahNumber] ?? 'سورة $surahNumber'
        : '—';

    return Column(
      children: [
        // Surah name + number badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            if (surahNumber != null)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$surahNumber',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Text(
              'سورة $surahName',
              style: AppTextStyles.arabicHeadline.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontSize: 24,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),

        if (state.currentAyahNumber != null) ...[
          const SizedBox(height: 4),
          Text(
            'الآية ${state.currentAyahNumber}',
            style: AppTextStyles.arabicCaption.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],

        // Repeat-mode badge
        if (state.repeatMode != RepeatMode.none) ...[
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _repeatLabel(state.repeatMode, state),
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: AppColors.secondaryDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.repeat_rounded,
                    size: 14, color: AppColors.secondaryDark),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _repeatLabel(RepeatMode mode, AudioPlayerState state) {
    switch (mode) {
      case RepeatMode.none:
        return '';
      case RepeatMode.singleAyah:
        return 'تكرار الآية';
      case RepeatMode.range:
        return 'تكرار (${state.repeatRangeStart}–${state.repeatRangeEnd})';
      case RepeatMode.surah:
        return 'تكرار السورة';
    }
  }
}

// ── Surah quick-select ───────────────────────────────────────────────────────

class _SurahQuickSelect extends StatelessWidget {
  final int? currentSurahNumber;
  final bool isDark;
  final ValueChanged<int> onSurahSelected;

  const _SurahQuickSelect({
    required this.currentSurahNumber,
    required this.isDark,
    required this.onSurahSelected,
  });

  static const _popularSurahs = [
    (1, 'الفاتحة'),
    (2, 'البقرة'),
    (18, 'الكهف'),
    (36, 'يس'),
    (55, 'الرحمن'),
    (56, 'الواقعة'),
    (67, 'الملك'),
    (73, 'المزمل'),
    (78, 'النبأ'),
    (87, 'الأعلى'),
    (112, 'الإخلاص'),
    (113, 'الفلق'),
    (114, 'الناس'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.queue_music_rounded,
                size: 18,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
              Text(
                'سور مقترحة',
                style: AppTextStyles.arabicBody.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: _popularSurahs.map((entry) {
              final (number, name) = entry;
              final isActive = currentSurahNumber == number;
              return GestureDetector(
                onTap: () => onSurahSelected(number),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(12),
                    border: isActive
                        ? null
                        : Border.all(
                            color: isDark
                                ? AppColors.dividerDark
                                : AppColors.dividerLight,
                            width: 0.5,
                          ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.arabicCaption.copyWith(
                          color: isActive
                              ? Colors.white
                              : isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.25)
                              : AppColors.primary
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          number.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive
                                ? Colors.white
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
