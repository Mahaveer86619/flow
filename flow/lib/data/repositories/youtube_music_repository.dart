import '../../../core/intelligence/app_intelligence.dart';
import '../../domain/engines/taste_blend_engine.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../sources/local/download_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/history_data.dart';
import '../../domain/repositories/music_repository.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../sources/remote/music_data_source.dart';

class YoutubeMusicRepository implements MusicRepository {
  final MusicDataSource _source;
  final _cacheTtl = const Duration(minutes: 30);
  static const _tag = 'MusicRepository';

  YoutubeMusicRepository(this._source);

  @override
  Future<HomeData> getHomeData({int limit = 25}) async {
    AppLogger.i(_tag, 'getHomeData(limit: $limit)');
    try {
      final model = await _source.fetchHomeData(limit: limit);
      final mappedShelves = _mapShelves(model.rawShelves);

      final entity = HomeData(
        shelves: mappedShelves,
        trending: model.trending.map((m) => m.toEntity()).toList(),
      );

      AppLogger.i(_tag, 'Repository: mapped ${mappedShelves.length} shelves');
      for (final shelf in mappedShelves) {
        AppLogger.d(
          _tag,
          'Mapped shelf: "${shelf.title}" with ${shelf.items.length} items',
        );
      }

      AppLogger.d(_tag, 'getHomeData: allSongs=${entity.allSongs.length}');
      return entity;
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'getHomeData failed', e, st);
      throw toAppException(e);
    }
  }

  List<HomeShelf> _mapShelves(List<Map<String, dynamic>> raw) {
    return raw.map((shelf) {
      final items = (shelf['items'] as List? ?? []).map((it) {
        final type = it['type'] as String;
        final data = it['data'];
        HomeItemType itemType;
        dynamic mappedData;

        switch (type) {
          case 'song':
            itemType = HomeItemType.song;
            mappedData = SongModel.fromJson(
              data as Map<String, dynamic>,
            ).toEntity();
            break;
          case 'playlist':
            itemType = HomeItemType.playlist;
            mappedData = PlaylistModel.fromJson(
              data as Map<String, dynamic>,
            ).toEntity();
            break;
          default:
            itemType = HomeItemType.song; // Fallback
            mappedData = data;
        }

        return HomeItem(type: itemType, data: mappedData);
      }).toList();

      return HomeShelf(
        title: shelf['title'] ?? 'More',
        section: shelf['section'],
        items: items,
      );
    }).toList();
  }

  @override
  Future<List<Song>> searchSongs(String query, {int limit = 25}) async {
    AppLogger.i(_tag, 'searchSongs("$query", limit: $limit)');
    try {
      final models = await _source.searchSongs(query, limit: limit);
      final songs = models.map((m) => m.toEntity()).toList();
      AppLogger.d(_tag, 'searchSongs("$query"): ${songs.length} hits');
      return songs;
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'searchSongs failed', e, st);
      throw toAppException(e);
    }
  }

  @override
  Future<List<Playlist>> getPlaylists() async {
    AppLogger.i(_tag, 'getPlaylists()');
    try {
      final models = await _source.fetchPlaylists();
      final playlists = models.map((m) => m.toEntity()).toList();
      AppLogger.d(_tag, 'getPlaylists: ${playlists.length}');
      return playlists;
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'getPlaylists failed', e, st);
      throw toAppException(e);
    }
  }

  @override
  Future<List<Song>> getPlaylistTracks(
    String playlistId, {
    int limit = 100,
  }) async {
    try {
      final models = await _source.fetchPlaylistTracks(
        playlistId,
        limit: limit,
      );
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw toAppException(e);
    }
  }

  @override
  Future<List<Song>> getAlbumTracks(String browseId, {int limit = 25}) async {
    try {
      final models = await _source.fetchAlbumTracks(browseId, limit: limit);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw toAppException(e);
    }
  }

  @override
  Future<List<Song>> getArtistSongs(String channelId) async {
    try {
      final models = await _source.fetchArtistSongs(channelId);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw toAppException(e);
    }
  }

  @override
  Future<List<Song>> getRadioTracks(String videoId, {int limit = 25}) async {
    try {
      final models = await _source.fetchRadioTracks(videoId, limit: limit);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw toAppException(e);
    }
  }

  @override
  Future<List<Song>> getSongsByIds(List<String> ids) async {
    try {
      final models = await _source.fetchSongsByIds(ids);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw toAppException(e);
    }
  }

  @override
  Future<void> prefetchAudio(String videoId) async {
    await _source.prefetchAudio(videoId);
  }

  @override
  Future<void> recordPlay(Song song) async {
    final model = SongModel.fromEntity(song);
    await _source.recordPlay(model);
  }

  @override
  Future<HistoryData> getPersistentHistory() async {
    return const HistoryData.empty();
  }

  @override
  Future<void> recordSearch(String query) async {}

  @override
  Future<List<String>> getTopArtists() async => [];

  @override
  void recordPodcastInterest(String artistName) {}

  @override
  void recordLofiInterest(String artistName) {}

  @override
  Future<Map<String, dynamic>> getSongDetails(String videoId) async {
    return _source.fetchSongDetails(videoId);
  }

  @override
  Future<Map<String, dynamic>> getArtistDetails(String browseId) async {
    return _source.fetchArtistDetails(browseId);
  }

  @override
  List<Map<String, dynamic>> getCategories() {
    return _source.fetchCategories();
  }

  @override
  Future<List<Song>> getRecommendations({int limit = 20}) async {
    try {
      final models = await _source.fetchRecommendations(limit: limit);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw toAppException(e);
    }
  }

  @override
  Future<List<Song>> getBlendedRecommendations(
    String friendId, {
    int limit = 20,
  }) async {
    try {
      final models = await _source.fetchBlendedRecommendations(
        friendId,
        limit: limit,
      );
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw toAppException(e);
    }
  }

  @override
  Future<Playlist> createFlowPlaylist({
    required String title,
    String description = '',
    bool isPublic = false,
  }) async {
    final model = await _source.createFlowPlaylist(
      title: title,
      description: description,
      isPublic: isPublic,
    );
    return model.toEntity();
  }

  @override
  Future<Playlist> updateFlowPlaylist(
    String playlistId, {
    String? title,
    String? description,
    bool? isPublic,
  }) async {
    final model = await _source.updateFlowPlaylist(
      playlistId,
      title: title,
      description: description,
      isPublic: isPublic,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteFlowPlaylist(String playlistId) async {
    await _source.deleteFlowPlaylist(playlistId);
  }

  @override
  Future<void> addTrackToFlowPlaylist(String playlistId, Song song) async {
    final model = SongModel.fromEntity(song);
    await _source.addTrackToFlowPlaylist(playlistId, model);
  }

  @override
  Future<void> removeTrackFromFlowPlaylist(
    String playlistId,
    int trackId,
  ) async {
    await _source.removeTrackFromFlowPlaylist(playlistId, trackId);
  }

  @override
  Future<void> addCollaborator(String playlistId, String userCode) async {
    await _source.addCollaborator(playlistId, userCode);
  }

  @override
  Future<void> removeCollaborator(String playlistId, String userCode) async {
    await _source.removeCollaborator(playlistId, userCode);
  }

  @override
  Future<void> likeArtist(String channelId) async {
    await _source.likeArtist(channelId);
  }

  @override
  Future<void> unlikeArtist(String channelId) async {
    await _source.unlikeArtist(channelId);
  }
}
