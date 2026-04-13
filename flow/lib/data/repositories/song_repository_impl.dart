import '../../core/error/app_exception.dart';
import '../../core/logger/app_logger.dart';
import '../../core/network/download_service.dart';
import '../../core/storage/local_storage.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/history_data.dart';
import '../../domain/repositories/song_repository.dart';
import '../models/song_model.dart';
import '../sources/song_data_source.dart';

// ── Repository Implementation ─────────────────────────────────────────────────
//
// Converts data-layer models into domain entities.
// The domain and presentation layers depend only on [SongRepository] — this
// class is invisible above the data boundary.
// ─────────────────────────────────────────────────────────────────────────────

class SongRepositoryImpl implements SongRepository {
  final SongDataSource _source;

  static const _tag = 'SongRepository';

  const SongRepositoryImpl(this._source);

  @override
  Future<HomeData> getHomeData() async {
    AppLogger.i(_tag, 'getHomeData()');
    try {
      final model = await _source.fetchHomeData();
      final entity = model.toEntity();
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
  Future<List<Song>> searchSongs(String query) async {
    AppLogger.i(_tag, 'searchSongs("$query")');
    try {
      final models = await _source.searchSongs(query);
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
    AppLogger.i(_tag, 'getPlaylistTracks($playlistId, limit=$limit)');
    try {
      final models = await _source.fetchPlaylistTracks(
        playlistId,
        limit: limit,
      );
      final tracks = models.map((m) => m.toEntity()).toList();
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
  Future<List<Song>> getAlbumTracks(String browseId) async {
    AppLogger.i(_tag, 'getAlbumTracks($browseId)');
    try {
      final models = await _source.fetchAlbumTracks(browseId);
      final tracks = models.map((m) => m.toEntity()).toList();
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
  Future<List<Song>> getSongsByIds(List<String> ids) async {
    AppLogger.i(_tag, 'getSongsByIds(${ids.length} ids)');
    try {
      final songs = <Song>[];
      final missingIds = <String>[];

      for (final id in ids) {
        final localMetadata = LocalStorage.instance.getDownloadMetadata(id);
        if (localMetadata != null) {
          songs.add(SongModel.fromJson(localMetadata).toEntity());
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
  List<Map<String, dynamic>> getCategories() {
    final cats = _source.fetchCategories();
    AppLogger.d(_tag, 'getCategories: ${cats.length}');
    return cats;
  }
}
