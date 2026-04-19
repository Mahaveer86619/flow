import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/app_event_bus.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/network/download_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/repositories/music_repository.dart';
import '../../../domain/usecases/get_playlists_usecase.dart';
import 'library_state.dart';

export 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  static const _tag = 'LibraryCubit';

  final GetPlaylistsUseCase _getPlaylists;
  final MusicRepository _musicRepository;

  StreamSubscription? _likedSongsSub;
  StreamSubscription? _downloadSub;
  StreamSubscription? _eventSub;

  bool _isInitialLoading = false;

  LibraryCubit({
    required GetPlaylistsUseCase getPlaylists,
    required MusicRepository musicRepository,
  }) : _getPlaylists = getPlaylists,
       _musicRepository = musicRepository,
       super(const LibraryState(isLoading: true, playlists: [])) {
    AppLogger.i(_tag, 'Created');

    _eventSub = AppEventBus.instance.events.listen((event) {
      if (event is GlobalRetryEvent) {
        if (state.error) {
          reload(isGlobal: true);
        }
      }
    });

    _loadAll();

    _likedSongsSub = LocalStorage.instance.likedSongsStream.listen((ids) async {
      AppLogger.d(_tag, 'Liked songs stream event: ${ids.length} ids');
      final songs = await _fetchLikedSongs();
      if (!isClosed) {
        emit(state.copyWith(likedSongs: songs));
      }
    });

    _downloadSub = DownloadService.instance.downloadEventStream.listen((
      _,
    ) async {
      AppLogger.d(_tag, 'Download event stream event');
      final songs = await _fetchDownloadedSongs();
      if (!isClosed) {
        emit(state.copyWith(downloadedSongs: songs));
      }
    });
  }

  @override
  Future<void> close() {
    _likedSongsSub?.cancel();
    _downloadSub?.cancel();
    _eventSub?.cancel();
    return super.close();
  }

  Future<void> reload({bool isGlobal = false}) {
    AppLogger.i(_tag, 'reload(isGlobal: $isGlobal)');
    if (!isGlobal) {
      AppEventBus.instance.fire(GlobalRetryEvent());
    }
    return _loadAll();
  }

  Future<void> refresh() => _loadAll();

  Future<void> _loadAll() async {
    if (_isInitialLoading) return;
    _isInitialLoading = true;

    emit(state.copyWith(isLoading: true));
    try {
      // Fetch components individually so one failure doesn't kill the whole load
      final results = await Future.wait([
        _getPlaylists().catchError((e) {
          AppLogger.e(_tag, 'Failed to fetch playlists', e);
          return <Playlist>[];
        }),
        _fetchRemoteLikedSongs().catchError((e) {
          AppLogger.e(_tag, 'Failed to fetch remote liked songs', e);
          return <Song>[];
        }),
        _fetchLikedSongs().catchError((e) {
          AppLogger.e(_tag, 'Failed to fetch liked songs', e);
          return <Song>[];
        }),
        _fetchDownloadedSongs().catchError((e) {
          AppLogger.e(_tag, 'Failed to fetch downloaded songs', e);
          return <Song>[];
        }),
      ]);

      if (isClosed) return;

      emit(
        state.copyWith(
          isLoading: false,
          playlists: results[0] as List<Playlist>,
          remoteLikedSongs: results[1] as List<Song>,
          likedSongs: results[2] as List<Song>,
          downloadedSongs: results[3] as List<Song>,
          error: false,
        ),
      );
    } catch (e, st) {
      if (isClosed) return;
      AppLogger.e(_tag, 'Unexpected error in _loadAll', e, st);
      emit(state.copyWith(isLoading: false, error: true));
    } finally {
      _isInitialLoading = false;
    }
  }

  Future<List<Song>> _fetchLikedSongs() async {
    final ids = LocalStorage.instance.likedSongIds;
    if (ids.isEmpty) return [];
    return _musicRepository.getSongsByIds(ids);
  }

  Future<List<Song>> _fetchDownloadedSongs() async {
    final ids = DownloadService.instance.getDownloadedIds();
    if (ids.isEmpty) return [];
    return _musicRepository.getSongsByIds(ids);
  }

  Future<List<Song>> _fetchRemoteLikedSongs() async {
    try {
      // "LM" is the YT Music "Your Likes" playlist ID
      return await _musicRepository.getPlaylistTracks('LM');
    } catch (e) {
      AppLogger.w(_tag, 'Failed to fetch remote liked songs: $e');
      return [];
    }
  }
}

