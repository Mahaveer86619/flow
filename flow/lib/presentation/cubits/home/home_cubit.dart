import 'dart:convert';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/app_event_bus.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/storage/hive_keys.dart';
import '../../../core/storage/local_storage.dart';
import '../../../data/models/home_data_model.dart';
import '../../../data/models/song_model.dart';
import '../../../data/models/playlist_model.dart';
import '../../../domain/entities/home_data.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/usecases/get_home_data_usecase.dart';
import '../../../domain/repositories/music_repository.dart';
import '../../../core/intelligence/app_intelligence.dart';
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
       super(const HomeState()) {
    _eventSub = AppEventBus.instance.events.listen((event) {
      if (event is RefreshHomeEvent) {
        refresh();
      }
    });
  }

  @override
  Future<void> close() {
    _eventSub?.cancel();
    return super.close();
  }

  Future<void> init() async {
    final cached = LocalStorage.instance.getCachedMetadata(
      HiveKeys.homeDataKey,
    );
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached as String);
        final model = HomeDataModel.fromJson(decoded as Map<String, dynamic>);
        final entity = model.toEntity();
        emit(
          HomeState(
            shelves: entity.shelves,
            allSongs: entity.allSongs,
            status: HomeStatus.success,
          ),
        );
      } catch (e) {
        AppLogger.w(_tag, 'Failed to parse home cache: $e');
      }
    }
    await refresh();
  }

  Future<void> refresh() async {
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      final data = await _getHomeData();
      final List<HomeShelf> finalShelves = List.from(data.shelves);

      if (AppConfig.intelligenceActive) {
        // 1. Add "Flow Intelligence" if not already there
        if (!finalShelves.any((s) => s.section == 'flowIntelligence')) {
          try {
            final recommendations = await _musicRepository.getRecommendations(
              limit: 15,
            );
            if (recommendations.isNotEmpty) {
              finalShelves.insert(
                0,
                HomeShelf(
                  title: 'Flow Intelligence',
                  section: 'flowIntelligence',
                  items: recommendations
                      .map((s) => HomeItem(type: HomeItemType.song, data: s))
                      .toList(),
                ),
              );
            }
          } catch (e) {
            AppLogger.w(_tag, 'Failed to fetch Flow Intelligence shelf: $e');
          }
        }

        // 2. Add "Daily Rotation" if history exists
        final storage = LocalStorage.instance;
        final recentIds = storage.recentlyPlayedIds;

        if (recentIds.isNotEmpty &&
            !finalShelves.any((s) => s.section == 'history_backfill')) {
          final songs = await _musicRepository.getSongsByIds(recentIds);
          songs.sort((a, b) {
            final aPlays = storage.artistPlayCounts[a.artist] ?? 0;
            final bPlays = storage.artistPlayCounts[b.artist] ?? 0;
            return bPlays.compareTo(aPlays);
          });

          final uniqueItems = songs
              .take(20)
              .map((s) => HomeItem(type: HomeItemType.song, data: s))
              .toList();

          if (uniqueItems.isNotEmpty) {
            finalShelves.add(
              HomeShelf(
                title: 'Daily Rotation',
                section: 'history_backfill',
                items: uniqueItems,
              ),
            );
          }
        }
      }

      final deduplicatedShelves = _deduplicateShelves(finalShelves);
      final allSongs = _extractAllSongs(deduplicatedShelves);

      emit(
        HomeState(
          shelves: deduplicatedShelves,
          allSongs: allSongs,
          status: HomeStatus.success,
        ),
      );

      _saveToCache(deduplicatedShelves);
    } on SourceException catch (e) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          error: e.message,
          errorCode: e.statusCode?.toString(),
        ),
      );
    } on AppException catch (e) {
      emit(state.copyWith(status: HomeStatus.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.failure, error: e.toString()));
    }
  }

  List<Song> _extractAllSongs(List<HomeShelf> shelves) {
    final seen = <String>{};
    final songs = <Song>[];
    for (final shelf in shelves) {
      for (final item in shelf.items) {
        // Both song and video items are playable
        if ((item.type == HomeItemType.song ||
                item.type == HomeItemType.video) &&
            item.data is Song) {
          final s = item.data as Song;
          if (seen.add(s.id)) songs.add(s);
        }
      }
    }
    return songs;
  }

  List<HomeShelf> _deduplicateShelves(List<HomeShelf> shelves) {
    final seenTitles = <String>{};
    return shelves.where((s) => seenTitles.add(s.title)).toList();
  }

  void _saveToCache(List<HomeShelf> shelves) {
    try {
      final model = HomeDataModel(
        rawShelves: shelves.map((s) {
          return {
            'title': s.title,
            'section': s.section,
            if (s.itemSize != null) 'itemSize': s.itemSize,
            'items': s.items.map((i) {
              String typeStr;
              Map<String, dynamic> dataJson;

              switch (i.type) {
                case HomeItemType.song:
                  typeStr = 'song';
                  dataJson = SongModel.fromEntity(i.data as Song).toJson();
                  break;
                case HomeItemType.video:
                  typeStr = 'video';
                  dataJson = SongModel.fromEntity(i.data as Song).toJson();
                  break;
                case HomeItemType.album:
                  typeStr = 'album';
                  dataJson = PlaylistModel.fromEntity(
                    i.data as Playlist,
                  ).toJson();
                  break;
                case HomeItemType.playlist:
                  typeStr = 'playlist';
                  dataJson = PlaylistModel.fromEntity(
                    i.data as Playlist,
                  ).toJson();
                  break;
                case HomeItemType.artist:
                  typeStr = 'artist';
                  final artistData = i.data as Map<String, dynamic>;
                  dataJson = {
                    'name': artistData['name'],
                    'thumbnailUrl': artistData['thumbnailUrl'],
                  };
                  break;
              }

              return {'type': typeStr, 'data': dataJson};
            }).toList(),
          };
        }).toList(),
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
