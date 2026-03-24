import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/services/audio_service.dart';
import '../../data/models/reciter_model.dart';
import '../../data/repositories/audio_repository_impl.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/repositories/audio_repository.dart';

// ── Repeat mode ────────────────────────────────────────────────────────────

/// Controls how playback loops.
enum RepeatMode {
  /// No repetition — playback stops at end.
  none,

  /// Repeat the current ayah indefinitely (LoopMode.one).
  singleAyah,

  /// Repeat a defined range of ayahs (e.g. 1–10).
  range,

  /// Repeat the entire surah (LoopMode.all / playlist loop).
  surah,
}

// ── Playback state ─────────────────────────────────────────────────────────

enum PlaybackStatus { idle, loading, playing, paused, error }

/// Snapshot of all playback-related state.
class AudioPlayerState {
  final PlaybackStatus status;
  final int? currentSurahNumber;
  final int? currentAyahNumber;
  final Duration position;
  final Duration duration;
  final double playbackSpeed;
  final RepeatMode repeatMode;
  final int repeatRangeStart;
  final int repeatRangeEnd;
  final bool isBackgroundPlayback;
  final String? errorMessage;

  /// Playlist of ayah audio URLs for the currently loaded surah.
  final List<String> playlist;

  const AudioPlayerState({
    this.status = PlaybackStatus.idle,
    this.currentSurahNumber,
    this.currentAyahNumber,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.repeatMode = RepeatMode.none,
    this.repeatRangeStart = 1,
    this.repeatRangeEnd = 1,
    this.isBackgroundPlayback = false,
    this.errorMessage,
    this.playlist = const [],
  });

  double get progress =>
      duration.inMilliseconds > 0
          ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
          : 0.0;

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get isLoading => status == PlaybackStatus.loading;
  bool get isIdle => status == PlaybackStatus.idle;
  bool get hasError => status == PlaybackStatus.error;
  bool get isRepeatOn => repeatMode != RepeatMode.none;

  AudioPlayerState copyWith({
    PlaybackStatus? status,
    int? currentSurahNumber,
    int? currentAyahNumber,
    Duration? position,
    Duration? duration,
    double? playbackSpeed,
    RepeatMode? repeatMode,
    int? repeatRangeStart,
    int? repeatRangeEnd,
    bool? isBackgroundPlayback,
    String? errorMessage,
    List<String>? playlist,
  }) {
    return AudioPlayerState(
      status: status ?? this.status,
      currentSurahNumber:
          currentSurahNumber ?? this.currentSurahNumber,
      currentAyahNumber: currentAyahNumber ?? this.currentAyahNumber,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      repeatMode: repeatMode ?? this.repeatMode,
      repeatRangeStart: repeatRangeStart ?? this.repeatRangeStart,
      repeatRangeEnd: repeatRangeEnd ?? this.repeatRangeEnd,
      isBackgroundPlayback:
          isBackgroundPlayback ?? this.isBackgroundPlayback,
      errorMessage: errorMessage,
      playlist: playlist ?? this.playlist,
    );
  }

  @override
  String toString() =>
      'AudioPlayerState(status=$status, surah=$currentSurahNumber, '
      'ayah=$currentAyahNumber, pos=$position, dur=$duration)';
}

// ── AudioPlayerNotifier ────────────────────────────────────────────────────

/// StateNotifier driving all audio playback interactions.
///
/// Integrates directly with [AudioPlayer] from just_audio and uses
/// [QuranAudioHandler] for background playback when available.
class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final AudioRepository _repository;
  Reciter _reciter;
  final AudioPlayer _player = AudioPlayer();
  QuranAudioHandler? _audioHandler;

  AudioPlayerNotifier(this._repository, this._reciter)
      : super(const AudioPlayerState()) {
    _initPlayer();
  }

  void _initPlayer() {
    // Forward position updates into state
    _player.positionStream.listen((pos) {
      if (!mounted) return;
      state = state.copyWith(position: pos);
    });

    // Forward duration updates into state
    _player.durationStream.listen((dur) {
      if (!mounted) return;
      if (dur != null) state = state.copyWith(duration: dur);
    });

    // Handle track completion
    _player.processingStateStream.listen((ps) {
      if (!mounted) return;
      if (ps == ProcessingState.completed) {
        _onTrackCompleted();
      } else if (ps == ProcessingState.ready && state.isLoading) {
        state = state.copyWith(status: PlaybackStatus.playing);
      }
    });

    // Mirror playing / paused state
    _player.playingStream.listen((playing) {
      if (!mounted) return;
      if (playing && state.isPaused) {
        state = state.copyWith(status: PlaybackStatus.playing);
      } else if (!playing && state.isPlaying) {
        state = state.copyWith(status: PlaybackStatus.paused);
      }
    });

    // Current index changes (playlist mode)
    _player.currentIndexStream.listen((idx) {
      if (!mounted || idx == null) return;
      if (state.playlist.isNotEmpty && idx < state.playlist.length) {
        state = state.copyWith(currentAyahNumber: idx + 1);
      }
    });
  }

  // ── Reciter ──────────────────────────────────────────────────────────────

  /// Update the reciter; resets playback if something was playing.
  void updateReciter(Reciter reciter) {
    if (_reciter.id == reciter.id) return;
    _reciter = reciter;
    if (!state.isIdle) stop();
  }

  // ── Background audio handler ──────────────────────────────────────────────

  void attachAudioHandler(QuranAudioHandler handler) {
    _audioHandler = handler;
  }

  // ── Playback ──────────────────────────────────────────────────────────────

  /// Plays the full surah as a single MP3 stream.
  Future<void> playSurah(int surahNumber) async {
    state = state.copyWith(
      status: PlaybackStatus.loading,
      currentSurahNumber: surahNumber,
      currentAyahNumber: null,
      playlist: [],
      errorMessage: null,
    );

    try {
      final localPath = await _repository.getLocalAudioPath(
        _reciter.id,
        surahNumber,
      );
      final audioUrl =
          localPath != null
              ? 'file://$localPath'
              : _repository.getAudioUrl(_reciter, surahNumber);

      await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
      await _player.setSpeed(state.playbackSpeed);
      await _player.play();

      state = state.copyWith(status: PlaybackStatus.playing);
    } catch (e) {
      state = state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'Failed to play surah: $e',
      );
    }
  }

  /// Loads a playlist of per-ayah URLs and starts from [startAyah].
  Future<void> playAyahPlaylist({
    required int surahNumber,
    required int ayahCount,
    int startAyah = 1,
  }) async {
    state = state.copyWith(
      status: PlaybackStatus.loading,
      currentSurahNumber: surahNumber,
      currentAyahNumber: startAyah,
      errorMessage: null,
    );

    try {
      final repo = _repository as AudioRepositoryImpl;
      final urls = repo.getSurahAyahUrls(_reciter, surahNumber, ayahCount);
      state = state.copyWith(playlist: urls);

      final sources = urls
          .map((u) => AudioSource.uri(Uri.parse(u)))
          .toList();
      final playlist = ConcatenatingAudioSource(children: sources);

      await _player.setAudioSource(
        playlist,
        initialIndex: (startAyah - 1).clamp(0, urls.length - 1),
      );
      await _player.setSpeed(state.playbackSpeed);
      _applyLoopMode();
      await _player.play();

      state = state.copyWith(status: PlaybackStatus.playing);
    } catch (e) {
      state = state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'Failed to load ayah playlist: $e',
      );
    }
  }

  /// Plays a single specific ayah.
  Future<void> playAyah(int surahNumber, int ayahNumber) async {
    state = state.copyWith(
      status: PlaybackStatus.loading,
      currentSurahNumber: surahNumber,
      currentAyahNumber: ayahNumber,
      playlist: [],
      errorMessage: null,
    );

    try {
      final url = _repository.getAyahAudioUrl(_reciter, surahNumber, ayahNumber);
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      await _player.setSpeed(state.playbackSpeed);
      await _player.play();
      state = state.copyWith(status: PlaybackStatus.playing);
    } catch (e) {
      state = state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'Failed to play ayah: $e',
      );
    }
  }

  void pause() {
    if (state.isPlaying) {
      _player.pause();
      state = state.copyWith(status: PlaybackStatus.paused);
    }
  }

  void resume() {
    if (state.isPaused) {
      _player.play();
      state = state.copyWith(status: PlaybackStatus.playing);
    }
  }

  void stop() {
    _player.stop();
    state = const AudioPlayerState();
  }

  void seekTo(Duration position) {
    _player.seek(position);
    state = state.copyWith(position: position);
  }

  /// Skip to the next ayah in the playlist.
  void skipToNext() {
    if (_player.hasNext) {
      _player.seekToNext();
    }
  }

  /// Skip to the previous ayah or restart current if past 3 seconds.
  void skipToPrevious() {
    if (_player.position.inSeconds > 3) {
      _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      _player.seekToPrevious();
    }
  }

  void setPlaybackSpeed(double speed) {
    _player.setSpeed(speed);
    state = state.copyWith(playbackSpeed: speed);
  }

  /// Cycle through repeat modes: none → singleAyah → range → surah → none.
  void cycleRepeatMode() {
    final next = RepeatMode.values[
        (state.repeatMode.index + 1) % RepeatMode.values.length];
    setRepeatMode(next);
  }

  void setRepeatMode(RepeatMode mode) {
    state = state.copyWith(repeatMode: mode);
    _applyLoopMode();
  }

  void setRepeatRange(int startAyah, int endAyah) {
    state = state.copyWith(
      repeatRangeStart: startAyah,
      repeatRangeEnd: endAyah,
      repeatMode: RepeatMode.range,
    );
  }

  void _applyLoopMode() {
    switch (state.repeatMode) {
      case RepeatMode.none:
        _player.setLoopMode(LoopMode.off);
      case RepeatMode.singleAyah:
        _player.setLoopMode(LoopMode.one);
      case RepeatMode.range:
      case RepeatMode.surah:
        _player.setLoopMode(LoopMode.all);
    }
  }

  void _onTrackCompleted() {
    switch (state.repeatMode) {
      case RepeatMode.none:
        state = state.copyWith(status: PlaybackStatus.idle);
      case RepeatMode.singleAyah:
        // just_audio handles LoopMode.one automatically
        break;
      case RepeatMode.range:
        // Restart from rangeStart when we pass rangeEnd
        final ayah = state.currentAyahNumber ?? 1;
        if (ayah >= state.repeatRangeEnd) {
          final startIdx = (state.repeatRangeStart - 1)
              .clamp(0, state.playlist.length - 1);
          _player.seek(Duration.zero, index: startIdx);
          _player.play();
        }
      case RepeatMode.surah:
        // LoopMode.all handles this automatically
        break;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

// ── Providers ──────────────────────────────────────────────────────────────

/// Provider for the audio repository implementation.
final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  return AudioRepositoryImpl();
});

/// Fetches and caches the list of available reciters.
final recitersProvider = FutureProvider<List<Reciter>>((ref) async {
  final repository = ref.watch(audioRepositoryProvider);
  final result = await repository.getReciters();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (reciters) => reciters,
  );
});

/// The currently selected reciter (defaults to Mishary Rashid).
final selectedReciterProvider = StateProvider<Reciter>((ref) {
  return ReciterModel.popularReciters.first;
});

/// The main audio player state notifier.
final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  final repository = ref.watch(audioRepositoryProvider);
  final reciter = ref.watch(selectedReciterProvider);
  final notifier = AudioPlayerNotifier(repository, reciter);

  // When the selected reciter changes, inform the notifier.
  ref.listen<Reciter>(selectedReciterProvider, (_, next) {
    notifier.updateReciter(next);
  });

  return notifier;
});

/// Convenience provider exposing only the current playback position.
final audioPositionProvider = Provider<Duration>((ref) {
  return ref.watch(audioPlayerProvider).position;
});

/// Convenience provider exposing only the total duration.
final audioDurationProvider = Provider<Duration>((ref) {
  return ref.watch(audioPlayerProvider).duration;
});

/// Convenience provider exposing only the progress (0.0 – 1.0).
final audioProgressProvider = Provider<double>((ref) {
  return ref.watch(audioPlayerProvider).progress;
});

/// Convenience provider exposing whether audio is currently playing.
final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(audioPlayerProvider).isPlaying;
});

/// The current repeat mode.
final repeatModeProvider = Provider<RepeatMode>((ref) {
  return ref.watch(audioPlayerProvider).repeatMode;
});

/// Tracks per-surah download progress (0.0 to 1.0), keyed by surah number.
final downloadProgressProvider = StateProvider.family<double?, int>(
  (ref, surahNumber) => null,
);

/// Whether a specific surah is downloaded (checked lazily per surah number).
final surahDownloadedProvider =
    FutureProvider.family<bool, ({int reciterId, int surahNumber})>(
        (ref, args) async {
  final repo = ref.watch(audioRepositoryProvider);
  return repo.isSurahDownloaded(args.reciterId, args.surahNumber);
});
