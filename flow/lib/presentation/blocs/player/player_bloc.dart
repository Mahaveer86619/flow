import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/song.dart';

part 'player_event.dart';
part 'player_state.dart';

// ── PlayerBloc ────────────────────────────────────────────────────────────────
//
// BLoC chosen over Cubit here because player logic involves many distinct
// event types (play, pause, seek, skip, like, shuffle, repeat, volume) that
// benefit from explicit event classes: they are self-documenting, easily
// logged, and individually unit-testable.
//
// Flow: UI dispatches an event → BLoC handler runs → new PlayerState emitted
//       → any BlocBuilder / context.watch<PlayerBloc> rebuilds.
//
// Progress timer: runs internally and dispatches [_ProgressTickEvent] every
// 500 ms while playing. Using an internal event keeps the handler pure and
// the timer logic out of the UI layer.
//
// To connect a real audio backend:
//   1. Inject your audio service in the constructor.
//   2. Call service methods inside the relevant handlers.
//   3. Listen to service position streams and add [_ProgressTickEvent] /
//      [SkipNextEvent] as needed.
// ─────────────────────────────────────────────────────────────────────────────

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  Timer? _progressTimer;

  PlayerBloc() : super(const PlayerState()) {
    on<PlayQueueEvent>(_onPlayQueue);
    on<PlaySingleEvent>(_onPlaySingle);
    on<TogglePlayPauseEvent>(_onTogglePlayPause);
    on<SeekToEvent>(_onSeekTo);
    on<SkipNextEvent>(_onSkipNext);
    on<SkipPreviousEvent>(_onSkipPrevious);
    on<ToggleShuffleEvent>(_onToggleShuffle);
    on<ToggleRepeatEvent>(_onToggleRepeat);
    on<ToggleLikeEvent>(_onToggleLike);
    on<SetVolumeEvent>(_onSetVolume);
    on<_ProgressTickEvent>(_onProgressTick);
  }

  // ── Event handlers ───────────────────────────────────────────────────────────

  void _onPlayQueue(PlayQueueEvent event, Emitter<PlayerState> emit) {
    final idx = event.startIndex.clamp(0, event.songs.length - 1);
    emit(state.copyWith(queue: List.from(event.songs), queueIndex: idx));
    _playSong(event.songs[idx], emit);
  }

  void _onPlaySingle(PlaySingleEvent event, Emitter<PlayerState> emit) {
    emit(state.copyWith(queue: [event.song], queueIndex: 0));
    _playSong(event.song, emit);
  }

  void _onTogglePlayPause(
    TogglePlayPauseEvent event,
    Emitter<PlayerState> emit,
  ) {
    if (state.isPlaying) {
      _progressTimer?.cancel();
      emit(state.copyWith(isPlaying: false));
    } else {
      emit(state.copyWith(isPlaying: true));
      _startTimer();
    }
  }

  void _onSeekTo(SeekToEvent event, Emitter<PlayerState> emit) =>
      emit(state.copyWith(progress: event.fraction.clamp(0.0, 1.0)));

  void _onSkipNext(SkipNextEvent event, Emitter<PlayerState> emit) {
    if (state.queue.isEmpty) return;
    final nextIdx = state.isShuffle
        ? Random().nextInt(state.queue.length)
        : (state.queueIndex + 1) % state.queue.length;
    emit(state.copyWith(queueIndex: nextIdx));
    _playSong(state.queue[nextIdx], emit);
  }

  void _onSkipPrevious(SkipPreviousEvent event, Emitter<PlayerState> emit) {
    if (state.progress > 0.05) {
      emit(state.copyWith(progress: 0.0));
      return;
    }
    if (state.queue.isEmpty) return;
    final prevIdx =
        (state.queueIndex - 1 + state.queue.length) % state.queue.length;
    emit(state.copyWith(queueIndex: prevIdx));
    _playSong(state.queue[prevIdx], emit);
  }

  void _onToggleShuffle(ToggleShuffleEvent event, Emitter<PlayerState> emit) =>
      emit(state.copyWith(isShuffle: !state.isShuffle));

  void _onToggleRepeat(ToggleRepeatEvent event, Emitter<PlayerState> emit) =>
      emit(state.copyWith(isRepeat: !state.isRepeat));

  void _onToggleLike(ToggleLikeEvent event, Emitter<PlayerState> emit) {
    final liked = List<String>.from(state.likedSongIds);
    liked.contains(event.song.id)
        ? liked.remove(event.song.id)
        : liked.add(event.song.id);
    emit(state.copyWith(likedSongIds: liked));
  }

  void _onSetVolume(SetVolumeEvent event, Emitter<PlayerState> emit) =>
      emit(state.copyWith(volume: event.volume.clamp(0.0, 1.0)));

  void _onProgressTick(_ProgressTickEvent event, Emitter<PlayerState> emit) {
    if (!state.isPlaying) return;
    final newProgress = state.progress + event.delta;
    if (newProgress >= 1.0) {
      if (state.isRepeat) {
        emit(state.copyWith(progress: 0.0));
      } else if (state.queue.length > 1) {
        add(const SkipNextEvent());
      } else {
        _progressTimer?.cancel();
        emit(state.copyWith(progress: 1.0, isPlaying: false));
      }
    } else {
      emit(state.copyWith(progress: newProgress));
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  void _playSong(Song song, Emitter<PlayerState> emit) {
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
    final delta = tickMs / totalMs;

    _progressTimer = Timer.periodic(
      const Duration(milliseconds: tickMs),
      (_) {
        if (!isClosed) add(_ProgressTickEvent(delta));
      },
    );
  }

  @override
  Future<void> close() {
    _progressTimer?.cancel();
    return super.close();
  }
}
