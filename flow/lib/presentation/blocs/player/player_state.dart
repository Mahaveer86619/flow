part of 'player_bloc.dart';

// ── PlayerState ───────────────────────────────────────────────────────────────
//
// Immutable snapshot of all playback state.
// [position] and [actualDuration] come from the real AudioPlayer; [progress]
// is derived so existing UI code continues to work unchanged.
// ─────────────────────────────────────────────────────────────────────────────

class PlayerState extends Equatable {
  final Song? currentSong;
  final bool isPlaying;
  final bool isBuffering;
  final bool isInitialLoading;

  /// Actual playback position from AudioPlayer.
  final Duration position;

  /// Buffered duration from AudioPlayer.
  final Duration bufferedPosition;

  /// Actual track duration reported by AudioPlayer (null until stream loads).
  final Duration? actualDuration;

  final bool isShuffle;
  final bool isRepeat;
  final bool isEndlessRadio;
  final double volume;
  final List<String> likedSongIds;
  final List<String> recentlyPlayedIds;
  final List<Song> recentlyPlayed;
  final List<Song> queue;
  final int queueIndex;

  /// Map of songId -> 0.0-1.0 progress
  final Map<String, double> downloadProgress;

  /// Dynamically extracted colors from current song artwork.
  final Color? customPrimary;
  final Color? customSecondary;

  const PlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isInitialLoading = false,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.actualDuration,
    this.isShuffle = false,
    this.isRepeat = false,
    this.isEndlessRadio = true,
    this.volume = 0.7,
    this.likedSongIds = const [],
    this.recentlyPlayedIds = const [],
    this.recentlyPlayed = const [],
    this.queue = const [],
    this.queueIndex = -1,
    this.downloadProgress = const {},
    this.customPrimary,
    this.customSecondary,
  });

  @override
  List<Object?> get props => [
    currentSong,
    isPlaying,
    isBuffering,
    isInitialLoading,
    position,
    bufferedPosition,
    actualDuration,
    isShuffle,
    isRepeat,
    isEndlessRadio,
    volume,
    likedSongIds,
    recentlyPlayedIds,
    recentlyPlayed,
    queue,
    queueIndex,
    downloadProgress,
    customPrimary,
    customSecondary,
  ];

  /// 0.0–1.0 fractional progress — derived from [position] / effective duration.
  /// Falls back to 0.0 when duration is unknown.
  double get progress {
    final dur = actualDuration ?? currentSong?.duration;
    if (dur == null || dur.inMilliseconds <= 0) return 0.0;
    return (position.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
  }

  /// 0.0–1.0 fractional buffer progress.
  double get bufferProgress {
    if (currentSong?.isDownloaded ?? false) return 1.0;
    final dur = actualDuration ?? currentSong?.duration;
    if (dur == null || dur.inMilliseconds <= 0) return 0.0;
    return (bufferedPosition.inMilliseconds / dur.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  bool isLiked(Song song) => likedSongIds.contains(song.id);
  int get likedSongsCount => likedSongIds.length;

  double getDownloadProgress(String songId) => downloadProgress[songId] ?? -1.0;

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
    bool? isInitialLoading,
    Duration? position,
    Duration? bufferedPosition,
    Duration? actualDuration,
    bool clearActualDuration = false,
    bool? isShuffle,
    bool? isRepeat,
    bool? isEndlessRadio,
    double? volume,
    List<String>? likedSongIds,
    List<String>? recentlyPlayedIds,
    List<Song>? recentlyPlayed,
    List<Song>? queue,
    int? queueIndex,
    Map<String, double>? downloadProgress,
    Color? customPrimary,
    Color? customSecondary,
    bool clearCustomColors = false,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      actualDuration: clearActualDuration
          ? null
          : (actualDuration ?? this.actualDuration),
      isShuffle: isShuffle ?? this.isShuffle,
      isRepeat: isRepeat ?? this.isRepeat,
      isEndlessRadio: isEndlessRadio ?? this.isEndlessRadio,
      volume: volume ?? this.volume,
      likedSongIds: likedSongIds ?? this.likedSongIds,
      recentlyPlayedIds: recentlyPlayedIds ?? this.recentlyPlayedIds,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      customPrimary: clearCustomColors
          ? null
          : (customPrimary ?? this.customPrimary),
      customSecondary: clearCustomColors
          ? null
          : (customSecondary ?? this.customSecondary),
    );
  }
}
