import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/reciter_model.dart';
import '../../data/repositories/audio_repository_impl.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/repositories/audio_repository.dart';

/// Provider for the audio repository.
final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  return AudioRepositoryImpl();
});

/// Fetches the list of available reciters.
final recitersProvider = FutureProvider<List<Reciter>>((ref) async {
  final repository = ref.watch(audioRepositoryProvider);
  final result = await repository.getReciters();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (reciters) => reciters,
  );
});

/// The currently selected reciter.
final selectedReciterProvider = StateProvider<Reciter>((ref) {
  return ReciterModel.popularReciters.first;
});

/// Playback state management.
enum PlaybackState { idle, loading, playing, paused, error }

class AudioPlayerState {
  final PlaybackState state;
  final int? currentSurahNumber;
  final int? currentAyahNumber;
  final Duration position;
  final Duration duration;
  final double playbackSpeed;
  final bool isRepeatOn;
  final String? errorMessage;

  const AudioPlayerState({
    this.state = PlaybackState.idle,
    this.currentSurahNumber,
    this.currentAyahNumber,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.isRepeatOn = false,
    this.errorMessage,
  });

  double get progress =>
      duration.inMilliseconds > 0
          ? position.inMilliseconds / duration.inMilliseconds
          : 0.0;

  bool get isPlaying => state == PlaybackState.playing;
  bool get isPaused => state == PlaybackState.paused;
  bool get isLoading => state == PlaybackState.loading;

  AudioPlayerState copyWith({
    PlaybackState? state,
    int? currentSurahNumber,
    int? currentAyahNumber,
    Duration? position,
    Duration? duration,
    double? playbackSpeed,
    bool? isRepeatOn,
    String? errorMessage,
  }) {
    return AudioPlayerState(
      state: state ?? this.state,
      currentSurahNumber: currentSurahNumber ?? this.currentSurahNumber,
      currentAyahNumber: currentAyahNumber ?? this.currentAyahNumber,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isRepeatOn: isRepeatOn ?? this.isRepeatOn,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Notifier for audio playback state.
class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final AudioRepository _repository;
  final Reciter _reciter;

  AudioPlayerNotifier(this._repository, this._reciter)
      : super(const AudioPlayerState());

  Future<void> playSurah(int surahNumber) async {
    state = state.copyWith(
      state: PlaybackState.loading,
      currentSurahNumber: surahNumber,
    );

    try {
      // Check for local file first
      final localPath = await _repository.getLocalAudioPath(
        _reciter.id,
        surahNumber,
      );
      final audioSource = localPath ?? _repository.getAudioUrl(_reciter, surahNumber);

      // TODO: Initialize just_audio player with audioSource
      state = state.copyWith(
        state: PlaybackState.playing,
      );
    } catch (e) {
      state = state.copyWith(
        state: PlaybackState.error,
        errorMessage: 'Failed to play audio: $e',
      );
    }
  }

  void pause() {
    if (state.isPlaying) {
      state = state.copyWith(state: PlaybackState.paused);
      // TODO: Pause just_audio player
    }
  }

  void resume() {
    if (state.isPaused) {
      state = state.copyWith(state: PlaybackState.playing);
      // TODO: Resume just_audio player
    }
  }

  void stop() {
    state = const AudioPlayerState();
    // TODO: Stop and dispose just_audio player
  }

  void seekTo(Duration position) {
    state = state.copyWith(position: position);
    // TODO: Seek just_audio player
  }

  void setPlaybackSpeed(double speed) {
    state = state.copyWith(playbackSpeed: speed);
    // TODO: Set just_audio playback speed
  }

  void toggleRepeat() {
    state = state.copyWith(isRepeatOn: !state.isRepeatOn);
  }
}

/// The main audio player state provider.
final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  final repository = ref.watch(audioRepositoryProvider);
  final reciter = ref.watch(selectedReciterProvider);
  return AudioPlayerNotifier(repository, reciter);
});

/// Tracks download progress for a surah (0.0 to 1.0).
final downloadProgressProvider = StateProvider.family<double?, int>(
  (ref, surahNumber) => null,
);
