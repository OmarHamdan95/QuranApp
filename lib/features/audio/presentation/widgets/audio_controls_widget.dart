import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/audio_providers.dart';

/// Reusable audio playback controls with play/pause, seek bar,
/// speed control, and repeat toggle.
class AudioControlsWidget extends ConsumerWidget {
  final bool compact;

  const AudioControlsWidget({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final audioNotifier = ref.read(audioPlayerProvider.notifier);
    final isDark = context.isDarkMode;

    if (compact) {
      return _CompactControls(
        state: audioState,
        notifier: audioNotifier,
        isDark: isDark,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
              thumbColor: AppColors.primary,
            ),
            child: Slider(
              value: audioState.progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final position = Duration(
                  milliseconds: (value * audioState.duration.inMilliseconds).round(),
                );
                audioNotifier.seekTo(position);
              },
            ),
          ),

          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  audioState.position.formatted,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryLight,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  audioState.duration.formatted,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryLight,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Main controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Repeat toggle
              IconButton(
                icon: Icon(
                  audioState.isRepeatOn
                      ? Icons.repeat_one
                      : Icons.repeat,
                  color: audioState.isRepeatOn
                      ? AppColors.primary
                      : AppColors.textTertiaryLight,
                ),
                onPressed: () => audioNotifier.toggleRepeat(),
              ),

              // Previous
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, size: 32),
                onPressed: () {
                  // TODO: Previous surah/ayah
                },
              ),

              // Play/Pause
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: audioState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Icon(
                          audioState.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                  onPressed: () {
                    if (audioState.isPlaying) {
                      audioNotifier.pause();
                    } else if (audioState.isPaused) {
                      audioNotifier.resume();
                    }
                  },
                ),
              ),

              // Next
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, size: 32),
                onPressed: () {
                  // TODO: Next surah/ayah
                },
              ),

              // Speed
              _SpeedButton(
                currentSpeed: audioState.playbackSpeed,
                onSpeedChanged: audioNotifier.setPlaybackSpeed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactControls extends StatelessWidget {
  final AudioPlayerState state;
  final AudioPlayerNotifier notifier;
  final bool isDark;

  const _CompactControls({
    required this.state,
    required this.notifier,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppColors.primary,
            ),
            onPressed: () {
              if (state.isPlaying) {
                notifier.pause();
              } else {
                notifier.resume();
              }
            },
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: state.progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.stop_rounded, color: AppColors.textTertiaryLight),
            onPressed: () => notifier.stop(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
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
        final currentIndex = _speeds.indexOf(currentSpeed);
        final nextIndex = (currentIndex + 1) % _speeds.length;
        onSpeedChanged(_speeds[nextIndex]);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textTertiaryLight),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${currentSpeed}x',
          style: AppTextStyles.labelSmall.copyWith(
            color: currentSpeed != 1.0
                ? AppColors.primary
                : AppColors.textTertiaryLight,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
