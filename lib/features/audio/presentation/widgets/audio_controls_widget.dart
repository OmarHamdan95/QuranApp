import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/audio_providers.dart';

/// Full-featured playback controls panel shown at the bottom of the
/// [AudioPlayerScreen].
///
/// Modern design with:
/// - Smooth rounded seek bar with time labels
/// - Centered play/pause with skip buttons
/// - Repeat mode cycling and speed selector
/// - Elevated rounded container with subtle shadow
class AudioControlsWidget extends ConsumerWidget {
  const AudioControlsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final notifier = ref.read(audioPlayerProvider.notifier);
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ─────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Seek bar ────────────────────────────────────────────────
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              trackShape: const RoundedRectSliderTrackShape(),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor:
                  AppColors.primary.withValues(alpha: 0.15),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: audioState.progress,
              onChanged: audioState.isIdle
                  ? null
                  : (value) {
                      final pos = Duration(
                        milliseconds:
                            (value * audioState.duration.inMilliseconds)
                                .round(),
                      );
                      notifier.seekTo(pos);
                    },
            ),
          ),

          // ── Time labels ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TimeLabel(audioState.position, isDark: isDark),
                _TimeLabel(audioState.duration, isDark: isDark),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Main controls row ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Repeat cycle
              _RepeatButton(
                mode: audioState.repeatMode,
                onTap: notifier.cycleRepeatMode,
              ),

              // Previous
              _ControlCircle(
                icon: Icons.skip_previous_rounded,
                size: 28,
                circleSize: 48,
                isDark: isDark,
                onTap: audioState.isIdle ? null : notifier.skipToPrevious,
              ),

              // Play / Pause
              _PlayPauseButton(state: audioState, notifier: notifier),

              // Next
              _ControlCircle(
                icon: Icons.skip_next_rounded,
                size: 28,
                circleSize: 48,
                isDark: isDark,
                onTap: audioState.isIdle ? null : notifier.skipToNext,
              ),

              // Speed
              _SpeedButton(
                currentSpeed: audioState.playbackSpeed,
                isDark: isDark,
                onSpeedChanged: notifier.setPlaybackSpeed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Mini player bar ──────────────────────────────────────────────────────────

/// Compact mini-player bar to be embedded at the bottom of other screens
/// (e.g. Quran reader). Only visible when audio is active.
class AudioMiniPlayerBar extends ConsumerWidget {
  const AudioMiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final notifier = ref.read(audioPlayerProvider.notifier);
    final isDark = context.isDarkMode;

    if (audioState.isIdle) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Surah label
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  audioState.currentSurahNumber != null
                      ? 'سورة ${audioState.currentSurahNumber}'
                      : 'جارٍ التشغيل',
                  style: AppTextStyles.arabicCaption.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Prev
              _MiniControlButton(
                icon: Icons.skip_previous_rounded,
                onTap: notifier.skipToPrevious,
              ),

              // Play / Pause
              GestureDetector(
                onTap: () {
                  if (audioState.isPlaying) {
                    notifier.pause();
                  } else {
                    notifier.resume();
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: audioState.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          audioState.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),

              // Next
              _MiniControlButton(
                icon: Icons.skip_next_rounded,
                onTap: notifier.skipToNext,
              ),

              // Stop
              _MiniControlButton(
                icon: Icons.stop_rounded,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
                onTap: notifier.stop,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Mini progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: audioState.progress,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _TimeLabel extends StatelessWidget {
  final Duration duration;
  final bool isDark;

  const _TimeLabel(this.duration, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      duration.formatted,
      style: AppTextStyles.labelSmall.copyWith(
        color: isDark
            ? AppColors.textTertiaryDark
            : AppColors.textTertiaryLight,
        fontFeatures: [const FontFeature.tabularFigures()],
      ),
    );
  }
}

class _ControlCircle extends StatelessWidget {
  final IconData icon;
  final double size;
  final double circleSize;
  final bool isDark;
  final VoidCallback? onTap;

  const _ControlCircle({
    required this.icon,
    required this.size,
    required this.circleSize,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariantLight,
        ),
        child: Icon(
          icon,
          size: size,
          color: isDisabled
              ? (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight)
                  .withValues(alpha: 0.3)
              : isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}

class _MiniControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniControlButton({
    required this.icon,
    this.color = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: color,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final AudioPlayerState state;
  final AudioPlayerNotifier notifier;

  const _PlayPauseButton({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (state.isPlaying) {
          notifier.pause();
        } else if (state.isPaused) {
          notifier.resume();
        }
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: state.isLoading
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Icon(
                state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 38,
              ),
      ),
    );
  }
}

class _RepeatButton extends StatelessWidget {
  final RepeatMode mode;
  final VoidCallback onTap;

  const _RepeatButton({required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final bool isActive;

    switch (mode) {
      case RepeatMode.none:
        icon = Icons.repeat_rounded;
        color = AppColors.textTertiaryLight;
        isActive = false;
      case RepeatMode.singleAyah:
        icon = Icons.repeat_one_rounded;
        color = AppColors.primary;
        isActive = true;
      case RepeatMode.range:
        icon = Icons.repeat_on_rounded;
        color = AppColors.secondary;
        isActive = true;
      case RepeatMode.surah:
        icon = Icons.repeat_rounded;
        color = AppColors.primary;
        isActive = true;
    }

    return Tooltip(
      message: _tooltip(mode),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }

  String _tooltip(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.none:
        return 'لا تكرار';
      case RepeatMode.singleAyah:
        return 'تكرار الآية';
      case RepeatMode.range:
        return 'تكرار النطاق';
      case RepeatMode.surah:
        return 'تكرار السورة';
    }
  }
}

class _SpeedButton extends StatelessWidget {
  final double currentSpeed;
  final bool isDark;
  final ValueChanged<double> onSpeedChanged;

  const _SpeedButton({
    required this.currentSpeed,
    required this.isDark,
    required this.onSpeedChanged,
  });

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final isNonDefault = currentSpeed != 1.0;
    return GestureDetector(
      onTap: () {
        final idx = _speeds.indexOf(currentSpeed);
        final next = _speeds[(idx + 1) % _speeds.length];
        onSpeedChanged(next);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isNonDefault
              ? AppColors.primary.withValues(alpha: 0.12)
              : isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${currentSpeed}x',
          style: AppTextStyles.labelSmall.copyWith(
            color: isNonDefault
                ? AppColors.primary
                : isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
            fontWeight:
                isNonDefault ? FontWeight.w700 : FontWeight.w500,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
