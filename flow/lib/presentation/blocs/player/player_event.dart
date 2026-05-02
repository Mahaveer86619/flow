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

/// Play a shuffle of all downloaded tracks.
class PlayDownloadedRadioEvent extends PlayerEvent {
  const PlayDownloadedRadioEvent();
}

/// Toggle between playing and paused.
class TogglePlayPauseEvent extends PlayerEvent {
  const TogglePlayPauseEvent();
}

/// Explicitly start playback.
class PlayEvent extends PlayerEvent {
  const PlayEvent();
}

/// Explicitly pause playback.
class PauseEvent extends PlayerEvent {
  const PauseEvent();
}

/// Seek to [fraction] (0.0–1.0) of the current song's duration.
class SeekToEvent extends PlayerEvent {
  final double fraction;
  const SeekToEvent(this.fraction);
}

/// Skip to a specific track in the existing queue.
class SkipToQueueIndexEvent extends PlayerEvent {
  final int index;
  const SkipToQueueIndexEvent(this.index);
}

/// Add a [song] to play immediately after the current one.
class InsertNextEvent extends PlayerEvent {
  final Song song;
  const InsertNextEvent(this.song);
}

/// Add a [song] to the end of the current queue.
class AppendToQueueEvent extends PlayerEvent {
  final Song song;
  const AppendToQueueEvent(this.song);
}

/// Remove the track at [index] from the queue.
class RemoveFromQueueEvent extends PlayerEvent {
  final int index;
  const RemoveFromQueueEvent(this.index);
}

/// Reorder tracks in the queue.
class ReorderQueueEvent extends PlayerEvent {
  final int oldIndex;
  final int newIndex;
  const ReorderQueueEvent(this.oldIndex, this.newIndex);
}

/// Skip to the next track in the queue.
class SkipNextEvent extends PlayerEvent {
  const SkipNextEvent();
}

/// Seek to the previous track (or restart if progress > 5 %).
class SkipPreviousEvent extends PlayerEvent {
  const SkipPreviousEvent();
}

/// Skip forward by 10 seconds.
class FastForwardEvent extends PlayerEvent {
  const FastForwardEvent();
}

/// Skip backward by 10 seconds.
class RewindEvent extends PlayerEvent {
  const RewindEvent();
}

/// Toggle shuffle mode on/off.
class ToggleShuffleEvent extends PlayerEvent {
  const ToggleShuffleEvent();
}

/// Toggle repeat mode on/off.
class ToggleRepeatEvent extends PlayerEvent {
  const ToggleRepeatEvent();
}

/// Toggle endless radio (auto-fetching next tracks).
class ToggleEndlessRadioEvent extends PlayerEvent {
  const ToggleEndlessRadioEvent();
}

/// Add or remove [song] from the liked-songs set.
class ToggleLikeEvent extends PlayerEvent {
  final Song song;
  const ToggleLikeEvent(this.song);
}

/// Add or remove [song] from the offline-downloads set.
class ToggleDownloadEvent extends PlayerEvent {
  final Song song;
  const ToggleDownloadEvent(this.song);
}

/// Set playback volume to [volume] (0.0–1.0).
class SetVolumeEvent extends PlayerEvent {
  final double volume;
  const SetVolumeEvent(this.volume);
}

/// Set playback speed (0.5 - 2.0).
class SetPlaybackSpeedEvent extends PlayerEvent {
  final double speed;
  const SetPlaybackSpeedEvent(this.speed);
}

/// Set crossfade duration.
class SetCrossfadeDurationEvent extends PlayerEvent {
  final Duration duration;
  const SetCrossfadeDurationEvent(this.duration);
}

/// Filter the current queue based on a mood target.

class FilterByMoodEvent extends PlayerEvent {
  final String mood;
  const FilterByMoodEvent(this.mood);
}

/// Reset the player state, stop playback, and clear queue.

/// Useful when the player gets stuck or for a "state clean" functionality.
class ResetPlayerEvent extends PlayerEvent {
  const ResetPlayerEvent();
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

class _BufferedPositionChangedEvent extends PlayerEvent {
  final Duration bufferedPosition;
  const _BufferedPositionChangedEvent(this.bufferedPosition);
}

class _InitialLoadingChangedEvent extends PlayerEvent {
  final bool isInitialLoading;
  const _InitialLoadingChangedEvent(this.isInitialLoading);
}

class _DownloadProgressUpdatedEvent extends PlayerEvent {
  final Map<String, double> progress;
  const _DownloadProgressUpdatedEvent(this.progress);
}

class _TrackCompletedEvent extends PlayerEvent {
  const _TrackCompletedEvent();
}

class _TrackChangedEvent extends PlayerEvent {
  final int index;
  const _TrackChangedEvent(this.index);
}

class _PlayStateChangedEvent extends PlayerEvent {
  final bool isPlaying;
  const _PlayStateChangedEvent(this.isPlaying);
}

class _QueueUpdatedEvent extends PlayerEvent {
  final List<Song> queue;
  const _QueueUpdatedEvent(this.queue);
}

class _RecentlyPlayedUpdatedEvent extends PlayerEvent {
  final List<Song> recentlyPlayed;
  const _RecentlyPlayedUpdatedEvent(this.recentlyPlayed);
}

class _PaletteUpdatedEvent extends PlayerEvent {
  final Color primary;
  final Color secondary;
  const _PaletteUpdatedEvent(this.primary, this.secondary);
}
