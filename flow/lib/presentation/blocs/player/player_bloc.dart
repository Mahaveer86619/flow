import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart' show Color, NetworkImage;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:palette_generator/palette_generator.dart';
import 'package:just_audio/just_audio.dart'
    show
        AudioPlayer,
        ConcatenatingAudioSource,
        AudioSource,
        LoopMode,
        LockCachingAudioSource;
import '../../../core/config/server_config.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/platform/windows_media_session.dart';
import '../../../core/storage/local_storage.dart';
import '../../../domain/entities/song.dart';

import '../../../core/network/download_service.dart';
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

  bool _isChangingSource = false;
  bool _isFetchingRadio = false;
  int _retryCount = 0;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<Duration>? _bufferedSub;
  StreamSubscription<ja.PlayerState>? _playerStateSub;
  StreamSubscription<ja.PlaybackEvent>? _playbackErrorSub;
  StreamSubscription<int?>? _currentIndexSub;
  StreamSubscription<Map<String, double>>? _downloadSub;

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
    on<PlayEvent>(_onPlay);
    on<PauseEvent>(_onPause);
    on<SeekToEvent>(_onSeekTo);
    on<SkipNextEvent>(_onSkipNext);
    on<SkipPreviousEvent>(_onSkipPrevious);
    on<FastForwardEvent>(_onFastForward);
    on<RewindEvent>(_onRewind);
    on<ToggleShuffleEvent>(_onToggleShuffle);
    on<ToggleRepeatEvent>(_onToggleRepeat);
    on<ToggleEndlessRadioEvent>(_onToggleEndlessRadio);
    on<PlayDownloadedRadioEvent>(_onPlayDownloadedRadio);
    on<SkipToQueueIndexEvent>(_onSkipToQueueIndex);
    on<ToggleLikeEvent>(_onToggleLike);
    on<ToggleDownloadEvent>(_onToggleDownload);
    on<SetVolumeEvent>(_onSetVolume);
    on<_PositionUpdateEvent>(_onPositionUpdate);
    on<_BufferedPositionChangedEvent>(_onBufferedPositionChanged);
    on<_BufferingChangedEvent>(_onBufferingChanged);
    on<_InitialLoadingChangedEvent>(_onInitialLoadingChanged);
    on<_DownloadProgressUpdatedEvent>(_onDownloadProgressUpdated);
    on<_TrackCompletedEvent>(_onTrackCompleted);
    on<_TrackChangedEvent>(_onTrackChanged);
    on<_PlayStateChangedEvent>(_onPlayStateChanged);
    on<_QueueUpdatedEvent>(_onQueueUpdated);
    on<_RecentlyPlayedUpdatedEvent>(_onRecentlyPlayedUpdated);
    on<_RestoreStateEvent>(_onRestoreState);
    on<_PaletteUpdatedEvent>(_onPaletteUpdated);

    _subscribeToPlayer();
    _subscribeToDownloads();
    add(const _RestoreStateEvent());

    // Initialise Windows SMTC — no-op on other platforms
    _mediaSession.init(
      onPlay: () {
        if (!isClosed) add(const PlayEvent());
      },
      onPause: () {
        if (!isClosed) add(const PauseEvent());
      },
      onNext: () {
        if (!isClosed) add(const SkipNextEvent());
      },
      onPrevious: () {
        if (!isClosed) add(const SkipPreviousEvent());
      },
      onFastForward: () {
        if (!isClosed) add(const FastForwardEvent());
      },
      onRewind: () {
        if (!isClosed) add(const RewindEvent());
      },
    );
  }

  // ── AudioPlayer subscriptions ─────────────────────────────────────────────

  void _subscribeToPlayer() {
    DateTime lastPositionUpdate = DateTime.fromMillisecondsSinceEpoch(0);
    DateTime lastBufferedUpdate = DateTime.fromMillisecondsSinceEpoch(0);

    _positionSub = _audioPlayer.positionStream.listen((pos) {
      if (isClosed) return;
      final now = DateTime.now();
      // Throttle position updates to ~5 times per second (200ms)
      if (now.difference(lastPositionUpdate).inMilliseconds > 200) {
        lastPositionUpdate = now;
        add(_PositionUpdateEvent(pos, _audioPlayer.duration));
      }
    });

    _durationSub = _audioPlayer.durationStream.listen((dur) {
      if (!isClosed && dur != null) {
        add(_PositionUpdateEvent(_audioPlayer.position, dur));
      }
    });

    _bufferedSub = _audioPlayer.bufferedPositionStream.listen((pos) {
      if (isClosed) return;
      final now = DateTime.now();
      // Throttle buffered updates to once per second
      if (now.difference(lastBufferedUpdate).inMilliseconds > 1000) {
        lastBufferedUpdate = now;
        add(_BufferedPositionChangedEvent(pos));
      }
    });

    _playerStateSub = _audioPlayer.playerStateStream.listen((ps) {
      if (isClosed) return;
      if (ps.processingState == ja.ProcessingState.completed) {
        add(const _TrackCompletedEvent());
      } else {
        final buffering =
            ps.processingState == ja.ProcessingState.loading ||
            ps.processingState == ja.ProcessingState.buffering;

        // Safety: ensure isInitialLoading is cleared once we are ready or playing
        if (state.isInitialLoading &&
            (ps.processingState == ja.ProcessingState.ready || ps.playing)) {
          add(const _InitialLoadingChangedEvent(false));
        }

        add(
          _BufferingChangedEvent(isBuffering: buffering, isPlaying: ps.playing),
        );
      }
    });

    _playbackErrorSub = _audioPlayer.playbackEventStream.listen(
      (event) {
        // This stream also emits regular events, but we care about errors
      },
      onError: (Object e, StackTrace st) async {
        if (isClosed) return;
        AppLogger.e(_tag, 'Playback error (retry=$_retryCount)', e, st);

        if (_retryCount < 3) {
          _retryCount++;
          // Wait a bit before retrying to allow network to recover
          await Future.delayed(Duration(seconds: _retryCount));
          if (!isClosed) {
            _audioPlayer.play();
          }
        } else {
          AppLogger.w(_tag, 'Retry limit reached, skipping to next track');
          _retryCount = 0;
          add(const SkipNextEvent());
        }
      },
    );

    _currentIndexSub = _audioPlayer.currentIndexStream.listen((idx) {
      if (isClosed ||
          idx == null ||
          _isChangingSource ||
          idx >= state.queue.length) {
        return;
      }
      if (idx != state.queueIndex) {
        add(_TrackChangedEvent(idx));
      }
    });
  }

  void _subscribeToDownloads() {
    _downloadSub = DownloadService.instance.progressStream.listen((prog) {
      if (!isClosed) add(_DownloadProgressUpdatedEvent(prog));
    });
  }

  void _onTrackChanged(_TrackChangedEvent event, Emitter<PlayerState> emit) {
    final newIndex = event.index;
    if (newIndex >= state.queue.length) return;

    _retryCount = 0; // Reset for new track
    final song = state.queue[newIndex];
    AppLogger.i(_tag, 'Auto-advanced to: "${song.title}" (idx=$newIndex)');

    // Record play in persistent history
    _songRepository.recordPlay(song);

    final recent = [
      song,
      ...state.recentlyPlayed.where((s) => s.id != song.id),
    ];
    if (recent.length > 20) recent.removeLast();
    _storage.saveRecentlyPlayedIds(recent.map((s) => s.id).toList());

    _mediaSession.updateSong(song);

    // Prefetch radio if we're near the end of the queue
    if (state.isEndlessRadio &&
        state.queue.length - newIndex < 3 &&
        state.queue.isNotEmpty) {
      _fetchMoreRadioTracks();
    }

    // Prefetch surrounding tracks
    _prefetchSurroundingTracks(newIndex);

    emit(
      state.copyWith(
        currentSong: song,
        queueIndex: newIndex,
        recentlyPlayed: recent,
        position: Duration.zero,
        bufferedPosition: Duration.zero,
        clearActualDuration: true,
        clearCustomColors: true,
      ),
    );

    _extractPalette(song);
  }

  void _prefetchSurroundingTracks(int currentIndex) {
    if (state.queue.isEmpty) return;

    final List<int> indicesToPrefetch = [];

    // Always prefetch current if not already ready (though it's playing)
    indicesToPrefetch.add(currentIndex);

    if (currentIndex == 0) {
      // First song: prefetch next two
      if (state.queue.length > 1) indicesToPrefetch.add(1);
      if (state.queue.length > 2) indicesToPrefetch.add(2);
    } else {
      // Has previous: prefetch previous and next
      indicesToPrefetch.add(currentIndex - 1);
      if (currentIndex + 1 < state.queue.length) {
        indicesToPrefetch.add(currentIndex + 1);
      }
    }

    for (final idx in indicesToPrefetch.toSet()) {
      if (idx >= 0 && idx < state.queue.length) {
        final song = state.queue[idx];
        AppLogger.d(_tag, 'Prefetching track at index $idx: ${song.title}');
        _songRepository.prefetchAudio(song.id);
      }
    }
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  void _onRestoreState(_RestoreStateEvent event, Emitter<PlayerState> emit) {
    final likedIds = _storage.likedSongIds;
    final recentIds = _storage.recentlyPlayedIds;
    final volume = _storage.volume;
    final shuffle = _storage.isShuffle;
    final repeat = _storage.isRepeat;

    AppLogger.i(
      _tag,
      'Restored — liked=${likedIds.length} recent=${recentIds.length} '
      'vol=$volume shuffle=$shuffle repeat=$repeat',
    );

    _audioPlayer.setVolume(volume);

    // Initial state with persisted IDs
    emit(
      state.copyWith(
        likedSongIds: likedIds,
        recentlyPlayedIds: recentIds,
        volume: volume,
        isShuffle: shuffle,
        isRepeat: repeat,
      ),
    );

    // If we have recent IDs, we might want to fetch the actual song objects
    // for the UI to display them immediately.
    if (recentIds.isNotEmpty) {
      _hydrateRecentlyPlayed(recentIds);
    }
  }

  Future<void> _hydrateRecentlyPlayed(List<String> ids) async {
    try {
      final songs = await _songRepository.getSongsByIds(ids);
      if (!isClosed) {
        add(_RecentlyPlayedUpdatedEvent(songs));
      }
    } catch (e) {
      AppLogger.w(_tag, 'Failed to hydrate recently played: $e');
    }
  }

  void _onRecentlyPlayedUpdated(
    _RecentlyPlayedUpdatedEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(recentlyPlayed: event.recentlyPlayed));
  }

  // ── Event handlers ────────────────────────────────────────────────────────

  Future<void> _onPlayQueue(
    PlayQueueEvent event,
    Emitter<PlayerState> emit,
  ) async {
    if (event.songs.isEmpty) return;
    _retryCount = 0;
    final idx = event.startIndex.clamp(0, event.songs.length - 1);

    final song = event.songs[idx];
    _songRepository.recordPlay(song);

    // Stop and reset before setting new source to avoid threading issues on Windows
    await _audioPlayer.stop();

    emit(
      state.copyWith(
        queue: List.from(event.songs),
        queueIndex: idx,
        currentSong: song,
        isPlaying: false,
        isInitialLoading: true,
        position: Duration.zero,
        bufferedPosition: Duration.zero,
        clearActualDuration: true,
        clearCustomColors: true,
      ),
    );

    _extractPalette(song);
    await _updatePlaylist(event.songs, initialIndex: idx);
  }

  Future<void> _onPlaySingle(
    PlaySingleEvent event,
    Emitter<PlayerState> emit,
  ) async {
    _retryCount = 0;
    _songRepository.recordPlay(event.song);
    await _audioPlayer.stop();

    emit(
      state.copyWith(
        queue: [event.song],
        queueIndex: 0,
        currentSong: event.song,
        isPlaying: false,
        isInitialLoading: true,
        position: Duration.zero,
        bufferedPosition: Duration.zero,
        clearActualDuration: true,
        clearCustomColors: true,
      ),
    );

    _extractPalette(event.song);
    await _updatePlaylist([event.song]);
  }

  Future<void> _onPlayRadio(
    PlayRadioEvent event,
    Emitter<PlayerState> emit,
  ) async {
    _retryCount = 0;
    _songRepository.recordPlay(event.song);
    emit(
      state.copyWith(
        queue: [event.song],
        queueIndex: 0,
        currentSong: event.song,
        isInitialLoading: true,
        clearCustomColors: true,
      ),
    );
    _extractPalette(event.song);
    await _updatePlaylist([event.song]);

    _fetchMoreRadioTracks();
  }

  Future<void> _fetchMoreRadioTracks() async {
    if (state.queue.isEmpty || _isFetchingRadio) return;
    _isFetchingRadio = true;
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
          final source = await _buildAudioSource(t);
          await _playlist.add(source);
        }
        add(_QueueUpdatedEvent(updatedQueue));
      }
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to fetch radio tracks', e, st);
    } finally {
      _isFetchingRadio = false;
    }
  }

  void _onQueueUpdated(_QueueUpdatedEvent event, Emitter<PlayerState> emit) {
    emit(state.copyWith(queue: event.queue));
  }

  Future<void> _updatePlaylist(List<Song> songs, {int initialIndex = 0}) async {
    try {
      AppLogger.i(
        _tag,
        'Updating playlist: songs=${songs.length} index=$initialIndex',
      );
      _isChangingSource = true;

      // 1. Clear and batch-add for efficiency
      await _playlist.clear();
      final sources = await Future.wait(songs.map((s) => _buildAudioSource(s)));
      await _playlist.addAll(sources);

      // 2. Set source with initial state
      await _audioPlayer.setAudioSource(
        _playlist,
        initialIndex: initialIndex,
        initialPosition: Duration.zero,
      );

      // 3. Update metadata & SMTC
      final current = songs[initialIndex];
      _mediaSession.updateSong(current);
      _mediaSession.setPlaybackStatus(true);

      // Safety: ensure 3 tracks are ready (previous, current, next)
      _prefetchSurroundingTracks(initialIndex);

      // We are essentially "done" with the initial source change here
      add(const _InitialLoadingChangedEvent(false));

      // Allow streams to settle
      await Future.delayed(const Duration(milliseconds: 300));
      _isChangingSource = false;

      AppLogger.d(_tag, 'Starting playback for: ${current.title}');

      // 4. Start playback - AudioPlayer stream will handle isPlaying state update
      await _audioPlayer.play();

      // Double check - on some platforms (like Windows/Linux) just_audio
      // sometimes needs a nudge if the first attempt didn't transition to playing
      if (!_audioPlayer.playing && !isClosed) {
        AppLogger.w(_tag, 'Playback didn\'t start, retrying play() in 200ms');
        await Future.delayed(const Duration(milliseconds: 200));
        await _audioPlayer.play();
      }
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to set AudioSource or Play', e, st);
      _isChangingSource = false;
    }
  }

  void _onPlayStateChanged(
    _PlayStateChangedEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(isPlaying: event.isPlaying));
  }

  Future<AudioSource> _buildAudioSource(
    Song song, {
    bool? isLikedOverride,
  }) async {
    final token = _storage.jwtToken;
    final isLiked = isLikedOverride ?? state.likedSongIds.contains(song.id);

    // 1. Check if downloaded (Check metadata and physical file)
    final downloadMetadata = _storage.getDownloadMetadata(song.id);
    final downloadedPath = _storage.getDownloadedPath(song.id);

    bool useLocal = false;
    File? localFile;
    String? effectiveThumbnailUrl = song.thumbnailUrl;

    if (downloadedPath != null) {
      localFile = File(downloadedPath);
      if (await localFile.exists()) {
        useLocal = true;
        // Use local thumb if available in metadata
        if (downloadMetadata != null &&
            downloadMetadata['thumbnailUrl'] != null) {
          effectiveThumbnailUrl = downloadMetadata['thumbnailUrl'] as String;
        }
      }
    }

    Uri? artUri;
    if (effectiveThumbnailUrl != null) {
      if (effectiveThumbnailUrl.startsWith('http')) {
        artUri = Uri.parse(effectiveThumbnailUrl);
      } else {
        // Local path
        final thumbFile = File(effectiveThumbnailUrl);
        if (await thumbFile.exists()) {
          artUri = Uri.file(effectiveThumbnailUrl);
        } else if (song.thumbnailUrl != null &&
            song.thumbnailUrl!.startsWith('http')) {
          // Fallback to remote if local thumb is missing but remote is known
          artUri = Uri.parse(song.thumbnailUrl!);
        }
      }
    }

    final mediaItem = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album.isNotEmpty ? song.album : song.artist,
      duration: song.duration,
      artUri: artUri,
      rating: Rating.newHeartRating(isLiked),
      extras: <String, dynamic>{
        'isLiked': isLiked,
        'isLocal': useLocal,
        // Ensure only 3 controls in compact view: Previous, Play/Pause, Next
        'androidCompactControlIndices': [0, 1, 2],
        // Hint to show heart button if supported
        'displayRating': true,
      },
    );

    if (useLocal && localFile != null) {
      AppLogger.i(
        _tag,
        'Building local AudioSource for: ${song.title} (Path: ${localFile.path})',
      );
      return AudioSource.file(localFile.path, tag: mediaItem);
    } else {
      final streamUrl = '${ServerConfig.instance.baseUrl}/v1/stream/${song.id}';
      final uri = Uri.parse(streamUrl);
      final headers = {
        if (token != null) 'Authorization': 'Bearer $token',
        'User-Agent': 'FlowMusicApp/1.0',
      };

      // LockCachingAudioSource has known file-locking and proxy issues on Windows.
      // We'll skip caching on Windows to ensure playback works correctly.
      if (Platform.isWindows) {
        AppLogger.i(
          _tag,
          'Building standard URI source for Windows: ${song.title}',
        );
        return AudioSource.uri(uri, headers: headers, tag: mediaItem);
      }

      // Use LockCachingAudioSource to enable caching for repeats and seeking back on other platforms
      return LockCachingAudioSource(uri, headers: headers, tag: mediaItem);
    }
  }

  void _onTogglePlayPause(
    TogglePlayPauseEvent event,
    Emitter<PlayerState> emit,
  ) {
    if (state.isPlaying) {
      add(const PauseEvent());
    } else {
      add(const PlayEvent());
    }
  }

  void _onPlay(PlayEvent event, Emitter<PlayerState> emit) {
    _audioPlayer.play();
    _mediaSession.setPlaybackStatus(true);
    // isPlaying state will be updated by _audioPlayer.playerStateStream -> _onBufferingChanged
  }

  void _onPause(PauseEvent event, Emitter<PlayerState> emit) {
    _audioPlayer.pause();
    _mediaSession.setPlaybackStatus(false);
    // isPlaying state will be updated by _audioPlayer.playerStateStream -> _onBufferingChanged
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

  void _onRewind(RewindEvent event, Emitter<PlayerState> emit) {
    final target = _audioPlayer.position - const Duration(seconds: 10);
    if (target > Duration.zero) {
      _audioPlayer.seek(target);
    } else {
      _audioPlayer.seek(Duration.zero);
    }
  }

  void _onFastForward(FastForwardEvent event, Emitter<PlayerState> emit) {
    final target = _audioPlayer.position + const Duration(seconds: 10);
    final total = _audioPlayer.duration ?? Duration.zero;
    if (target < total) {
      _audioPlayer.seek(target);
    } else {
      _audioPlayer.seekToNext();
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

  void _onToggleEndlessRadio(
    ToggleEndlessRadioEvent event,
    Emitter<PlayerState> emit,
  ) {
    final next = !state.isEndlessRadio;
    emit(state.copyWith(isEndlessRadio: next));
    if (next && state.queue.length - state.queueIndex < 3) {
      _fetchMoreRadioTracks();
    }
  }

  Future<void> _onPlayDownloadedRadio(
    PlayDownloadedRadioEvent event,
    Emitter<PlayerState> emit,
  ) async {
    final ids = DownloadService.instance.getDownloadedIds();
    if (ids.isEmpty) return;

    emit(state.copyWith(isInitialLoading: true));

    try {
      final songs = await _songRepository.getSongsByIds(ids);
      if (songs.isEmpty) {
        emit(state.copyWith(isInitialLoading: false));
        return;
      }

      final shuffled = List<Song>.from(songs)..shuffle();

      emit(
        state.copyWith(
          queue: shuffled,
          queueIndex: 0,
          currentSong: shuffled[0],
          isInitialLoading: true,
          isEndlessRadio: false, // Don't fetch remote tracks in offline mode
          clearCustomColors: true,
        ),
      );

      _extractPalette(shuffled[0]);
      await _updatePlaylist(shuffled);
    } catch (e) {
      AppLogger.e(_tag, 'Failed to start downloaded radio', e);
      emit(state.copyWith(isInitialLoading: false));
    }
  }

  void _onToggleLike(ToggleLikeEvent event, Emitter<PlayerState> emit) {
    final liked = List<String>.from(state.likedSongIds);
    final isNowLiked = !liked.contains(event.song.id);
    if (liked.contains(event.song.id)) {
      liked.remove(event.song.id);
    } else {
      liked.add(event.song.id);
    }
    _storage.saveLikedSongIds(liked);

    // Update the tag in the playlist if it's currently in the queue
    final idx = state.queue.indexWhere((s) => s.id == event.song.id);
    if (idx != -1) {
      _buildAudioSource(event.song, isLikedOverride: isNowLiked).then((
        newSource,
      ) {
        if (!isClosed) {
          final currentIndex = _audioPlayer.currentIndex;
          // Only replace if it's NOT the current playing song to avoid skipping
          if (idx != currentIndex) {
            _playlist.removeAt(idx);
            _playlist.insert(idx, newSource);
          }
        }
      });
    }

    emit(state.copyWith(likedSongIds: liked));
  }

  Future<void> _onToggleDownload(
    ToggleDownloadEvent event,
    Emitter<PlayerState> emit,
  ) async {
    final song = event.song;
    final isDownloaded = await DownloadService.instance.isDownloaded(song.id);

    try {
      if (isDownloaded) {
        await DownloadService.instance.deleteDownload(song.id);
      } else {
        await DownloadService.instance.downloadSong(song);
      }

      // Update current song if it's the one being downloaded
      if (state.currentSong?.id == song.id) {
        emit(
          state.copyWith(
            currentSong: state.currentSong!.copyWith(
              isDownloaded: !isDownloaded,
            ),
          ),
        );
      }

      // Update queue
      final newQueue = state.queue.map((s) {
        if (s.id == song.id) {
          return s.copyWith(isDownloaded: !isDownloaded);
        }
        return s;
      }).toList();
      emit(state.copyWith(queue: newQueue));
    } catch (e) {
      AppLogger.e(_tag, 'Toggle download failed', e);
    }
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
    // If the song is already fully cached/downloaded, ensure bufferedPosition is at max
    final isFullyCached =
        _audioPlayer.bufferedPosition >= (event.duration ?? Duration.zero);

    emit(
      state.copyWith(
        position: event.position,
        actualDuration: event.duration,
        bufferedPosition: isFullyCached ? event.duration : null,
      ),
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

  void _onDownloadProgressUpdated(
    _DownloadProgressUpdatedEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(downloadProgress: event.progress));
  }

  void _onSkipToQueueIndex(
    SkipToQueueIndexEvent event,
    Emitter<PlayerState> emit,
  ) {
    if (event.index >= 0 && event.index < state.queue.length) {
      _audioPlayer.seek(Duration.zero, index: event.index);
    }
  }

  void _onTrackCompleted(
    _TrackCompletedEvent event,
    Emitter<PlayerState> emit,
  ) {
    if (!state.isRepeat && !_audioPlayer.hasNext) {
      if (state.isEndlessRadio && state.currentSong != null) {
        // Fetch more tracks. Once added, just_audio will have a 'next' track.
        _fetchMoreRadioTracks().then((_) {
          if (!isClosed && _audioPlayer.hasNext && !state.isPlaying) {
            _audioPlayer.seekToNext();
            _audioPlayer.play();
          }
        });
      } else {
        _mediaSession.setStopped();
        emit(state.copyWith(isPlaying: false));
      }
    }
  }

  void _onPaletteUpdated(
    _PaletteUpdatedEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(
      state.copyWith(
        customPrimary: event.primary,
        customSecondary: event.secondary,
      ),
    );
  }

  Future<void> _extractPalette(Song song) async {
    if (song.thumbnailUrl == null) return;

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(song.thumbnailUrl!),
        maximumColorCount: 20,
      );

      final primary =
          palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          song.colorPrimary;
      final secondary =
          palette.mutedColor?.color ??
          palette.lightVibrantColor?.color ??
          song.colorSecondary;

      if (!isClosed) {
        add(_PaletteUpdatedEvent(primary, secondary));
      }
    } catch (e) {
      AppLogger.w(_tag, 'Palette extraction failed: $e');
    }
  }

  @override
  Future<void> close() async {
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _bufferedSub?.cancel();
    await _playerStateSub?.cancel();
    await _currentIndexSub?.cancel();
    await _downloadSub?.cancel();
    await _audioPlayer.dispose();
    await _mediaSession.dispose();
    return super.close();
  }
}
