part of 'player_bloc.dart';

// ── Player State ──────────────────────────────────────────────────────────────
//
// Immutable snapshot of all playback state at a point in time.
// [PlayerBloc] emits a new instance on every state change; widgets rebuild
// only when the slice of state they read actually differs.
// ─────────────────────────────────────────────────────────────────────────────

class PlayerState {
  final Song? currentSong;
  final bool isPlaying;
  final double progress;
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
    this.progress = 0.0,
    this.isShuffle = false,
    this.isRepeat = false,
    this.volume = 0.7,
    this.likedSongIds = const [],
    this.recentlyPlayed = const [],
    this.queue = const [],
    this.queueIndex = -1,
  });

  bool isLiked(Song song) => likedSongIds.contains(song.id);
  int get likedSongsCount => likedSongIds.length;

  String get currentTimeString {
    if (currentSong == null) return '0:00';
    final secs = (currentSong!.duration.inSeconds * progress).round();
    return '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
  }

  String get totalTimeString {
    if (currentSong == null) return '0:00';
    final secs = currentSong!.duration.inSeconds;
    return '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
  }

  PlayerState copyWith({
    Song? currentSong,
    bool? isPlaying,
    double? progress,
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
      progress: progress ?? this.progress,
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
