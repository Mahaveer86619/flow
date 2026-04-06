import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/song.dart';

// ── State ─────────────────────────────────────────────────────────────────────

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

// ── Cubit ──────────────────────────────────────────────────────────────────────

class PlayerCubit extends Cubit<PlayerState> {
  Timer? _progressTimer;

  PlayerCubit() : super(const PlayerState());

  // ── Public commands ────────────────────────────────────────────────────────

  void playQueue(List<Song> songs, {int startIndex = 0}) {
    final idx = startIndex.clamp(0, songs.length - 1);
    emit(state.copyWith(queue: List.from(songs), queueIndex: idx));
    _playSong(songs[idx]);
  }

  void play(Song song) {
    emit(state.copyWith(queue: [song], queueIndex: 0));
    _playSong(song);
  }

  void togglePlayPause() {
    if (state.isPlaying) {
      _progressTimer?.cancel();
      emit(state.copyWith(isPlaying: false));
    } else {
      emit(state.copyWith(isPlaying: true));
      _startTimer();
    }
  }

  void seekTo(double value) =>
      emit(state.copyWith(progress: value.clamp(0.0, 1.0)));

  void next() {
    if (state.queue.isEmpty) return;
    int nextIdx = state.isShuffle
        ? Random().nextInt(state.queue.length)
        : (state.queueIndex + 1) % state.queue.length;
    emit(state.copyWith(queueIndex: nextIdx));
    _playSong(state.queue[nextIdx]);
  }

  void previous() {
    if (state.progress > 0.05) {
      seekTo(0.0);
      return;
    }
    if (state.queue.isEmpty) return;
    int prevIdx =
        (state.queueIndex - 1 + state.queue.length) % state.queue.length;
    emit(state.copyWith(queueIndex: prevIdx));
    _playSong(state.queue[prevIdx]);
  }

  void toggleShuffle() => emit(state.copyWith(isShuffle: !state.isShuffle));

  void toggleRepeat() => emit(state.copyWith(isRepeat: !state.isRepeat));

  void toggleLike(Song song) {
    final liked = List<String>.from(state.likedSongIds);
    liked.contains(song.id) ? liked.remove(song.id) : liked.add(song.id);
    emit(state.copyWith(likedSongIds: liked));
  }

  void setVolume(double value) =>
      emit(state.copyWith(volume: value.clamp(0.0, 1.0)));

  // ── Private helpers ──────────────────────────────────────────────────────────

  void _playSong(Song song) {
    _progressTimer?.cancel();
    final recent = [
      song,
      ...state.recentlyPlayed.where((s) => s.id != song.id),
    ];
    if (recent.length > 20) recent.removeLast();
    emit(
      state.copyWith(
        currentSong: song,
        isPlaying: true,
        progress: 0.0,
        recentlyPlayed: recent,
      ),
    );
    _startTimer();
  }

  void _startTimer() {
    _progressTimer?.cancel();
    if (state.currentSong == null) return;

    final totalMs = state.currentSong!.duration.inMilliseconds;
    const tickMs = 500;

    _progressTimer = Timer.periodic(const Duration(milliseconds: tickMs), (_) {
      if (!state.isPlaying || isClosed) return;

      final newProgress = state.progress + tickMs / totalMs;
      if (newProgress >= 1.0) {
        if (state.isRepeat) {
          emit(state.copyWith(progress: 0.0));
        } else if (state.queue.length > 1) {
          next();
        } else {
          _progressTimer?.cancel();
          emit(state.copyWith(progress: 1.0, isPlaying: false));
        }
      } else {
        emit(state.copyWith(progress: newProgress));
      }
    });
  }

  @override
  Future<void> close() {
    _progressTimer?.cancel();
    return super.close();
  }
}
