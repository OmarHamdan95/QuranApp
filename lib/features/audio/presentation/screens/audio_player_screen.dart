import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/audio_providers.dart';
import '../widgets/audio_controls_widget.dart';
import '../widgets/reciter_selector.dart';

/// Full-screen audio player with:
/// - Now-playing display (surah / ayah info)
/// - Large animated reciter avatar
/// - Background playback indicator
/// - Full seek bar with time labels
/// - Play / pause / next / prev controls
/// - Repeat mode cycling (none → single ayah → range → surah)
/// - Playback speed selector
/// - Quick-select surah grid
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'الاستماع للقرآن',
          style: AppTextStyles.arabicHeadline.copyWith(
            color: AppColors.primary,
          ),
        ),
        actions: [
          if (audioState.isBackgroundPlayback)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                avatar: const Icon(
                  Icons.headphones,
                  size: 14,
                  color: Colors.white,
                ),
                label: Text(
                  'يعمل في الخلفية',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // ── Reciter avatar ───────────────────────────────────────
                  _ReciterAvatar(
                    isPlaying: audioState.isPlaying,
                    onTap: () => ReciterSelector.show(context),
                  ),

                  const SizedBox(height: 20),

                  // ── Reciter name (tappable to change) ────────────────────
                  GestureDetector(
                    onTap: () => ReciterSelector.show(context),
                    child: Column(
                      children: [
                        Row(
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
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textTertiaryLight,
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${selectedReciter.nameEnglish}  ·  ${selectedReciter.style}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (selectedReciter.country != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            selectedReciter.country!,
                            style: AppTextStyles.arabicCaption.copyWith(
                              color: AppColors.textTertiaryLight,
                              fontSize: 12,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Now-playing info ─────────────────────────────────────
                  _NowPlayingCard(state: audioState, isDark: isDark),

                  const SizedBox(height: 24),

                  // ── Surah quick-select ────────────────────────────────────
                  _SurahQuickSelect(
                    currentSurahNumber: audioState.currentSurahNumber,
                    onSurahSelected: (number) {
                      ref.read(audioPlayerProvider.notifier).playSurah(number);
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Full audio controls bar ────────────────────────────────────
          const AudioControlsWidget(),
          SizedBox(height: context.bottomPadding),
        ],
      ),
    );
  }
}

// ── Reciter avatar ─────────────────────────────────────────────────────────

class _ReciterAvatar extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _ReciterAvatar({required this.isPlaying, required this.onTap});

  @override
  State<_ReciterAvatar> createState() => _ReciterAvatarState();
}

class _ReciterAvatarState extends State<_ReciterAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isPlaying) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_ReciterAvatar old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.animateTo(0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _pulseAnim,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryLight,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: widget.isPlaying ? 28 : 14,
                spreadRadius: widget.isPlaying ? 4 : 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 68,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Now-playing card ───────────────────────────────────────────────────────

class _NowPlayingCard extends StatelessWidget {
  final AudioPlayerState state;
  final bool isDark;

  const _NowPlayingCard({required this.state, required this.isDark});

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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariantLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Text(
          'اختر سورة للاستماع',
          style: AppTextStyles.arabicBody.copyWith(
            color: AppColors.textTertiaryLight,
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (state.hasError) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.errorMessage ?? 'حدث خطأ',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final surahNumber = state.currentSurahNumber;
    final surahName =
        surahNumber != null ? _surahNames[surahNumber] ?? 'سورة $surahNumber' : '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Surah name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                const Icon(
                  Icons.music_note_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              const SizedBox(width: 8),
              Text(
                'سورة $surahName',
                style: AppTextStyles.arabicBody.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
                textDirection: TextDirection.rtl,
              ),
              if (surahNumber != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
              ],
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _repeatLabel(state.repeatMode, state),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.secondaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
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

// ── Surah quick-select ─────────────────────────────────────────────────────

class _SurahQuickSelect extends StatelessWidget {
  final int? currentSurahNumber;
  final ValueChanged<int> onSurahSelected;

  const _SurahQuickSelect({
    required this.currentSurahNumber,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'سور مقترحة',
            style: AppTextStyles.arabicCaption.copyWith(
              color: AppColors.textTertiaryLight,
              fontWeight: FontWeight.w700,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: _popularSurahs.map((entry) {
            final (number, name) = entry;
            final isActive = currentSurahNumber == number;
            return ActionChip(
              backgroundColor: isActive
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.06),
              side: BorderSide(
                color: isActive
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.2),
              ),
              label: Text(
                name,
                style: AppTextStyles.arabicCaption.copyWith(
                  color: isActive ? Colors.white : AppColors.primary,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              onPressed: () => onSurahSelected(number),
              avatar: CircleAvatar(
                radius: 10,
                backgroundColor: isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  number.toString(),
                  style: TextStyle(
                    fontSize: 9,
                    color: isActive ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
