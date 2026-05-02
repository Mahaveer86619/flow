import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart'
    show Color, NetworkImage, ImageProvider, FileImage;
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
import '../../../core/logger/app_logger.dart';
import '../../../core/platform/windows_media_session.dart';
import '../../../core/storage/local_storage.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/track.dart' as domain;
import '../../../core/intelligence/app_intelligence.dart';
import '../../../domain/entities/scoring_graph.dart' as domain;
import '../../../domain/engines/mood_engine.dart';
import '../../../data/sources/local/download_service.dart';
import '../../../data/sources/local/cache_service.dart';
import '../../../domain/repositories/music_repository.dart';
import '../../../data/sources/remote/stream_resolver.dart';
import '../../../core/network/lan_stream_bridge.dart';
import '../../../core/network/peer_manager.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../cubits/settings/settings_state.dart';

part 'player_event.dart';
part 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioPlayer _audioPlayer;
  final LocalStorage _storage;
  final WindowsMediaSession _mediaSession;
  final MusicRepository _musicRepository;
  final SettingsCubit _settingsCubit;

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

  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(
    children: [],
  );

  static const _tag = 'PlayerBloc';

  PlayerBloc({
    required MusicRepository musicRepository,
    required SettingsCubit settingsCubit,
    LocalStorage? storage,
    AudioPlayer? audioPlayer,
    WindowsMediaSession? mediaSession,
  }) : _musicRepository = musicRepository,
       _settingsCubit = settingsCubit,
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
    on<InsertNextEvent>(_onInsertNext);
    on<AppendToQueueEvent>(_onAppendToQueue);
    on<RemoveFromQueueEvent>(_onRemoveFromQueue);
    on<ReorderQueueEvent>(_onReorderQueue);
    on<ToggleLikeEvent>(_onToggleLike);
    on<ToggleDownloadEvent>(_onToggleDownload);
    on<SetVolumeEvent>(_onSetVolume);
    on<SetPlaybackSpeedEvent>(_onSetPlaybackSpeed);
    on<SetCrossfadeDurationEvent>(_onSetCrossfadeDuration);
    on<ResetPlayerEvent>(_onResetPlayer);
    on<FilterByMoodEvent>(_onFilterByMood);

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

    _mediaSession.init(
      onPlay: () { if (!isClosed) add(const PlayEvent()); },
      onPause: () { if (!isClosed) add(const PauseEvent()); },
      onNext: () { if (!isClosed) add(const SkipNextEvent()); },
      onPrevious: () { if (!isClosed) add(const SkipPreviousEvent()); },
      onFastForward: () { if (!isClosed) add(const FastForwardEvent()); },
      onRewind: () { if (!isClosed) add(const RewindEvent()); },
    );
  }

  void _subscribeToPlayer() {
    DateTime lastPositionUpdate = DateTime.fromMillisecondsSinceEpoch(0);
    DateTime lastBufferedUpdate = DateTime.fromMillisecondsSinceEpoch(0);

    _positionSub = _audioPlayer.positionStream.listen((pos) {
      if (isClosed) return;
      final now = DateTime.now();
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
        final buffering = ps.processingState == ja.ProcessingState.loading || ps.processingState == ja.ProcessingState.buffering;
        if (state.isInitialLoading && (ps.processingState == ja.ProcessingState.ready || ps.playing)) {
          add(const _InitialLoadingChangedEvent(false));
        }
        add(_BufferingChangedEvent(isBuffering: buffering, isPlaying: ps.playing));
      }
    });

    _playbackErrorSub = _audioPlayer.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace st) async {
      if (isClosed) return;
      String? failedHost;
      final currentIndex = _audioPlayer.currentIndex;
      if (currentIndex != null && currentIndex < _playlist.length) {
        final source = _playlist.children[currentIndex];
        if (source is ja.UriAudioSource) failedHost = source.uri.host;
      }
      if (failedHost == '127.0.0.1' || failedHost == 'flow-jit') return;
      AppLogger.e(_tag, 'Playback error (retry=$_retryCount) host=$failedHost', e, st);
      if (_retryCount < 3) {
        _retryCount++;
        await Future.delayed(Duration(seconds: _retryCount));
        if (!isClosed) _audioPlayer.play();
      } else {
        _retryCount = 0;
        add(const SkipNextEvent());
      }
    });

    _currentIndexSub = _audioPlayer.currentIndexStream.listen((idx) {
      if (isClosed || idx == null || _isChangingSource || idx >= state.queue.length) return;
      if (idx != state.queueIndex) {
        final isPlaceholder = idx < _playlist.length && _playlist.children[idx] is ja.UriAudioSource && (_playlist.children[idx] as ja.UriAudioSource).uri.host == 'flow-jit';
        if (isPlaceholder) _prefetchSurroundingTracks(idx);
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
    _retryCount = 0;
    final song = state.queue[newIndex];
    _musicRepository.recordPlay(song);
    final recent = [song, ...state.recentlyPlayed.where((s) => s.id != song.id)];
    if (recent.length > 20) recent.removeLast();
    _storage.saveRecentlyPlayedIds(recent.map((s) => s.id).toList());
    _mediaSession.updateSong(song);
    if (state.isEndlessRadio && state.queue.length - newIndex < 3 && state.queue.isNotEmpty) _fetchMoreRadioTracks();
    _prefetchSurroundingTracks(newIndex);
    emit(state.copyWith(currentSong: song, queueIndex: newIndex, recentlyPlayed: recent, position: Duration.zero, bufferedPosition: Duration.zero, clearActualDuration: true, clearCustomColors: true));
    _extractPalette(song);
  }

  void _prefetchSurroundingTracks(int currentIndex) async {
    if (state.queue.isEmpty) return;
    final List<int> indicesToPrefetch = [currentIndex];
    if (currentIndex + 1 < state.queue.length) indicesToPrefetch.add(currentIndex + 1);
    if (currentIndex > 0) indicesToPrefetch.add(currentIndex - 1);

    for (final idx in indicesToPrefetch.toSet()) {
      if (idx >= 0 && idx < state.queue.length) {
        final song = state.queue[idx];
        try {
          if (idx >= _playlist.length) continue;
          final currentSource = _playlist.children[idx];
          final isPlaceholder = currentSource is ja.UriAudioSource && (currentSource.uri.host == 'flow-jit' || currentSource.uri.host == 'flow.error');
          if (isPlaceholder) {
            final realSource = await _buildAudioSource(song);
            if (!isClosed && idx < _playlist.length) {
              await _playlist.removeAt(idx);
              await _playlist.insert(idx, realSource);
              if (idx == _audioPlayer.currentIndex && (_audioPlayer.processingState == ja.ProcessingState.idle || _audioPlayer.processingState == ja.ProcessingState.loading)) {
                final currentPos = _audioPlayer.position;
                await _audioPlayer.seek(currentPos, index: idx);
                if (state.isPlaying) _audioPlayer.play();
              }
            }
          }
        } catch (e) { AppLogger.w(_tag, 'Prefetch resolution failed for index $idx: $e'); }
      }
    }
  }

  void _onRestoreState(_RestoreStateEvent event, Emitter<PlayerState> emit) {
    final likedIds = _storage.likedSongIds;
    final recentIds = _storage.recentlyPlayedIds;
    final volume = _storage.volume;
    final speed = _storage.playbackSpeed;
    final crossfadeSeconds = _storage.crossfadeDuration;
    final shuffle = _storage.isShuffle;
    final repeat = _storage.isRepeat;
    _audioPlayer.setVolume(volume);
    _audioPlayer.setSpeed(speed);
    emit(state.copyWith(
      likedSongIds: likedIds, 
      recentlyPlayedIds: recentIds, 
      volume: volume, 
      playbackSpeed: speed,
      crossfadeDuration: Duration(seconds: crossfadeSeconds),
      isShuffle: shuffle, 
      isRepeat: repeat,
    ));
    if (recentIds.isNotEmpty) _hydrateRecentlyPlayed(recentIds);
  }

  Future<void> _hydrateRecentlyPlayed(List<String> ids) async {
    try {
      final songs = await _musicRepository.getSongsByIds(ids);
      if (!isClosed) add(_RecentlyPlayedUpdatedEvent(songs));
    } catch (e) { AppLogger.w(_tag, 'Failed to hydrate recently played: $e'); }
  }

  void _onRecentlyPlayedUpdated(_RecentlyPlayedUpdatedEvent event, Emitter<PlayerState> emit) {
    emit(state.copyWith(recentlyPlayed: event.recentlyPlayed));
  }

  Future<void> _onPlayQueue(PlayQueueEvent event, Emitter<PlayerState> emit) async {
    if (event.songs.isEmpty) return;
    _retryCount = 0;
    if (event.songs.length == 1 && !state.isEndlessRadio) { add(PlayRadioEvent(event.songs[0])); return; }
    final idx = event.startIndex.clamp(0, event.songs.length - 1);
    final song = event.songs[idx];
    _musicRepository.recordPlay(song);
    await _audioPlayer.stop();
    emit(state.copyWith(queue: List.from(event.songs), queueIndex: idx, currentSong: song, isPlaying: false, isInitialLoading: true, isEndlessRadio: false, position: Duration.zero, bufferedPosition: Duration.zero, clearActualDuration: true, clearCustomColors: true));
    _extractPalette(song);
    await _updatePlaylist(event.songs, initialIndex: idx);
  }

  Future<void> _onPlaySingle(PlaySingleEvent event, Emitter<PlayerState> emit) async {
    _retryCount = 0;
    _musicRepository.recordPlay(event.song);
    await _audioPlayer.stop();
    // Default to endless radio for single song plays from search/etc
    emit(state.copyWith(
      queue: [event.song], 
      queueIndex: 0, 
      currentSong: event.song, 
      isPlaying: false, 
      isInitialLoading: true, 
      isEndlessRadio: true,
      position: Duration.zero, 
      bufferedPosition: Duration.zero, 
      clearActualDuration: true, 
      clearCustomColors: true,
    ));
    _extractPalette(event.song);
    await _updatePlaylist([event.song]);
    _fetchMoreRadioTracks();
  }

  Future<void> _onPlayRadio(PlayRadioEvent event, Emitter<PlayerState> emit) async {
    _retryCount = 0;
    _musicRepository.recordPlay(event.song);
    emit(state.copyWith(queue: [event.song], queueIndex: 0, currentSong: event.song, isInitialLoading: true, isEndlessRadio: true, clearCustomColors: true));
    _extractPalette(event.song);
    await _updatePlaylist([event.song]);
    _fetchMoreRadioTracks();
  }

  Future<void> _fetchMoreRadioTracks() async {
    if (state.queue.isEmpty || _isFetchingRadio) return;
    _isFetchingRadio = true;
    final anchor = state.queue.last;
    try {
      final tracks = await _musicRepository.getRadioTracks(anchor.id);
      if (isClosed) return;
      final existingIds = state.queue.map((s) => s.id).toSet();
      final newTracks = tracks.where((t) => !existingIds.contains(t.id)).toList();
      if (newTracks.isNotEmpty) {
        final updatedQueue = [...state.queue, ...newTracks];
        for (final t in newTracks) {
          final source = await _buildAudioSource(t, isPlaceholder: true);
          await _playlist.add(source);
        }
        add(_QueueUpdatedEvent(updatedQueue));
        _prefetchSurroundingTracks(state.queueIndex);
      }
    } catch (e, st) { AppLogger.e(_tag, 'Failed to fetch radio tracks', e, st); } finally { _isFetchingRadio = false; }
  }

  void _onQueueUpdated(_QueueUpdatedEvent event, Emitter<PlayerState> emit) {
    final playerIdx = _audioPlayer.currentIndex;
    if (playerIdx != null && playerIdx != state.queueIndex && playerIdx < event.queue.length) add(_TrackChangedEvent(playerIdx));
    emit(state.copyWith(queue: event.queue));
    if (_audioPlayer.processingState == ja.ProcessingState.completed && _audioPlayer.hasNext) { _audioPlayer.seekToNext(); _audioPlayer.play(); }
  }

  Future<void> _onResetPlayer(ResetPlayerEvent event, Emitter<PlayerState> emit) async {
    _isChangingSource = true; _isFetchingRadio = false; _retryCount = 0;
    try { await _audioPlayer.stop(); await _playlist.clear(); _mediaSession.setStopped(); } catch (e) { AppLogger.e(_tag, 'Failed to stop/clear player', e); } finally { _isChangingSource = false; }
    emit(state.copyWith(isPlaying: false, isBuffering: false, isInitialLoading: false, position: Duration.zero, bufferedPosition: Duration.zero, queue: [], queueIndex: -1, currentSong: null, clearActualDuration: true, clearCustomColors: true));
  }

  Future<void> _updatePlaylist(List<Song> songs, {int initialIndex = 0}) async {
    try {
      _isChangingSource = true; await _playlist.clear();
      final List<AudioSource> children = [];
      for (int i = 0; i < songs.length; i++) {
        children.add(await _buildAudioSource(songs[i], isPlaceholder: i != initialIndex));
      }
      await _playlist.addAll(children);
      await _audioPlayer.setAudioSource(_playlist, initialIndex: initialIndex, initialPosition: Duration.zero);
      _mediaSession.updateSong(songs[initialIndex]);
      _mediaSession.setPlaybackStatus(true);
      _prefetchSurroundingTracks(initialIndex);
      add(const _InitialLoadingChangedEvent(false));
      await Future.delayed(const Duration(milliseconds: 200));
      _isChangingSource = false;
      await _audioPlayer.play();
    } catch (e, st) { AppLogger.e(_tag, 'Failed to update playlist', e, st); _isChangingSource = false; }
  }

  void _onPlayStateChanged(_PlayStateChangedEvent event, Emitter<PlayerState> emit) { emit(state.copyWith(isPlaying: event.isPlaying)); }

  Future<AudioSource> _buildAudioSource(Song song, {bool? isLikedOverride, bool isPlaceholder = false}) async {
    final isLiked = isLikedOverride ?? state.likedSongIds.contains(song.id);
    final downloadMetadata = _storage.getDownloadMetadata(song.id);
    final downloadedPath = _storage.getDownloadedPath(song.id);
    bool useLocal = false; File? localFile; String? effectiveThumbnailUrl = song.thumbnailUrl; Duration effectiveDuration = song.duration;
    if (downloadedPath != null) {
      localFile = File(downloadedPath);
      if (await localFile.exists()) {
        useLocal = true;
        if (downloadMetadata != null) {
          if (downloadMetadata['thumbnailUrl'] != null) effectiveThumbnailUrl = downloadMetadata['thumbnailUrl'] as String;
          if (downloadMetadata['durationMs'] != null) effectiveDuration = Duration(milliseconds: downloadMetadata['durationMs'] as int);
        }
      }
    }
    if (!useLocal) { localFile = await CacheService.instance.getCachedFile(song.id); if (localFile != null) useLocal = true; }
    Uri? artUri;
    if (effectiveThumbnailUrl != null) {
      if (effectiveThumbnailUrl.startsWith('http')) { artUri = Uri.parse(effectiveThumbnailUrl); } else {
        final thumbFile = File(effectiveThumbnailUrl);
        if (await thumbFile.exists()) { artUri = Uri.file(effectiveThumbnailUrl); } else if (song.thumbnailUrl != null && song.thumbnailUrl!.startsWith('http')) { artUri = Uri.parse(song.thumbnailUrl!); }
      }
    }
    final mediaItem = MediaItem(id: song.id, title: song.title, artist: song.artist, album: song.album.isNotEmpty ? song.album : song.artist, duration: effectiveDuration, artUri: artUri, rating: Rating.newHeartRating(isLiked), extras: <String, dynamic>{'isLiked': isLiked, 'isLocal': useLocal, 'isDownloaded': useLocal, 'androidCompactControlIndices': [0, 1, 2], 'displayRating': true});

    if (useLocal && localFile != null) { return AudioSource.uri(Uri.file(localFile.path), tag: mediaItem); } else {
      String? streamUrl;
      if (isPlaceholder) { streamUrl = 'https://127.0.0.1/flow-jit/${song.id}'; } else {
        final mode = _settingsCubit.state.streamingMode;
        try {
          if (mode == StreamingMode.relayFromPeer) {
            final activePeer = PeerManager.instance.getActivePeer();
            if (activePeer != null) {
              streamUrl = LanStreamBridge.instance.getProxyUrl(song.id, activePeer);
            }
            streamUrl ??= await StreamResolver.instance.resolveYoutubeStream(song.id, title: song.title, artist: song.artist, forceStandardYouTube: song.source == 'ytm');
          } else if (mode == StreamingMode.hybridPreferLocal) {
            streamUrl = await StreamResolver.instance.resolveYoutubeStream(song.id, title: song.title, artist: song.artist, forceStandardYouTube: song.source == 'ytm');
            if (streamUrl == null) {
              final activePeer = PeerManager.instance.getActivePeer();
              if (activePeer != null) {
                streamUrl = LanStreamBridge.instance.getProxyUrl(song.id, activePeer);
              }
            }
          } else { streamUrl = await StreamResolver.instance.resolveYoutubeStream(song.id, title: song.title, artist: song.artist, forceStandardYouTube: song.source == 'ytm'); }
          if (streamUrl != null) CacheService.instance.cacheSong(song);
        } catch (e) { AppLogger.e(_tag, 'Failed to resolve stream', e); }
      }
      if (streamUrl == null || streamUrl.isEmpty) streamUrl = 'https://127.0.0.1/flow.error/${song.id}';
      final uri = Uri.parse(streamUrl);
      final headers = {
        'User-Agent': 'com.google.android.apps.youtube.music/7.05.52 (Linux; U; Android 14; en_US) gzip',
        'Origin': 'https://music.youtube.com',
        'Referer': 'https://music.youtube.com/',
      };
      if (uri.host.contains('googlevideo.com')) return AudioSource.uri(uri, headers: headers, tag: mediaItem);
      if (Platform.isWindows || isPlaceholder) return AudioSource.uri(uri, headers: headers, tag: mediaItem);
      return LockCachingAudioSource(uri, headers: headers, tag: mediaItem);
    }
  }

  void _onTogglePlayPause(TogglePlayPauseEvent event, Emitter<PlayerState> emit) { if (state.isPlaying) { add(const PauseEvent()); } else { add(const PlayEvent()); } }
  void _onPlay(PlayEvent event, Emitter<PlayerState> emit) { _audioPlayer.play(); _mediaSession.setPlaybackStatus(true); }
  void _onPause(PauseEvent event, Emitter<PlayerState> emit) { _audioPlayer.pause(); _mediaSession.setPlaybackStatus(false); }
  void _onSeekTo(SeekToEvent event, Emitter<PlayerState> emit) { final dur = _audioPlayer.duration ?? state.actualDuration ?? state.currentSong?.duration; if (dur != null) { _audioPlayer.seek(Duration(milliseconds: (event.fraction * dur.inMilliseconds).round())); } }
  void _onSkipNext(SkipNextEvent event, Emitter<PlayerState> emit) {
    if (state.currentSong != null) {
      final isEarly = state.position.inSeconds < 30;
      AppIntelligence.instance.recordEvent(domain.Track.fromSong(state.currentSong!), isEarly ? domain.ListenEvent.skippedEarly : domain.ListenEvent.skippedMid);
    }
    _retryCount = 0;
    if (_audioPlayer.hasNext) { _audioPlayer.seekToNext(); } else if (state.currentSong != null) { add(PlayRadioEvent(state.currentSong!)); }
  }
  void _onSkipPrevious(SkipPreviousEvent event, Emitter<PlayerState> emit) { _retryCount = 0; if (state.progress > 0.05 || !_audioPlayer.hasPrevious) { _audioPlayer.seek(Duration.zero); } else { _audioPlayer.seekToPrevious(); } }
  void _onRewind(RewindEvent event, Emitter<PlayerState> emit) { final target = _audioPlayer.position - const Duration(seconds: 10); _audioPlayer.seek(target > Duration.zero ? target : Duration.zero); }
  void _onFastForward(FastForwardEvent event, Emitter<PlayerState> emit) { final target = _audioPlayer.position + const Duration(seconds: 10); final total = _audioPlayer.duration ?? Duration.zero; if (target < total) { _audioPlayer.seek(target); } else { _audioPlayer.seekToNext(); } }
  void _onToggleShuffle(ToggleShuffleEvent event, Emitter<PlayerState> emit) { final next = !state.isShuffle; _storage.saveShuffle(next); _audioPlayer.setShuffleModeEnabled(next); emit(state.copyWith(isShuffle: next)); }
  void _onToggleRepeat(ToggleRepeatEvent event, Emitter<PlayerState> emit) { final next = !state.isRepeat; _storage.saveRepeat(next); _audioPlayer.setLoopMode(next ? LoopMode.one : LoopMode.off); emit(state.copyWith(isRepeat: next)); }
  void _onToggleEndlessRadio(ToggleEndlessRadioEvent event, Emitter<PlayerState> emit) { final next = !state.isEndlessRadio; emit(state.copyWith(isEndlessRadio: next)); if (next && state.queue.length - state.queueIndex < 3) _fetchMoreRadioTracks(); }
  Future<void> _onPlayDownloadedRadio(PlayDownloadedRadioEvent event, Emitter<PlayerState> emit) async {
    final ids = DownloadService.instance.getDownloadedIds(); if (ids.isEmpty) return;
    emit(state.copyWith(isInitialLoading: true));
    try {
      final songs = await _musicRepository.getSongsByIds(ids); if (songs.isEmpty) { emit(state.copyWith(isInitialLoading: false)); return; }
      final shuffled = List<Song>.from(songs)..shuffle();
      emit(state.copyWith(queue: shuffled, queueIndex: 0, currentSong: shuffled[0], isInitialLoading: true, isEndlessRadio: false, clearCustomColors: true));
      _extractPalette(shuffled[0]); await _updatePlaylist(shuffled);
    } catch (e) { AppLogger.e(_tag, 'Failed downloaded radio', e); emit(state.copyWith(isInitialLoading: false)); }
  }
  void _onToggleLike(ToggleLikeEvent event, Emitter<PlayerState> emit) {
    final liked = List<String>.from(state.likedSongIds); final isNowLiked = !liked.contains(event.song.id);
    if (liked.contains(event.song.id)) { liked.remove(event.song.id); } else { liked.add(event.song.id); }
    _storage.saveLikedSongIds(liked);
    final idx = state.queue.indexWhere((s) => s.id == event.song.id);
    if (idx != -1) { _buildAudioSource(event.song, isLikedOverride: isNowLiked).then((newSource) { if (!isClosed) { final currentIndex = _audioPlayer.currentIndex; if (idx != currentIndex) { _playlist.removeAt(idx); _playlist.insert(idx, newSource); } } }); }
    emit(state.copyWith(likedSongIds: liked));
  }
  Future<void> _onToggleDownload(ToggleDownloadEvent event, Emitter<PlayerState> emit) async {
    final song = event.song; final isDownloaded = await DownloadService.instance.isDownloaded(song.id);
    try {
      if (isDownloaded) { await DownloadService.instance.deleteDownload(song.id); } else { await DownloadService.instance.downloadSong(song); }
      if (state.currentSong?.id == song.id) { emit(state.copyWith(currentSong: state.currentSong!.copyWith(isDownloaded: !isDownloaded))); }
      final List<Song> newQueue = state.queue.map((s) => s.id == song.id ? s.copyWith(isDownloaded: !isDownloaded) : s).toList();
      emit(state.copyWith(queue: newQueue));
    } catch (e) { AppLogger.e(_tag, 'Toggle download failed', e); }
  }
  void _onSetVolume(SetVolumeEvent event, Emitter<PlayerState> emit) { final vol = event.volume.clamp(0.0, 1.0); _audioPlayer.setVolume(vol); _storage.saveVolume(vol); emit(state.copyWith(volume: vol)); }
  void _onSetPlaybackSpeed(SetPlaybackSpeedEvent event, Emitter<PlayerState> emit) { 
    final speed = event.speed.clamp(0.5, 2.0); 
    _audioPlayer.setSpeed(speed); 
    _storage.savePlaybackSpeed(speed); 
    emit(state.copyWith(playbackSpeed: speed)); 
  }
  void _onSetCrossfadeDuration(SetCrossfadeDurationEvent event, Emitter<PlayerState> emit) {
    _storage.saveCrossfadeDuration(event.duration.inSeconds);
    emit(state.copyWith(crossfadeDuration: event.duration));
  }
  void _onPositionUpdate(_PositionUpdateEvent event, Emitter<PlayerState> emit) {
    final isFullyCached = _audioPlayer.bufferedPosition >= (event.duration ?? Duration.zero);
    emit(state.copyWith(position: event.position, actualDuration: event.duration, bufferedPosition: isFullyCached ? event.duration : null));
    if (event.duration != null && event.position.inSeconds % 2 == 0) _mediaSession.updateTimeline(event.position, event.duration!);
  }
  void _onBufferedPositionChanged(_BufferedPositionChangedEvent event, Emitter<PlayerState> emit) { emit(state.copyWith(bufferedPosition: event.bufferedPosition)); }
  void _onBufferingChanged(_BufferingChangedEvent event, Emitter<PlayerState> emit) { emit(state.copyWith(isBuffering: event.isBuffering, isPlaying: _audioPlayer.playing)); }
  void _onInitialLoadingChanged(_InitialLoadingChangedEvent event, Emitter<PlayerState> emit) { emit(state.copyWith(isInitialLoading: event.isInitialLoading)); }
  void _onDownloadProgressUpdated(_DownloadProgressUpdatedEvent event, Emitter<PlayerState> emit) { emit(state.copyWith(downloadProgress: event.progress)); }
  Future<void> _onSkipToQueueIndex(SkipToQueueIndexEvent event, Emitter<PlayerState> emit) async {
    if (event.index >= 0 && event.index < state.queue.length) {
      final song = state.queue[event.index];
      try {
        final currentSource = _playlist.children[event.index];
        if (currentSource is ja.UriAudioSource && (currentSource.uri.host == '127.0.0.1' || currentSource.uri.host == 'flow.loading')) {
          AppLogger.i(_tag, 'JIT Resolve on skip...'); emit(state.copyWith(isBuffering: true));
          final realSource = await _buildAudioSource(song); await _playlist.removeAt(event.index); await _playlist.insert(event.index, realSource);
        }
      } catch (e) { AppLogger.w(_tag, 'JIT skip failed: $e'); }
      await _audioPlayer.seek(Duration.zero, index: event.index); _audioPlayer.play();
    }
  }
  Future<void> _onInsertNext(InsertNextEvent event, Emitter<PlayerState> emit) async {
    final bool wasEmpty = state.queue.isEmpty;
    final updatedQueue = List<Song>.from(state.queue)..removeWhere((s) => s.id == event.song.id);
    final currentIdxAfterRemoval = updatedQueue.indexWhere((s) => s.id == state.currentSong?.id);
    final targetIdx = (currentIdxAfterRemoval != -1) ? currentIdxAfterRemoval + 1 : 0;
    updatedQueue.insert(targetIdx, event.song);
    final source = await _buildAudioSource(event.song);
    final existingIdxInPlaylist = state.queue.indexWhere((s) => s.id == event.song.id);
    if (existingIdxInPlaylist != -1) await _playlist.removeAt(existingIdxInPlaylist);
    await _playlist.insert(targetIdx, source);
    if (wasEmpty) { add(PlayQueueEvent(songs: [event.song], startIndex: 0)); } else { emit(state.copyWith(queue: updatedQueue, queueIndex: updatedQueue.indexWhere((s) => s.id == state.currentSong?.id))); }
  }
  Future<void> _onAppendToQueue(AppendToQueueEvent event, Emitter<PlayerState> emit) async {
    if (state.queue.any((s) => s.id == event.song.id)) return;
    final bool wasEmpty = state.queue.isEmpty;
    final updatedQueue = [...state.queue, event.song];
    final source = await _buildAudioSource(event.song);
    await _playlist.add(source);
    if (wasEmpty) { add(PlayQueueEvent(songs: [event.song], startIndex: 0)); } else { emit(state.copyWith(queue: updatedQueue)); }
  }
  Future<void> _onRemoveFromQueue(RemoveFromQueueEvent event, Emitter<PlayerState> emit) async {
    if (event.index < 0 || event.index >= state.queue.length) return;
    if (event.index == state.queueIndex) add(const SkipNextEvent());
    final updatedQueue = List<Song>.from(state.queue)..removeAt(event.index);
    await _playlist.removeAt(event.index);
    emit(state.copyWith(queue: updatedQueue, queueIndex: _audioPlayer.currentIndex ?? state.queueIndex));
  }
  Future<void> _onReorderQueue(ReorderQueueEvent event, Emitter<PlayerState> emit) async {
    int oldIdx = event.oldIndex; int newIdx = event.newIndex; if (oldIdx < newIdx) newIdx -= 1;
    final updatedQueue = List<Song>.from(state.queue); final song = updatedQueue.removeAt(oldIdx); updatedQueue.insert(newIdx, song);
    await _playlist.move(oldIdx, newIdx); emit(state.copyWith(queue: updatedQueue, queueIndex: _audioPlayer.currentIndex ?? state.queueIndex));
  }
  void _onTrackCompleted(_TrackCompletedEvent event, Emitter<PlayerState> emit) {
    if (state.currentSong != null) { AppIntelligence.instance.recordEvent(domain.Track.fromSong(state.currentSong!), domain.ListenEvent.fullListen); }
    if (!state.isRepeat && !_audioPlayer.hasNext) {
      if (state.isEndlessRadio && state.currentSong != null) {
        _fetchMoreRadioTracks().then((_) { if (!isClosed && _audioPlayer.hasNext && !state.isPlaying) { _audioPlayer.seekToNext(); _audioPlayer.play(); } });
      } else { _mediaSession.setStopped(); emit(state.copyWith(isPlaying: false)); }
    }
  }
  void _onPaletteUpdated(_PaletteUpdatedEvent event, Emitter<PlayerState> emit) { emit(state.copyWith(customPrimary: event.primary, customSecondary: event.secondary)); }
  Future<void> _extractPalette(Song song) async {
    String? thumbUrl = song.thumbnailUrl;
    final metadata = _storage.getDownloadMetadata(song.id);
    if (metadata != null && metadata['thumbnailUrl'] != null) thumbUrl = metadata['thumbnailUrl'] as String;
    if (thumbUrl == null || thumbUrl.isEmpty) return;
    try {
      final ImageProvider provider = thumbUrl.startsWith('http') ? NetworkImage(thumbUrl) : FileImage(File(thumbUrl));
      final palette = await PaletteGenerator.fromImageProvider(provider, maximumColorCount: 20);
      final primary = palette.vibrantColor?.color ?? palette.dominantColor?.color ?? song.colorPrimary;
      final secondary = palette.mutedColor?.color ?? palette.lightVibrantColor?.color ?? song.colorSecondary;
      if (!isClosed) add(_PaletteUpdatedEvent(primary, secondary));
    } catch (e) { AppLogger.w(_tag, 'Palette extraction failed: $e'); }
  }
  Future<void> _onFilterByMood(FilterByMoodEvent event, Emitter<PlayerState> emit) async {
    if (state.queue.isEmpty) return;
    final mood = Mood.values.firstWhere((m) => m.name.toLowerCase() == event.mood.toLowerCase(), orElse: () => Mood.chill);
    final currentSong = state.currentSong; final engine = MoodEngine();
    final tracks = state.queue.map((s) => domain.Track.fromSong(s)).toList();
    final filteredTracks = engine.filterByMood(tracks, mood);
    if (filteredTracks.isNotEmpty) {
      final filteredSongs = filteredTracks.map((t) => state.queue.firstWhere((s) => s.id == t.id)).toList();
      if (currentSong != null && !filteredSongs.any((s) => s.id == currentSong.id)) filteredSongs.insert(0, currentSong);
      add(PlayQueueEvent(songs: filteredSongs, startIndex: 0));
    }
  }
  @override
  Future<void> close() async {
    await _positionSub?.cancel(); await _durationSub?.cancel(); await _bufferedSub?.cancel(); await _playerStateSub?.cancel(); await _currentIndexSub?.cancel(); await _downloadSub?.cancel();
    await _audioPlayer.dispose(); await _mediaSession.dispose(); return super.close();
  }
}
