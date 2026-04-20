import 'dart:convert';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/app_event_bus.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/storage/hive_keys.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/models/home_data_model.dart';
import '../../../data/models/song_model.dart';
import '../../../data/models/playlist_model.dart';
import '../../../domain/usecases/get_home_data_usecase.dart';
import '../../../domain/entities/home_data.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/history_data.dart';
import '../../../domain/repositories/music_repository.dart';
import 'home_state.dart';

export 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  static const _tag = 'HomeCubit';

  final GetHomeDataUseCase _getHomeData;
  final MusicRepository _musicRepository;
  StreamSubscription? _eventSub;

  HomeCubit({
    required GetHomeDataUseCase getHomeData,
    required MusicRepository musicRepository,
  }) : _getHomeData = getHomeData,
       _musicRepository = musicRepository,
       super(const HomeState(isLoading: true)) {
    AppLogger.i(_tag, 'Created');

    _eventSub = AppEventBus.instance.events.listen((event) {
      if (event is GlobalRetryEvent) {
        if (state.error || state.noSource) {
          reload(isGlobal: true);
        }
      }
    });

    _init();
  }

  Future<void> _init() async {
    // 1. Try loading from cache first for instant UI
    await _loadFromCache();
    // 2. Trigger background refresh
    _load();
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedData = LocalStorage.instance.getCachedMetadata(HiveKeys.homeDataKey);
      if (cachedData != null) {
        AppLogger.d(_tag, 'Found cached home data');
        final model = HomeDataModel.fromJson(jsonDecode(cachedData as String));
        final data = model.toEntity();
        
        final hour = DateTime.now().hour;
        final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

        emit(state.copyWith(
          isLoading: false,
          greeting: greeting,
          shelves: data.shelves,
          trending: data.trending,
          allSongs: data.allSongs,
          profileUrl: data.profileUrl,
          ytName: data.ytName,
          musicVideos: data.musicVideos,
          favArtistsSongs: data.favArtistsSongs,
        ));
      }
    } catch (e) {
      AppLogger.w(_tag, 'Failed to load home cache: $e');
    }
  }

  Future<void> reload({bool isGlobal = false}) {
    AppLogger.i(_tag, 'reload(isGlobal: $isGlobal)');
    if (!isGlobal) {
      AppEventBus.instance.fire(GlobalRetryEvent());
    }
    emit(state.copyWith(isLoading: true, error: false, noSource: false));
    return _load();
  }

  @override
  Future<void> close() {
    _eventSub?.cancel();
    return super.close();
  }

  Future<void> refresh() {
    AppLogger.i(_tag, 'refresh()');
    return _load();
  }

  Future<void> _load() async {
    // ── STANDALONE SOURCE CHECK (Phase 2) ──────────────────────────────────
    // Check local secure storage for cookies.
    await SecureStorageService.instance.getYoutubeCookies();

    try {
      AppLogger.d(_tag, 'Fetching home data and history (Standalone)...');
      final dataFuture = _getHomeData(limit: 48);
      // History is local, always fetchable
      final historyFuture = _musicRepository.getPersistentHistory();

      final results = await Future.wait([dataFuture, historyFuture]);
      final data = results[0] as HomeData;
      final history = results[1] as HistoryData;

      if (isClosed) return;

      // Cache the new data
      _saveToCache(data);

      final hour = DateTime.now().hour;
      final greeting = hour < 12
          ? 'Good morning'
          : hour < 17
          ? 'Good afternoon'
          : 'Good evening';

      AppLogger.i(
        _tag,
        'Loaded — allSongs=${data.allSongs.length}  greeting=$greeting',
      );

      final recent = [
        ...history.today,
        ...history.thisWeek,
        ...history.thisMonth,
      ].take(12).toList();

      emit(
        HomeState(
          isLoading: false,
          greeting: greeting,
          shelves: data.shelves,
          trending: data.trending,
          recentlyPlayed: recent,
          allSongs: data.allSongs,
          profileUrl: data.profileUrl,
          ytName: data.ytName,
          musicVideos: data.musicVideos,
          favArtistsSongs: data.favArtistsSongs,
        ),
      );
    } on AppException catch (e) {
      if (isClosed) return;
      AppLogger.w(_tag, 'Load failed: ${e.message}');
      // Only show error if we don't have cached data showing
      if (state.shelves.isEmpty) {
        emit(HomeState(isLoading: false, error: true, errorType: e.errorType));
      }
    } catch (e, st) {
      if (isClosed) return;
      AppLogger.e(_tag, 'Unexpected error', e, st);
      if (state.shelves.isEmpty) {
        emit(
          const HomeState(
            isLoading: false,
            error: true,
            errorType: AppErrorType.unknown,
          ),
        );
      }
    }
  }

  void _saveToCache(HomeData data) {
    try {
      // Use HomeDataModel to convert entity back to JSON
      final model = HomeDataModel(
        rawShelves: data.shelves.map((s) => {
          'title': s.title,
          'section': s.section,
          'items': s.items.map((i) {
            String typeStr = 'song';
            Map<String, dynamic> itemData = {};
            
            if (i.type == HomeItemType.song) {
               typeStr = 'song';
               itemData = SongModel.fromEntity(i.data as Song).toJson();
            } else if (i.type == HomeItemType.artist) {
               typeStr = 'artist';
               final d = i.data as Map<String, dynamic>;
               itemData = {
                 'name': d['name'],
                 'thumbnailUrl': d['thumbnailUrl'],
               };
            } else if (i.type == HomeItemType.album) {
               typeStr = 'album';
               itemData = PlaylistModel.fromEntity(i.data as Playlist).toJson();
            } else if (i.type == HomeItemType.playlist) {
               typeStr = 'playlist';
               itemData = PlaylistModel.fromEntity(i.data as Playlist).toJson();
            }
            
            return {
              'type': typeStr,
              'data': itemData,
            };
          }).toList(),
        }).toList(),
        trending: data.trending.map((s) => SongModel.fromEntity(s)).toList().cast<SongModel>(),
        profileUrl: data.profileUrl,
        ytName: data.ytName,
        musicVideos: data.musicVideos.map((s) => SongModel.fromEntity(s)).toList().cast<SongModel>(),
        favArtistsSongs: data.favArtistsSongs.map((s) => SongModel.fromEntity(s)).toList().cast<SongModel>(),
      );
      
      LocalStorage.instance.saveCachedMetadata(HiveKeys.homeDataKey, jsonEncode(model.toJson()));
    } catch (e) {
      AppLogger.w(_tag, 'Failed to save home cache: $e');
    }
  }
}
