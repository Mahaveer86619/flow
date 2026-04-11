import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:smtc_windows/smtc_windows.dart';
import '../../domain/entities/song.dart';
import '../logger/app_logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WindowsMediaSession
//
// Wraps SMTCWindows (System Media Transport Controls) so the OS media overlay
// — accessible via the volume flyout or media keys — shows current song info
// and routes play/pause/next/prev back into the player.
//
// All public methods are safe to call on non-Windows platforms; they become
// no-ops so callers don't need platform guards.
//
// Usage (from PlayerBloc constructor):
//   await WindowsMediaSession.instance.init(
//     onPlay:     () => add(const TogglePlayPauseEvent()),
//     onPause:    () => add(const TogglePlayPauseEvent()),
//     onNext:     () => add(const SkipNextEvent()),
//     onPrevious: () => add(const SkipPreviousEvent()),
//   );
// ─────────────────────────────────────────────────────────────────────────────

class WindowsMediaSession {
  WindowsMediaSession._();
  static final WindowsMediaSession instance = WindowsMediaSession._();

  static const _tag = 'WindowsMediaSession';

  SMTCWindows? _smtc;
  StreamSubscription<PressedButton>? _buttonSub;

  bool get _isWindows => !kIsWeb && Platform.isWindows;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> init({
    required VoidCallback onPlay,
    required VoidCallback onPause,
    required VoidCallback onNext,
    required VoidCallback onPrevious,
    VoidCallback? onFastForward,
    VoidCallback? onRewind,
  }) async {
    if (!_isWindows) return;
    AppLogger.i(_tag, 'Initialising SMTC');

    try {
      _smtc = SMTCWindows(
        config: const SMTCConfig(
          fastForwardEnabled: true,
          nextEnabled: true,
          prevEnabled: true,
          playEnabled: true,
          pauseEnabled: true,
          stopEnabled: false,
          rewindEnabled: true,
        ),
      );

      await _smtc!.enableSmtc();

      _buttonSub = _smtc!.buttonPressStream.listen((button) {
        AppLogger.d(_tag, 'Button: $button');
        switch (button) {
          case PressedButton.play:
            onPlay();
          case PressedButton.pause:
            onPause();
          case PressedButton.next:
            onNext();
          case PressedButton.previous:
            onPrevious();
          case PressedButton.fastForward:
            onFastForward?.call();
          case PressedButton.rewind:
            onRewind?.call();
          default:
            break;
        }
      });

      AppLogger.i(_tag, 'SMTC ready');
    } catch (e, st) {
      AppLogger.e(_tag, 'SMTC init failed — media keys unavailable', e, st);
    }
  }

  // ── State updates ──────────────────────────────────────────────────────────

  Future<void> updateSong(Song song) async {
    if (!_isWindows || _smtc == null) return;
    try {
      await _smtc!.updateMetadata(
        MusicMetadata(
          title: song.title,
          artist: song.artist,
          albumArtist: song.artist,
          album: song.album.isNotEmpty ? song.album : song.artist,
          thumbnail: song.thumbnailUrl,
        ),
      );
      AppLogger.d(_tag, 'Metadata updated: "${song.title}"');
    } catch (e) {
      AppLogger.w(_tag, 'updateSong failed: $e');
    }
  }

  Future<void> setPlaybackStatus(bool isPlaying) async {
    if (!_isWindows || _smtc == null) return;
    try {
      await _smtc!.setPlaybackStatus(
        isPlaying ? PlaybackStatus.Playing : PlaybackStatus.Paused,
      );
    } catch (e) {
      AppLogger.w(_tag, 'setPlaybackStatus failed: $e');
    }
  }

  Future<void> updateTimeline(Duration position, Duration duration) async {
    if (!_isWindows || _smtc == null) return;
    if (duration.inMilliseconds <= 0) return;
    try {
      await _smtc!.updateTimeline(
        PlaybackTimeline(
          startTimeMs: 0,
          endTimeMs: duration.inMilliseconds,
          positionMs: position.inMilliseconds.clamp(0, duration.inMilliseconds),
          minSeekTimeMs: 0,
          maxSeekTimeMs: duration.inMilliseconds,
        ),
      );
    } catch (e) {
      AppLogger.w(_tag, 'updateTimeline failed: $e');
    }
  }

  Future<void> setStopped() async {
    if (!_isWindows || _smtc == null) return;
    try {
      await _smtc!.setPlaybackStatus(PlaybackStatus.Stopped);
    } catch (e) {
      AppLogger.w(_tag, 'setStopped failed: $e');
    }
  }

  Future<void> dispose() async {
    if (!_isWindows || _smtc == null) return;
    AppLogger.i(_tag, 'Disposing SMTC');
    await _buttonSub?.cancel();
    await _smtc!.disableSmtc();
    _smtc!.dispose();
    _smtc = null;
  }
}
