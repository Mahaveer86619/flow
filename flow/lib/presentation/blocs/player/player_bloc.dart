import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:just_audio/just_audio.dart'
    as ja
    show PlayerState, ProcessingState;
import '../../../core/config/server_config.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/platform/windows_media_session.dart';
import '../../../core/storage/local_storage.dart';
import '../../../domain/entities/song.dart';

import '../../../domain/repositories/song_repository.dart';

part 'player_event.dart';
part 'player_state.dart';

// ── PlayerBloc ────────────────────────────────────────────────────────────────
//
// Drives actual audio playback via just_audio (AudioPlayer).
// Stream URL: GET $streamBaseUrl/api/stream/{videoId}  (server-side yt-dlp proxy)
//
// Background audio + lock-screen controls are handled by just_audio_background
// which wraps AudioPlayer transparently when JustAudioBackground.init() is
// called in main().
//
// Internal events (_PositionUpdateEvent, _BufferingChangedEvent,
// _TrackCompletedEvent) are dispatched by AudioPlayer stream subscriptions so
// all state mutations remain inside the BLoC and are fully testable.
// ─────────────────────────────────────────────────────────────────────────────

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioPlayer _audioPlayer;
  final LocalStorage _storage;
  final WindowsMediaSession _mediaSession;
  final SongRepository _songRepository;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<ja.PlayerState>? _playerStateSub;

  /// Tracks the most recent load request to prevent race conditions during rapid skips.
  int _currentLoadId = 0;

  static const _tag = 'PlayerBloc';

  PlayerBloc({
    required SongRepository songRepository,
    LocalStorage? storage,
    AudioPlayer? audioPlayer,
    WindowsMediaSession? mediaSession,
  }) : _songRepository = songRepository,
       _storage = storage ?? LocalStorage.instance,
       _audioPlayer = audioPlayer ?? AudioPlayer(),
       _mediaSession = mediaSession ?? WindowsMediaSession.instance,
       super(const PlayerState()) {
    on<PlayQueueEvent>(_onPlayQueue);
    on<PlaySingleEvent>(_onPlaySingle);
    on<PlayRadioEvent>(_onPlayRadio);
    on<TogglePlayPauseEvent>(_onTogglePlayPause);
    on<SeekToEvent>(_onSeekTo);
    on<SkipNextEvent>(_onSkipNext);
    on<SkipPreviousEvent>(_onSkipPrevious);
    on<ToggleShuffleEvent>(_onToggleShuffle);
    on<ToggleRepeatEvent>(_onToggleRepeat);
    on<ToggleLikeEvent>(_onToggleLike);
    on<SetVolumeEvent>(_onSetVolume);
    on<_PositionUpdateEvent>(_onPositionUpdate);
    on<_BufferingChangedEvent>(_onBufferingChanged);
    on<_TrackCompletedEvent>(_onTrackCompleted);

    on<_RestoreStateEvent>(_onRestoreState);

    _subscribeToPlayer();
    add(const _RestoreStateEvent());

    // Initialise Windows SMTC — no-op on other platforms
    _mediaSession.init(
      onPlay: () {
        if (!isClosed) add(const TogglePlayPauseEvent());
      },
      onPause: () {
        if (!isClosed) add(const TogglePlayPauseEvent());
      },
      onNext: () {
        if (!isClosed) add(const SkipNextEvent());
      },
      onPrevious: () {
        if (!isClosed) add(const SkipPreviousEvent());
      },
    );
  }

  // ── AudioPlayer subscriptions ─────────────────────────────────────────────

  void _subscribeToPlayer() {
    // Position updates — throttled to once per 500 ms by just_audio internally
    _positionSub = _audioPlayer.positionStream.listen((pos) {
      if (!isClosed) add(_PositionUpdateEvent(pos, _audioPlayer.duration));
    });

    // Duration updates (available once the stream is loaded)
    _durationSub = _audioPlayer.durationStream.listen((dur) {
      if (!isClosed && dur != null) {
        add(_PositionUpdateEvent(_audioPlayer.position, dur));
      }
    });

    // Buffering / playing state + completion detection
    _playerStateSub = _audioPlayer.playerStateStream.listen((ps) {
      if (isClosed) return;
      if (ps.processingState == ja.ProcessingState.completed) {
        add(const _TrackCompletedEvent());
      } else {
        final buffering =
            ps.processingState == ja.ProcessingState.loading ||
            ps.processingState == ja.ProcessingState.buffering;
        add(
          _BufferingChangedEvent(isBuffering: buffering, isPlaying: ps.playing),
        );
      }
    });
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  void _onRestoreState(_RestoreStateEvent event, Emitter<PlayerState> emit) {
    final likedIds = _storage.likedSongIds;
    final volume = _storage.volume;
    final shuffle = _storage.isShuffle;
    final repeat = _storage.isRepeat;
    AppLogger.i(
      _tag,
      'Restored — liked=${likedIds.length} vol=$volume '
      'shuffle=$shuffle repeat=$repeat',
    );
    _audioPlayer.setVolume(volume);
    emit(
      state.copyWith(
        likedSongIds: likedIds,
        volume: volume,
        isShuffle: shuffle,
        isRepeat: repeat,
      ),
    );
  }

  // ── Event handlers ────────────────────────────────────────────────────────

  void _onPlayQueue(PlayQueueEvent event, Emitter<PlayerState> emit) {
    if (event.songs.isEmpty) return;
    final idx = event.startIndex.clamp(0, event.songs.length - 1);
    AppLogger.i(_tag, 'PlayQueue: ${event.songs.length} songs, start=$idx');
    emit(state.copyWith(queue: List.from(event.songs), queueIndex: idx));
    _currentLoadId++;
    _playSong(event.songs[idx], emit, loadId: _currentLoadId);
  }

  void _onPlaySingle(PlaySingleEvent event, Emitter<PlayerState> emit) {
    AppLogger.i(_tag, 'PlaySingle: "${event.song.title}"');
    emit(state.copyWith(queue: [event.song], queueIndex: 0));
    _currentLoadId++;
    _playSong(event.song, emit, loadId: _currentLoadId);
  }

  Future<void> _onPlayRadio(
    PlayRadioEvent event,
    Emitter<PlayerState> emit,
  ) async {
    AppLogger.i(_tag, 'PlayRadio: "${event.song.title}"');
    // Start playing the anchor song immediately
    emit(state.copyWith(queue: [event.song], queueIndex: 0));
    _currentLoadId++;
    final myLoadId = _currentLoadId;
    _playSong(event.song, emit, loadId: myLoadId);

    try {
      // Fetch up-next tracks from the repository
      final tracks = await _songRepository.getRadioTracks(event.song.id);
      if (isClosed || myLoadId != _currentLoadId) return;

      // Filter out the anchor song if present and append to queue
      final newQueue = [
        event.song,
        ...tracks.where((t) => t.id != event.song.id),
      ];
      AppLogger.d(_tag, 'Radio queue built: ${newQueue.length} tracks');
      emit(state.copyWith(queue: newQueue));
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to fetch radio tracks', e, st);
    }
  }

  void _onTogglePlayPause(
    TogglePlayPauseEvent event,
    Emitter<PlayerState> emit,
  ) {
    if (state.isPlaying) {
      AppLogger.d(_tag, 'Pause');
      _audioPlayer.pause();
      _mediaSession.setPlaybackStatus(false);
      emit(state.copyWith(isPlaying: false));
    } else {
      AppLogger.d(_tag, 'Resume');
      _audioPlayer.play();
      _mediaSession.setPlaybackStatus(true);
      emit(state.copyWith(isPlaying: true));
    }
  }

  void _onSeekTo(SeekToEvent event, Emitter<PlayerState> emit) {
    final dur =
        _audioPlayer.duration ??
        state.actualDuration ??
        state.currentSong?.duration;
    if (dur != null && dur.inMilliseconds > 0) {
      final target = Duration(
        milliseconds: (event.fraction.clamp(0.0, 1.0) * dur.inMilliseconds)
            .round(),
      );
      AppLogger.d(
        _tag,
        'Seek → ${(event.fraction * 100).toStringAsFixed(1)}%  ($target)',
      );
      _audioPlayer.seek(target);
    }
  }

  void _onSkipNext(SkipNextEvent event, Emitter<PlayerState> emit) {
    if (state.queue.isEmpty) return;

    final isLast = state.queueIndex == state.queue.length - 1;

    if (isLast && !state.isShuffle && !state.isRepeat) {
      AppLogger.i(_tag, 'SkipNext → end of queue, starting radio');
      if (state.currentSong != null) {
        add(PlayRadioEvent(state.currentSong!));
      }
      return;
    }

    final nextIdx = state.isShuffle
        ? Random().nextInt(state.queue.length)
        : (state.queueIndex + 1) % state.queue.length;
    AppLogger.i(_tag, 'SkipNext → idx=$nextIdx');
    emit(state.copyWith(queueIndex: nextIdx));
    _currentLoadId++;
    _playSong(state.queue[nextIdx], emit, loadId: _currentLoadId);
  }

  void _onSkipPrevious(SkipPreviousEvent event, Emitter<PlayerState> emit) {
    // If more than 5 % into the track, restart instead of going back
    if (state.progress > 0.05) {
      AppLogger.d(_tag, 'SkipPrev: restart');
      _audioPlayer.seek(Duration.zero);
      return;
    }
    if (state.queue.isEmpty) return;
    final prevIdx =
        (state.queueIndex - 1 + state.queue.length) % state.queue.length;
    AppLogger.i(_tag, 'SkipPrev → idx=$prevIdx');
    emit(state.copyWith(queueIndex: prevIdx));
    _currentLoadId++;
    _playSong(state.queue[prevIdx], emit, loadId: _currentLoadId);
  }

  void _onToggleShuffle(ToggleShuffleEvent event, Emitter<PlayerState> emit) {
    final next = !state.isShuffle;
    AppLogger.i(_tag, 'Shuffle → $next');
    _storage.saveShuffle(next);
    emit(state.copyWith(isShuffle: next));
  }

  void _onToggleRepeat(ToggleRepeatEvent event, Emitter<PlayerState> emit) {
    final next = !state.isRepeat;
    AppLogger.i(_tag, 'Repeat → $next');
    _storage.saveRepeat(next);
    emit(state.copyWith(isRepeat: next));
  }

  void _onToggleLike(ToggleLikeEvent event, Emitter<PlayerState> emit) {
    final liked = List<String>.from(state.likedSongIds);
    if (liked.contains(event.song.id)) {
      liked.remove(event.song.id);
      AppLogger.i(_tag, 'Unlike: "${event.song.title}"');
    } else {
      liked.add(event.song.id);
      AppLogger.i(_tag, 'Like: "${event.song.title}"');
    }
    _storage.saveLikedSongIds(liked);
    emit(state.copyWith(likedSongIds: liked));
  }

  void _onSetVolume(SetVolumeEvent event, Emitter<PlayerState> emit) {
    final vol = event.volume.clamp(0.0, 1.0);
    AppLogger.d(_tag, 'Volume → ${(vol * 100).toStringAsFixed(0)}%');
    _audioPlayer.setVolume(vol);
    _storage.saveVolume(vol);
    emit(state.copyWith(volume: vol));
  }

  void _onPositionUpdate(
    _PositionUpdateEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(
      state.copyWith(position: event.position, actualDuration: event.duration),
    );
    // Throttle SMTC timeline updates to once every ~2 s to avoid overhead
    final pos = event.position;
    final dur = event.duration;
    if (dur != null && pos.inSeconds % 2 == 0) {
      _mediaSession.updateTimeline(pos, dur);
    }
  }

  void _onBufferingChanged(
    _BufferingChangedEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(
      state.copyWith(
        isBuffering: event.isBuffering,
        isPlaying: event.isPlaying,
      ),
    );
  }

  void _onTrackCompleted(
    _TrackCompletedEvent event,
    Emitter<PlayerState> emit,
  ) {
    if (state.isRepeat) {
      AppLogger.d(_tag, 'Track completed — repeat, restarting');
      _audioPlayer.seek(Duration.zero);
      _audioPlayer.play();
    } else if (state.queueIndex < state.queue.length - 1 || state.isShuffle) {
      AppLogger.d(_tag, 'Track completed — advancing to next');
      add(const SkipNextEvent());
    } else {
      AppLogger.d(_tag, 'Track completed — end of queue, starting radio');
      if (state.currentSong != null) {
        add(PlayRadioEvent(state.currentSong!));
      } else {
        _mediaSession.setStopped();
        emit(state.copyWith(isPlaying: false));
      }
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _playSong(Song song, Emitter<PlayerState> emit, {required int loadId}) {
    AppLogger.i(
      _tag,
      'Playing (loadId=$loadId): "${song.title}" by ${song.artist}',
    );

    // Update recently played
    final recent = [
      song,
      ...state.recentlyPlayed.where((s) => s.id != song.id),
    ];
    if (recent.length > 20) recent.removeLast();
    _storage.saveRecentlyPlayedIds(recent.map((s) => s.id).toList());

    // Emit loading state immediately so UI shows the new song
    emit(
      state.copyWith(
        currentSong: song,
        isPlaying: false,
        isBuffering: true,
        position: Duration.zero,
        clearActualDuration: true,
        recentlyPlayed: recent,
      ),
    );

    // Update Windows SMTC overlay immediately so media keys work straight away
    _mediaSession.updateSong(song);
    _mediaSession.setPlaybackStatus(true);

    // Fire-and-forget the actual stream load; AudioPlayer subscriptions will
    // update state via internal events once buffering/playing begins.
    _loadStream(song, loadId: loadId);
  }

  Future<void> _loadStream(Song song, {required int loadId}) async {
    final streamUrl = '${ServerConfig.instance.baseUrl}/api/stream/${song.id}';
    AppLogger.d(_tag, 'Loading stream (loadId=$loadId): $streamUrl');
    try {
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamUrl),
          tag: MediaItem(
            id: song.id,
            title: song.title,
            artist: song.artist,
            album: song.album.isNotEmpty ? song.album : song.artist,
            artUri: song.thumbnailUrl != null
                ? Uri.parse(song.thumbnailUrl!)
                : null,
          ),
        ),
      );
      if (isClosed || loadId != _currentLoadId) return;
      await _audioPlayer.play();
    } catch (e, st) {
      if (isClosed || loadId != _currentLoadId) {
        AppLogger.d(
          _tag,
          'Stream load for ${song.id} superseded or closed (loadId=$loadId)',
        );
        return;
      }
      AppLogger.e(
        _tag,
        'Stream load failed for ${song.id} (loadId=$loadId)',
        e,
        st,
      );
      // Skip to next on load failure so the queue keeps moving
      add(const SkipNextEvent());
    }
  }

  @override
  Future<void> close() async {
    AppLogger.i(_tag, 'Closing PlayerBloc');
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _playerStateSub?.cancel();
    await _audioPlayer.dispose();
    await _mediaSession.dispose();
    return super.close();
  }
}
