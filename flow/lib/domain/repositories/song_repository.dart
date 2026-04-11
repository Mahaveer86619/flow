import '../entities/home_data.dart';
import '../entities/song.dart';

// ── Repository Interface ──────────────────────────────────────────────────────
//
// One method per screen's data need. The concrete implementation (data layer)
// is injected at the composition root — the domain never knows which source.
// ─────────────────────────────────────────────────────────────────────────────

abstract class SongRepository {
  /// Structured home screen data — all sections in one call.
  Future<HomeData> getHomeData();

  /// Songs matching [query] via the backend search or local filter.
  Future<List<Song>> searchSongs(String query);

  /// User playlist metadata for the library screen.
  Future<List<Playlist>> getPlaylists();

  /// Tracks for a playlist (for queue loading / playlist detail).
  Future<List<Song>> getPlaylistTracks(String playlistId, {int limit = 100});

  /// Tracks for an album.
  Future<List<Song>> getAlbumTracks(String browseId);

  /// Tracks from a radio station (up-next).
  Future<List<Song>> getRadioTracks(String videoId, {int limit = 25});

  /// Get multiple songs by their IDs.
  Future<List<Song>> getSongsByIds(List<String> ids);

  /// Static browse categories — synchronous, never needs the network.
  List<Map<String, dynamic>> getCategories();
}
