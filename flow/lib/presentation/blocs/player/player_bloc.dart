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
// Uses ConcatenatingAudioSource for smooth transitions and pre-buffering.
// ─────────────────────────────────────────────────────────────────────────────

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioPlayer _audioPlayer;
  final LocalStorage _storage;
  final WindowsMediaSession _mediaSession;
  final SongRepository _songRepository;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<Duration>? _bufferedSub;
  StreamSubscription<ja.PlayerState>? _playerStateSub;
  StreamSubscription<int?>? _currentIndexSub;

  /// The active playlist for just_audio.
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(
    children: [],
  );

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
    on<_BufferedPositionChangedEvent>(_onBufferedPositionChanged);
    on<_BufferingChangedEvent>(_onBufferingChanged);
    on<_InitialLoadingChangedEvent>(_onInitialLoadingChanged);
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
    _positionSub = _audioPlayer.positionStream.listen((pos) {
      if (!isClosed) add(_PositionUpdateEvent(pos, _audioPlayer.duration));
    });

    _durationSub = _audioPlayer.durationStream.listen((dur) {
      if (!isClosed && dur != null) {
        add(_PositionUpdateEvent(_audioPlayer.position, dur));
      }
    });

    _bufferedSub = _audioPlayer.bufferedPositionStream.listen((pos) {
      if (!isClosed) add(_BufferedPositionChangedEvent(pos));
    });

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

    _currentIndexSub = _audioPlayer.currentIndexStream.listen((idx) {
      if (isClosed || idx == null || idx >= state.queue.length) return;
      if (idx != state.queueIndex) {
        _onAutoTrackChange(idx);
      }
    });
  }

  void _onAutoTrackChange(int newIndex) {
    final song = state.queue[newIndex];
    AppLogger.i(_tag, 'Auto-advanced to: "${song.title}" (idx=$newIndex)');

    final recent = [
      song,
      ...state.recentlyPlayed.where((s) => s.id != song.id),
    ];
    if (recent.length > 20) recent.removeLast();
    _storage.saveRecentlyPlayedIds(recent.map((s) => s.id).toList());

    _mediaSession.updateSong(song);

    // Prefetch radio if we're near the end of the queue
    if (state.queue.length - newIndex < 3 && state.queue.isNotEmpty) {
      _fetchMoreRadioTracks();
    }

    emit(
      state.copyWith(
        currentSong: song,
        queueIndex: newIndex,
        recentlyPlayed: recent,
        position: Duration.zero,
        bufferedPosition: Duration.zero,
        clearActualDuration: true,
      ),
    );
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

  Future<void> _onPlayQueue(
    PlayQueueEvent event,
    Emitter<PlayerState> emit,
  ) async {
    if (event.songs.isEmpty) return;
    final idx = event.startIndex.clamp(0, event.songs.length - 1);

    emit(
      state.copyWith(
        queue: List.from(event.songs),
        queueIndex: idx,
        currentSong: event.songs[idx],
        isInitialLoading: true,
      ),
    );

    await _updatePlaylist(event.songs, initialIndex: idx);
    add(const _InitialLoadingChangedEvent(false));
  }

  Future<void> _onPlaySingle(
    PlaySingleEvent event,
    Emitter<PlayerState> emit,
  ) async {
    emit(
      state.copyWith(
        queue: [event.song],
        queueIndex: 0,
        currentSong: event.song,
        isInitialLoading: true,
      ),
    );

    await _updatePlaylist([event.song]);
    add(const _InitialLoadingChangedEvent(false));
  }

  Future<void> _onPlayRadio(
    PlayRadioEvent event,
    Emitter<PlayerState> emit,
  ) async {
    emit(
      state.copyWith(
        queue: [event.song],
        queueIndex: 0,
        currentSong: event.song,
        isInitialLoading: true,
      ),
    );
    await _updatePlaylist([event.song]);
    add(const _InitialLoadingChangedEvent(false));

    _fetchMoreRadioTracks();
  }

  Future<void> _fetchMoreRadioTracks() async {
    if (state.queue.isEmpty) return;
    final anchor = state.queue.last;
    try {
      final tracks = await _songRepository.getRadioTracks(anchor.id);
      if (isClosed) return;

      final existingIds = state.queue.map((s) => s.id).toSet();
      final newTracks = tracks
          .where((t) => !existingIds.contains(t.id))
          .toList();

      if (newTracks.isNotEmpty) {
        final updatedQueue = [...state.queue, ...newTracks];
        for (final t in newTracks) {
          await _playlist.add(_buildAudioSource(t));
        }
        emit(state.copyWith(queue: updatedQueue));
      }
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to fetch radio tracks', e, st);
    }
  }

  Future<void> _updatePlaylist(List<Song> songs, {int initialIndex = 0}) async {
    await _playlist.clear();
    for (final song in songs) {
      await _playlist.add(_buildAudioSource(song));
    }

    try {
      await _audioPlayer.setAudioSource(
        _playlist,
        initialIndex: initialIndex,
        initialPosition: Duration.zero,
      );

      final current = songs[initialIndex];
      _mediaSession.updateSong(current);
      _mediaSession.setPlaybackStatus(true);

      await _audioPlayer.play();
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to set AudioSource', e, st);
    }
  }

  AudioSource _buildAudioSource(Song song) {
    final streamUrl = '${ServerConfig.instance.baseUrl}/v1/stream/${song.id}';
    final token = _storage.jwtToken;
    return AudioSource.uri(
      Uri.parse(streamUrl),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
      tag: MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album.isNotEmpty ? song.album : song.artist,
        artUri: song.thumbnailUrl != null
            ? Uri.parse(song.thumbnailUrl!)
            : null,
      ),
    );
  }

  void _onTogglePlayPause(
    TogglePlayPauseEvent event,
    Emitter<PlayerState> emit,
  ) {
    if (state.isPlaying) {
      _audioPlayer.pause();
      _mediaSession.setPlaybackStatus(false);
      emit(state.copyWith(isPlaying: false));
    } else {
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
    if (dur != null) {
      final target = Duration(
        milliseconds: (event.fraction * dur.inMilliseconds).round(),
      );
      _audioPlayer.seek(target);
    }
  }

  void _onSkipNext(SkipNextEvent event, Emitter<PlayerState> emit) {
    if (_audioPlayer.hasNext) {
      _audioPlayer.seekToNext();
    } else if (state.currentSong != null) {
      add(PlayRadioEvent(state.currentSong!));
    }
  }

  void _onSkipPrevious(SkipPreviousEvent event, Emitter<PlayerState> emit) {
    if (state.progress > 0.05 || !_audioPlayer.hasPrevious) {
      _audioPlayer.seek(Duration.zero);
    } else {
      _audioPlayer.seekToPrevious();
    }
  }

  void _onToggleShuffle(ToggleShuffleEvent event, Emitter<PlayerState> emit) {
    final next = !state.isShuffle;
    _storage.saveShuffle(next);
    _audioPlayer.setShuffleModeEnabled(next);
    emit(state.copyWith(isShuffle: next));
  }

  void _onToggleRepeat(ToggleRepeatEvent event, Emitter<PlayerState> emit) {
    final next = !state.isRepeat;
    _storage.saveRepeat(next);
    _audioPlayer.setLoopMode(next ? LoopMode.one : LoopMode.off);
    emit(state.copyWith(isRepeat: next));
  }

  void _onToggleLike(ToggleLikeEvent event, Emitter<PlayerState> emit) {
    final liked = List<String>.from(state.likedSongIds);
    if (liked.contains(event.song.id)) {
      liked.remove(event.song.id);
    } else {
      liked.add(event.song.id);
    }
    _storage.saveLikedSongIds(liked);
    emit(state.copyWith(likedSongIds: liked));
  }

  void _onSetVolume(SetVolumeEvent event, Emitter<PlayerState> emit) {
    final vol = event.volume.clamp(0.0, 1.0);
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
    if (event.duration != null && event.position.inSeconds % 2 == 0) {
      _mediaSession.updateTimeline(event.position, event.duration!);
    }
  }

  void _onBufferedPositionChanged(
    _BufferedPositionChangedEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(bufferedPosition: event.bufferedPosition));
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

  void _onInitialLoadingChanged(
    _InitialLoadingChangedEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(isInitialLoading: event.isInitialLoading));
  }

  void _onTrackCompleted(
    _TrackCompletedEvent event,
    Emitter<PlayerState> emit,
  ) {
    if (!state.isRepeat && !_audioPlayer.hasNext) {
      _mediaSession.setStopped();
      emit(state.copyWith(isPlaying: false));
    }
  }

  @override
  Future<void> close() async {
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _bufferedSub?.cancel();
    await _playerStateSub?.cancel();
    await _currentIndexSub?.cancel();
    await _audioPlayer.dispose();
    await _mediaSession.dispose();
    return super.close();
  }
}
