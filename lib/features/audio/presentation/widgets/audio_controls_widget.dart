import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/audio_providers.dart';

/// Full-featured playback controls panel shown at the bottom of the
/// [AudioPlayerScreen].
///
/// For other screens, use [AudioMiniPlayerBar] — a compact floating bar
/// that only shows when audio is active.
class AudioControlsWidget extends ConsumerWidget {
  const AudioControlsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final notifier = ref.read(audioPlayerProvider.notifier);
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ─────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
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
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.18),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
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
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TimeLabel(audioState.position),
                _TimeLabel(audioState.duration),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Main controls row ────────────────────────────────────────
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
              _ControlButton(
                icon: Icons.skip_previous_rounded,
                size: 30,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                onTap: audioState.isIdle ? null : notifier.skipToPrevious,
              ),

              // Play / Pause
              _PlayPauseButton(state: audioState, notifier: notifier),

              // Next
              _ControlButton(
                icon: Icons.skip_next_rounded,
                size: 30,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                onTap: audioState.isIdle ? null : notifier.skipToNext,
              ),

              // Speed
              _SpeedButton(
                currentSpeed: audioState.playbackSpeed,
                onSpeedChanged: notifier.setPlaybackSpeed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Mini player bar ────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Reciter / surah label
              const Icon(
                Icons.music_note_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
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
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
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
                color: AppColors.textTertiaryLight,
                onTap: notifier.stop,
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Mini progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: audioState.progress,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _TimeLabel extends StatelessWidget {
  final Duration duration;
  const _TimeLabel(this.duration);

  @override
  Widget build(BuildContext context) {
    return Text(
      duration.formatted,
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textTertiaryLight,
        fontFeatures: [const FontFeature.tabularFigures()],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: size),
      color: onTap == null ? color.withValues(alpha: 0.35) : color,
      onPressed: onTap,
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
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
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
                size: 40,
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
    IconData icon;
    Color color;

    switch (mode) {
      case RepeatMode.none:
        icon = Icons.repeat_rounded;
        color = AppColors.textTertiaryLight;
      case RepeatMode.singleAyah:
        icon = Icons.repeat_one_rounded;
        color = AppColors.primary;
      case RepeatMode.range:
        icon = Icons.repeat_on_rounded;
        color = AppColors.secondary;
      case RepeatMode.surah:
        icon = Icons.repeat_rounded;
        color = AppColors.primary;
    }

    return Tooltip(
      message: _tooltip(mode),
      child: IconButton(
        icon: Icon(icon, size: 24),
        color: color,
        onPressed: onTap,
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
  final ValueChanged<double> onSpeedChanged;

  const _SpeedButton({
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final idx = _speeds.indexOf(currentSpeed);
        final next = _speeds[(idx + 1) % _speeds.length];
        onSpeedChanged(next);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: currentSpeed != 1.0
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: currentSpeed != 1.0
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.textTertiaryLight.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${currentSpeed}x',
          style: AppTextStyles.labelSmall.copyWith(
            color: currentSpeed != 1.0
                ? AppColors.primary
                : AppColors.textTertiaryLight,
            fontWeight:
                currentSpeed != 1.0 ? FontWeight.w700 : FontWeight.w500,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
