import '../../core/error/app_exception.dart';
import '../../core/logger/app_logger.dart';
import '../../core/network/download_service.dart';
import '../../core/storage/local_storage.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/history_data.dart';
import '../../domain/repositories/music_repository.dart';
import '../models/song_model.dart';
import '../sources/music_data_source.dart';

// ── Repository Implementation ─────────────────────────────────────────────────
//
// Converts data-layer models into domain entities.
// The domain and presentation layers depend only on [MusicRepository] — this
// class is invisible above the data boundary.
// ─────────────────────────────────────────────────────────────────────────────

class YoutubeMusicRepository implements MusicRepository {
  final MusicDataSource _source;

  static const _tag = 'MusicRepository';
  static const _cacheTtl = Duration(minutes: 30);

  const YoutubeMusicRepository(this._source);

  @override
  Future<HomeData> getHomeData({int limit = 25}) async {
    final cacheKey = 'home_data_$limit';
    /* 
    try {
      final cached = LocalStorage.instance.getCachedMetadata(cacheKey);
      if (cached != null && cached is Map) {
        final ts = cached['timestamp'] as int?;
        if (ts != null &&
            DateTime.now().millisecondsSinceEpoch - ts <
                _cacheTtl.inMilliseconds) {
          AppLogger.d(_tag, 'getHomeData: cache hit');
          return HomeDataModel.fromJson(
            Map<String, dynamic>.from(cached['data'] as Map),
          ).toEntity();
        }
      }
    } catch (e) {
      AppLogger.w(_tag, 'Failed to read home cache: $e');
    }
    */

    AppLogger.i(_tag, 'getHomeData(limit: $limit) - fetching fresh');
    try {
      final model = await _source.fetchHomeData(limit: limit);
      final entity = model.toEntity();

      // Persist to cache
      LocalStorage.instance.saveCachedMetadata(cacheKey, {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': model.toJson(),
      });

      AppLogger.d(_tag, 'getHomeData: allSongs=${entity.allSongs.length}');
      return entity;
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'getHomeData failed', e, st);
      throw toAppException(e);
    }
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
    final cacheKey = 'playlist_tracks_$playlistId';
    try {
      final cached = LocalStorage.instance.getCachedMetadata(cacheKey);
      if (cached != null && cached is Map) {
        final ts = cached['timestamp'] as int?;
        if (ts != null &&
            DateTime.now().millisecondsSinceEpoch - ts <
                _cacheTtl.inMilliseconds) {
          AppLogger.d(_tag, 'getPlaylistTracks($playlistId): cache hit');
          final list = cached['data'] as List;
          return list
              .map(
                (e) => SongModel.fromJson(Map<String, dynamic>.from(e as Map))
                    .toEntity(),
              )
              .toList();
        }
      }
    } catch (e) {
      AppLogger.w(_tag, 'Failed to read playlist cache: $e');
    }

    AppLogger.i(_tag, 'getPlaylistTracks($playlistId, limit=$limit)');
    try {
      final models = await _source.fetchPlaylistTracks(
        playlistId,
        limit: limit,
      );
      final tracks = models.map((m) => m.toEntity()).toList();

      // Persist to cache
      LocalStorage.instance.saveCachedMetadata(cacheKey, {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': models.map((m) => m.toJson()).toList(),
      });

      AppLogger.d(
        _tag,
        'getPlaylistTracks($playlistId): ${tracks.length} tracks',
      );
      return tracks;
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'getPlaylistTracks failed', e, st);
      throw toAppException(e);
    }
  }

  @override
  Future<List<Song>> getAlbumTracks(String browseId, {int limit = 25}) async {
    final cacheKey = 'album_tracks_$browseId';
    try {
      final cached = LocalStorage.instance.getCachedMetadata(cacheKey);
      if (cached != null && cached is Map) {
        final ts = cached['timestamp'] as int?;
        if (ts != null &&
            DateTime.now().millisecondsSinceEpoch - ts <
                _cacheTtl.inMilliseconds) {
          AppLogger.d(_tag, 'getAlbumTracks($browseId): cache hit');
          final list = cached['data'] as List;
          return list
              .map(
                (e) => SongModel.fromJson(Map<String, dynamic>.from(e as Map))
                    .toEntity(),
              )
              .toList();
        }
      }
    } catch (e) {
      AppLogger.w(_tag, 'Failed to read album cache: $e');
    }

    AppLogger.i(_tag, 'getAlbumTracks($browseId, limit: $limit)');
    try {
      final models = await _source.fetchAlbumTracks(browseId, limit: limit);
      final tracks = models.map((m) => m.toEntity()).toList();

      // Persist to cache
      LocalStorage.instance.saveCachedMetadata(cacheKey, {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': models.map((m) => m.toJson()).toList(),
      });

      AppLogger.d(_tag, 'getAlbumTracks($browseId): ${tracks.length} tracks');
      return tracks;
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'getAlbumTracks failed', e, st);
      throw toAppException(e);
    }
  }

  @override
  Future<List<Song>> getArtistSongs(String channelId) async {
    final cacheKey = 'artist_songs_$channelId';
    try {
      final cached = LocalStorage.instance.getCachedMetadata(cacheKey);
      if (cached != null && cached is Map) {
        final ts = cached['timestamp'] as int?;
        if (ts != null &&
            DateTime.now().millisecondsSinceEpoch - ts <
                _cacheTtl.inMilliseconds) {
          AppLogger.d(_tag, 'getArtistSongs($channelId): cache hit');
          final list = cached['data'] as List;
          return list
              .map(
                (e) => SongModel.fromJson(Map<String, dynamic>.from(e as Map))
                    .toEntity(),
              )
              .toList();
        }
      }
    } catch (e) {
      AppLogger.w(_tag, 'Failed to read artist songs cache: $e');
    }

    AppLogger.i(_tag, 'getArtistSongs($channelId)');
    try {
      final models = await _source.fetchArtistSongs(channelId);
      final songs = models.map((m) => m.toEntity()).toList();

      // Persist to cache
      LocalStorage.instance.saveCachedMetadata(cacheKey, {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': models.map((m) => m.toJson()).toList(),
      });

      return songs;
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'getArtistSongs failed', e, st);
      throw toAppException(e);
    }
  }

  @override
  Future<List<Song>> getRadioTracks(String videoId, {int limit = 25}) async {
    AppLogger.i(_tag, 'getRadioTracks($videoId, limit=$limit)');
    try {
      final models = await _source.fetchRadioTracks(videoId, limit: limit);
      final tracks = models.map((m) => m.toEntity()).toList();
      AppLogger.d(_tag, 'getRadioTracks($videoId): ${tracks.length} tracks');
      return tracks;
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'getRadioTracks failed', e, st);
      throw toAppException(e);
    }
  }

  @override
  Future<void> likeArtist(String channelId) async {
    try {
      await _source.likeArtist(channelId);
    } catch (e) {
      throw toAppException(e);
    }
  }

  @override
  Future<void> unlikeArtist(String channelId) async {
    try {
      await _source.unlikeArtist(channelId);
    } catch (e) {
      throw toAppException(e);
    }
  }

  @override
  Future<List<Song>> getSongsByIds(List<String> ids) async {
    AppLogger.i(_tag, 'getSongsByIds(${ids.length} ids)');
    try {
      final songs = <Song>[];
      final missingIds = <String>[];

      for (final id in ids) {
        final localMetadata = LocalStorage.instance.getDownloadMetadata(id) ??
            LocalStorage.instance.getCachedMetadata('song_meta_$id');
        if (localMetadata != null) {
          songs.add(
            SongModel.fromJson(Map<String, dynamic>.from(localMetadata as Map))
                .toEntity(),
          );
        } else {
          missingIds.add(id);
        }
      }

      if (missingIds.isNotEmpty) {
        try {
          final models = await _source.fetchSongsByIds(missingIds);
          for (final m in models) {
            songs.add(m.toEntity());
            // Heal local metadata if it was missing but song is downloaded
            if (DownloadService.instance.isDownloadedSync(m.id)) {
              LocalStorage.instance.saveDownloadMetadata(m.id, m.toJson());
            }
          }
        } catch (e) {
          // If we have some songs (from local), don't fail completely
          if (songs.isEmpty) rethrow;
          AppLogger.w(_tag, 'Failed to fetch missing songs from API: $e');
        }
      }

      // Maintain original order if possible
      final idToSong = {for (var s in songs) s.id: s};
      return ids.map((id) => idToSong[id]).whereType<Song>().toList();
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'getSongsByIds failed', e, st);
      throw toAppException(e);
    }
  }

  @override
  Future<void> prefetchAudio(String videoId) async {
    try {
      await _source.prefetchAudio(videoId);
    } catch (e) {
      // Don't throw for prefetch, just log
      AppLogger.w(_tag, 'Prefetch failed for $videoId: $e');
    }
  }

  @override
  Future<void> recordPlay(Song song) async {
    try {
      final model = SongModel(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: song.duration,
        thumbnailUrl: song.thumbnailUrl,
        colorPrimary: song.colorPrimary,
        colorSecondary: song.colorSecondary,
        isDownloaded: song.isDownloaded,
      );
      await _source.recordPlay(model);
    } catch (e) {
      AppLogger.w(_tag, 'Failed to record play history: $e');
    }
  }

  @override
  Future<HistoryData> getPersistentHistory() async {
    AppLogger.i(_tag, 'getPersistentHistory()');
    try {
      final Map<String, dynamic> json = await _source.fetchPersistentHistory();

      List<Song> parseList(dynamic list) {
        if (list == null || list is! List) return [];
        return list
            .map(
              (e) => SongModel.fromJson(e as Map<String, dynamic>).toEntity(),
            )
            .toList();
      }

      final byMonthRaw = json['byMonth'] as Map<String, dynamic>? ?? {};
      final byMonth = <String, List<Song>>{};
      byMonthRaw.forEach((key, value) {
        byMonth[key] = parseList(value);
      });

      return HistoryData(
        today: parseList(json['today']),
        thisWeek: parseList(json['thisWeek']),
        thisMonth: parseList(json['thisMonth']),
        byMonth: byMonth,
      );
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'getPersistentHistory failed', e, st);
      throw toAppException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getSongDetails(String videoId) async {
    try {
      return await _source.fetchSongDetails(videoId);
    } catch (e) {
      AppLogger.w(_tag, 'getSongDetails failed: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getArtistDetails(String browseId) async {
    final cacheKey = 'artist_details_$browseId';
    try {
      final cached = LocalStorage.instance.getCachedMetadata(cacheKey);
      if (cached != null && cached is Map) {
        final ts = cached['timestamp'] as int?;
        if (ts != null &&
            DateTime.now().millisecondsSinceEpoch - ts <
                _cacheTtl.inMilliseconds * 2) {
          return Map<String, dynamic>.from(cached['data'] as Map);
        }
      }
    } catch (_) {}

    try {
      final details = await _source.fetchArtistDetails(browseId);
      LocalStorage.instance.saveCachedMetadata(cacheKey, {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': details,
      });
      return details;
    } catch (e) {
      AppLogger.w(_tag, 'getArtistDetails failed: $e');
      return {};
    }
  }

  @override
  List<Map<String, dynamic>> getCategories() {
    final cats = _source.fetchCategories();
    AppLogger.d(_tag, 'getCategories: ${cats.length}');
    return cats;
  }

  // ── Flow Playlist CRUD ────────────────────────────────────────────────────────

  @override
  Future<Playlist> createFlowPlaylist({
    required String title,
    String description = '',
    bool isPublic = false,
  }) async {
    try {
      final model = await _source.createFlowPlaylist(
        title: title,
        description: description,
        isPublic: isPublic,
      );
      return model.toEntity();
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'createFlowPlaylist failed', e, st);
      throw toAppException(e);
    }
  }

  @override
  Future<Playlist> updateFlowPlaylist(
    String playlistId, {
    String? title,
    String? description,
    bool? isPublic,
  }) async {
    try {
      final model = await _source.updateFlowPlaylist(
        playlistId,
        title: title,
        description: description,
        isPublic: isPublic,
      );
      return model.toEntity();
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'updateFlowPlaylist failed', e, st);
      throw toAppException(e);
    }
  }

  @override
  Future<void> deleteFlowPlaylist(String playlistId) async {
    try {
      await _source.deleteFlowPlaylist(playlistId);
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'deleteFlowPlaylist failed', e, st);
      throw toAppException(e);
    }
  }

  @override
  Future<void> addTrackToFlowPlaylist(String playlistId, Song song) async {
    try {
      final songData = SongModel(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: song.duration,
        thumbnailUrl: song.thumbnailUrl,
        colorPrimary: song.colorPrimary,
        colorSecondary: song.colorSecondary,
      ).toJson();
      await _source.addTrackToFlowPlaylist(playlistId, songData);
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'addTrackToFlowPlaylist failed', e, st);
      throw toAppException(e);
    }
  }

  @override
  Future<void> removeTrackFromFlowPlaylist(
    String playlistId,
    int trackId,
  ) async {
    try {
      await _source.removeTrackFromFlowPlaylist(playlistId, trackId);
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'removeTrackFromFlowPlaylist failed', e, st);
      throw toAppException(e);
    }
  }

  @override
  Future<void> addCollaborator(String playlistId, String userCode) async {
    try {
      await _source.addCollaborator(playlistId, userCode);
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'addCollaborator failed', e, st);
      throw toAppException(e);
    }
  }

  @override
  Future<void> removeCollaborator(String playlistId, String userCode) async {
    try {
      await _source.removeCollaborator(playlistId, userCode);
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'removeCollaborator failed', e, st);
      throw toAppException(e);
    }
  }
}
