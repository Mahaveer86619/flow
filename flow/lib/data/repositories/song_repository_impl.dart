import '../../core/error/app_exception.dart';
import '../../core/logger/app_logger.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
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
      final models = await _source.fetchSongsByIds(ids);
      final songs = models.map((m) => m.toEntity()).toList();
      AppLogger.d(_tag, 'getSongsByIds: ${songs.length} songs');
      return songs;
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(_tag, 'getSongsByIds failed', e, st);
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
