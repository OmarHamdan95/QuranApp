import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart' show Color;
import 'package:just_audio/just_audio.dart';

/// [AudioService] wraps just_audio with background playback support,
/// lock-screen controls, and notification media controls via audio_service.
///
/// Usage: obtain via [initAudioService] and pass around as a singleton.
class QuranAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  QuranAudioHandler() {
    _init();
  }

  void _init() {
    // Forward player state to audio_service MediaItem / playback state
    _player.playbackEventStream.listen(_broadcastState);

    // When a track ends, auto-advance or stop based on repeat mode
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handleTrackCompletion();
      }
    });
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Loads and plays an audio URL immediately.
  Future<void> loadAndPlay({
    required String url,
    required MediaItem mediaItem,
  }) async {
    this.mediaItem.add(mediaItem);
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      await _player.play();
    } catch (e) {
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
        ),
      );
    }
  }

  /// Loads a playlist of audio URLs for continuous surah/ayah playback.
  Future<void> loadPlaylist({
    required List<AudioSource> sources,
    required List<MediaItem> items,
    int initialIndex = 0,
  }) async {
    queue.add(items);
    try {
      final playlist = ConcatenatingAudioSource(children: sources);
      await _player.setAudioSource(
        playlist,
        initialIndex: initialIndex,
      );
      mediaItem.add(items[initialIndex]);
      await _player.play();
    } catch (e) {
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
        ),
      );
    }
  }

  /// Sets the playback speed (0.5x – 2.0x).
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  /// Sets loop mode on the underlying player.
  Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  /// Exposes the raw player stream for position updates.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Exposes the raw player stream for duration updates.
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Exposes current index stream for playlist tracking.
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  /// Returns the current player state.
  bool get isPlaying => _player.playing;
  Duration get currentPosition => _player.position;
  Duration? get currentDuration => _player.duration;

  // ── BaseAudioHandler overrides ─────────────────────────────────────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
      final idx = _player.currentIndex;
      if (idx != null && idx < queue.value.length) {
        mediaItem.add(queue.value[idx]);
      }
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      final idx = _player.currentIndex;
      if (idx != null && idx < queue.value.length) {
        mediaItem.add(queue.value[idx]);
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
    return super.stop();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  void _handleTrackCompletion() {
    // If playlist has more tracks, just_audio handles advancing automatically
    // when using ConcatenatingAudioSource. For single tracks, stop.
    if (!_player.hasNext && _player.loopMode == LoopMode.off) {
      stop();
    }
  }
}

/// Initialises the audio service and returns the [QuranAudioHandler].
/// Call once from main() or the app's initialisation logic.
Future<QuranAudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => QuranAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.quranapp.audio',
      androidNotificationChannelName: 'Quran Audio',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_notification',
      androidShowNotificationBadge: true,
      notificationColor: Color(0xFF1B5E20),
      artDownscaleWidth: 300,
      artDownscaleHeight: 300,
    ),
  );
}

// ignore: avoid_classes_with_only_static_members
/// Helper to build a [MediaItem] from reciter + surah metadata.
class AudioMediaItemFactory {
  static MediaItem forSurah({
    required int surahNumber,
    required String surahNameArabic,
    required String surahNameEnglish,
    required String reciterNameArabic,
    required String reciterNameEnglish,
    required String audioUrl,
    Duration? duration,
  }) {
    final surahStr = surahNumber.toString().padLeft(3, '0');
    return MediaItem(
      id: audioUrl,
      album: reciterNameEnglish,
      title: surahNameArabic,
      artist: reciterNameArabic,
      displayTitle: surahNameArabic,
      displaySubtitle: '$reciterNameArabic - $reciterNameEnglish',
      displayDescription: 'سورة $surahNameArabic | Surah $surahNameEnglish',
      artUri: Uri.parse(
        'https://cdn.islamic.network/quran/images/surah/$surahStr.jpg',
      ),
      duration: duration,
      extras: {
        'surahNumber': surahNumber,
        'reciterNameEnglish': reciterNameEnglish,
        'reciterNameArabic': reciterNameArabic,
      },
    );
  }

  static MediaItem forAyah({
    required int surahNumber,
    required int ayahNumber,
    required String surahNameArabic,
    required String reciterNameArabic,
    required String audioUrl,
  }) {
    return MediaItem(
      id: audioUrl,
      album: reciterNameArabic,
      title: 'آية $ayahNumber - $surahNameArabic',
      artist: reciterNameArabic,
      displayTitle: 'آية $ayahNumber',
      displaySubtitle: surahNameArabic,
      extras: {
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
      },
    );
  }
}
