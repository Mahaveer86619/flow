part of 'player_bloc.dart';

// ── Player Events ─────────────────────────────────────────────────────────────

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

/// Play a song and fetch its radio (up-next) tracks.
class PlayRadioEvent extends PlayerEvent {
  final Song song;
  const PlayRadioEvent(this.song);
}

/// Toggle between playing and paused.
class TogglePlayPauseEvent extends PlayerEvent {
  const TogglePlayPauseEvent();
}

/// Seek to [fraction] (0.0–1.0) of the current song's duration.
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

/// Set playback volume to [volume] (0.0–1.0).
class SetVolumeEvent extends PlayerEvent {
  final double volume;
  const SetVolumeEvent(this.volume);
}

// ── Internal events ─────────────────────────────────────────────────────────────

class _RestoreStateEvent extends PlayerEvent {
  const _RestoreStateEvent();
}

// ── Internal events dispatched by AudioPlayer stream subscriptions ─────────────

class _PositionUpdateEvent extends PlayerEvent {
  final Duration position;
  final Duration? duration;
  const _PositionUpdateEvent(this.position, this.duration);
}

class _BufferingChangedEvent extends PlayerEvent {
  final bool isBuffering;
  final bool isPlaying;
  const _BufferingChangedEvent({
    required this.isBuffering,
    required this.isPlaying,
  });
}

class _TrackCompletedEvent extends PlayerEvent {
  const _TrackCompletedEvent();
}
