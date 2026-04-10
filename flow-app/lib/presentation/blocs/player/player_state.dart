part of 'player_bloc.dart';

// ── PlayerState ───────────────────────────────────────────────────────────────
//
// Immutable snapshot of all playback state.
// [position] and [actualDuration] come from the real AudioPlayer; [progress]
// is derived so existing UI code continues to work unchanged.
// ─────────────────────────────────────────────────────────────────────────────

class PlayerState {
  final Song? currentSong;
  final bool isPlaying;
  final bool isBuffering;

  /// Actual playback position from AudioPlayer.
  final Duration position;

  /// Actual track duration reported by AudioPlayer (null until stream loads).
  final Duration? actualDuration;

  final bool isShuffle;
  final bool isRepeat;
  final double volume;
  final List<String> likedSongIds;
  final List<Song> recentlyPlayed;
  final List<Song> queue;
  final int queueIndex;

  const PlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.actualDuration,
    this.isShuffle = false,
    this.isRepeat = false,
    this.volume = 0.7,
    this.likedSongIds = const [],
    this.recentlyPlayed = const [],
    this.queue = const [],
    this.queueIndex = -1,
  });

  /// 0.0–1.0 fractional progress — derived from [position] / effective duration.
  /// Falls back to 0.0 when duration is unknown.
  double get progress {
    final dur = actualDuration ?? currentSong?.duration;
    if (dur == null || dur.inMilliseconds <= 0) return 0.0;
    return (position.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
  }

  bool isLiked(Song song) => likedSongIds.contains(song.id);
  int get likedSongsCount => likedSongIds.length;

  String get currentTimeString {
    final s = position.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  String get totalTimeString {
    final dur = actualDuration ?? currentSong?.duration ?? Duration.zero;
    final s = dur.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  PlayerState copyWith({
    Song? currentSong,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? actualDuration,
    bool clearActualDuration = false,
    bool? isShuffle,
    bool? isRepeat,
    double? volume,
    List<String>? likedSongIds,
    List<Song>? recentlyPlayed,
    List<Song>? queue,
    int? queueIndex,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      actualDuration: clearActualDuration ? null : (actualDuration ?? this.actualDuration),
      isShuffle: isShuffle ?? this.isShuffle,
      isRepeat: isRepeat ?? this.isRepeat,
      volume: volume ?? this.volume,
      likedSongIds: likedSongIds ?? this.likedSongIds,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
    );
  }
}
