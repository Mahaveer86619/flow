import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
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
    await _loadFromCache();
    _load();
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedData = LocalStorage.instance.getCachedMetadata(
        HiveKeys.homeDataKey,
      );
      if (cachedData != null) {
        AppLogger.d(_tag, 'Found cached home data');
        final model = HomeDataModel.fromJson(jsonDecode(cachedData as String));
        final data = model.toEntity();

        final hour = DateTime.now().hour;
        final greeting = hour < 12
            ? 'Good morning'
            : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

        final deduplicatedShelves = _deduplicateShelves(data.shelves);

        emit(
          state.copyWith(
            isLoading: false,
            greeting: greeting,
            shelves: deduplicatedShelves,
            trending: data.trending,
            allSongs: data.allSongs,
            profileUrl: data.profileUrl,
            ytName: data.ytName,
            musicVideos: data.musicVideos,
            favArtistsSongs: data.favArtistsSongs,
          ),
        );
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

  List<HomeShelf> _deduplicateShelves(List<HomeShelf> shelves) {
    final seenIds = <String>{};
    final storage = LocalStorage.instance;
    final topArtists = storage.topArtists;
    final searchArtists = storage.searchArtistHistory;
    final affinityArtists = {...topArtists, ...searchArtists}.toList();

    return shelves.map((shelf) {
      List<HomeItem> uniqueItems = shelf.items.where((item) {
        if (item.type == HomeItemType.song && item.data is Song) {
          final song = item.data as Song;
          return seenIds.add(song.id);
        }
        return true;
      }).toList();

      // Behavioral Sorting for Quick Picks
      if (shelf.section == 'quickPicks') {
        final songs = uniqueItems
            .where((it) => it.type == HomeItemType.song)
            .map((it) => it.data as Song)
            .toList();

        songs.sort((a, b) {
          final aAffinity = affinityArtists.indexOf(a.artist);
          final bAffinity = affinityArtists.indexOf(b.artist);
          if (aAffinity != -1 && bAffinity != -1)
            return aAffinity.compareTo(bAffinity);
          if (aAffinity != -1) return -1;
          if (bAffinity != -1) return 1;
          final aPlays = storage.artistPlayCounts[a.artist] ?? 0;
          final bPlays = storage.artistPlayCounts[b.artist] ?? 0;
          return bPlays.compareTo(aPlays);
        });

        uniqueItems = songs
            .take(20)
            .map((s) => HomeItem(type: HomeItemType.song, data: s))
            .toList();
      }

      return HomeShelf(
        title: shelf.title,
        section: shelf.section,
        items: uniqueItems,
      );
    }).toList();
  }

  Future<void> _load() async {
    await SecureStorageService.instance.getYoutubeCookies();

    try {
      AppLogger.d(_tag, 'Fetching home data and history (Standalone)...');
      final dataFuture = _getHomeData(limit: 48);
      final historyFuture = _musicRepository.getPersistentHistory();

      final results = await Future.wait([dataFuture, historyFuture]);
      final data = results[0] as HomeData;
      final history = results[1] as HistoryData;

      if (isClosed) return;

      _saveToCache(data);

      final hour = DateTime.now().hour;
      final greeting = hour < 12
          ? 'Good morning'
          : hour < 17
          ? 'Good afternoon'
          : 'Good evening';

      final recent = [
        ...history.today,
        ...history.thisWeek,
        ...history.thisMonth,
      ].take(12).toList();

      List<HomeShelf> finalShelves = List.from(data.shelves);

      // 1. Backfill Daily Rotation (Pure Music - SQUARE)
      final listenAgainIdx = finalShelves.indexWhere(
        (s) => s.section == 'listeningAgain',
      );
      List<Song> currentListenAgain = [];
      if (listenAgainIdx != -1) {
        currentListenAgain = finalShelves[listenAgainIdx].items
            .where((it) => it.type == HomeItemType.song)
            .map((e) => e.data as Song)
            .toList();
      }

      final allHistory = [
        ...history.today,
        ...history.thisWeek,
        ...history.thisMonth,
        ...history.byMonth.values.expand((e) => e),
      ];

      final combinedListenAgain = [
        ...currentListenAgain,
        ...allHistory,
      ].toSet().take(25).toList();

      finalShelves[listenAgainIdx != -1 ? listenAgainIdx : 0] = HomeShelf(
        title: 'Daily Rotation',
        section: 'listeningAgain',
        items: combinedListenAgain
            .map((s) => HomeItem(type: HomeItemType.song, data: s))
            .toList(),
      );

      // 2. Artist Affinity Discovery
      final topArtists = _musicRepository.getTopArtists().take(5).toList();
      for (final artist in topArtists) {
        LocalStorage.instance.addToInterestList(artist);
      }

      final deduplicatedShelves = _deduplicateShelves(finalShelves);

      emit(
        HomeState(
          isLoading: false,
          greeting: greeting,
          shelves: deduplicatedShelves,
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
      if (state.shelves.isEmpty)
        emit(HomeState(isLoading: false, error: true, errorType: e.errorType));
    } catch (e, st) {
      if (isClosed) return;
      AppLogger.e(_tag, 'Unexpected error', e, st);
      if (state.shelves.isEmpty)
        emit(
          const HomeState(
            isLoading: false,
            error: true,
            errorType: AppErrorType.unknown,
          ),
        );
    }
  }

  void _saveToCache(HomeData data) {
    try {
      final model = HomeDataModel(
        rawShelves: data.shelves
            .map(
              (s) => {
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
                  } else if (i.type == HomeItemType.album ||
                      i.type == HomeItemType.playlist) {
                    typeStr = i.type.name;
                    itemData = PlaylistModel.fromEntity(
                      i.data as Playlist,
                    ).toJson();
                  }

                  return {'type': typeStr, 'data': itemData};
                }).toList(),
              },
            )
            .toList(),
        trending: data.trending
            .map((s) => SongModel.fromEntity(s))
            .toList()
            .cast<SongModel>(),
        profileUrl: data.profileUrl,
        ytName: data.ytName,
        musicVideos: data.musicVideos
            .map((s) => SongModel.fromEntity(s))
            .toList()
            .cast<SongModel>(),
        favArtistsSongs: data.favArtistsSongs
            .map((s) => SongModel.fromEntity(s))
            .toList()
            .cast<SongModel>(),
      );

      LocalStorage.instance.saveCachedMetadata(
        HiveKeys.homeDataKey,
        jsonEncode(model.toJson()),
      );
    } catch (e) {
      AppLogger.w(_tag, 'Failed to save home cache: $e');
    }
  }
}
