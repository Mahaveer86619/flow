part of 'player_bloc.dart';

// ── Player Events ─────────────────────────────────────────────────────────────
//
// Every user action or system signal that mutates player state is expressed as
// an immutable event. The BLoC handles each via a dedicated handler, keeping
// the state-transition logic testable and explicit.
// ─────────────────────────────────────────────────────────────────────────────

abstract class PlayerEvent {
  const PlayerEvent();
}

/// Start playback of [songs] beginning at [startIndex].
class PlayQueueEvent extends PlayerEvent {
  final List<Song> songs;
  final int startIndex;
  const PlayQueueEvent({required this.songs, this.startIndex = 0});
}

/// Play a single [song] (creates a one-item internal queue).
class PlaySingleEvent extends PlayerEvent {
  final Song song;
  const PlaySingleEvent(this.song);
}

/// Toggle between playing and paused.
class TogglePlayPauseEvent extends PlayerEvent {
  const TogglePlayPauseEvent();
}

/// Seek to [fraction] (0.0 – 1.0) of the current song's duration.
class SeekToEvent extends PlayerEvent {
  final double fraction;
  const SeekToEvent(this.fraction);
}

/// Skip to the next track in the queue.
class SkipNextEvent extends PlayerEvent {
  const SkipNextEvent();
}

/// Skip to the previous track (or restart if progress > 5 %).
class SkipPreviousEvent extends PlayerEvent {
  const SkipPreviousEvent();
}

/// Toggle shuffle mode on/off.
class ToggleShuffleEvent extends PlayerEvent {
  const ToggleShuffleEvent();
}

/// Toggle repeat mode on/off.
class ToggleRepeatEvent extends PlayerEvent {
  const ToggleRepeatEvent();
}

/// Add or remove [song] from the liked-songs set.
class ToggleLikeEvent extends PlayerEvent {
  final Song song;
  const ToggleLikeEvent(this.song);
}

/// Set playback volume to [volume] (0.0 – 1.0).
class SetVolumeEvent extends PlayerEvent {
  final double volume;
  const SetVolumeEvent(this.volume);
}

/// Internal: emitted by the progress timer each tick.
/// Not part of the public API — prefixed with _ to signal that.
class _ProgressTickEvent extends PlayerEvent {
  /// Fractional progress increment for this tick.
  final double delta;
  const _ProgressTickEvent(this.delta);
}
