import '../models/home_data_model.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

// ── Data Source Interface ─────────────────────────────────────────────────────
//
// One method per screen — each returns exactly the data that screen needs.
// Swap implementations (mock ↔ API) in main.dart without touching anything above.
// ─────────────────────────────────────────────────────────────────────────────

abstract class SongDataSource {
  /// Structured home screen data — maps to the five UI sections in one call.
  /// Requires authentication on the server; throws [AuthException] if not set up.
  Future<HomeDataModel> fetchHomeData();

  /// Unauthenticated home feed — returns trending / charts only.
  /// Safe to call without server authentication.
  Future<HomeDataModel> fetchFeed();

  /// Song search results for the given query.
  Future<List<SongModel>> searchSongs(String query);

  /// Playlist metadata for the library screen (no embedded tracks).
  /// Requires authentication; throws [AuthException] if not set up.
  Future<List<PlaylistModel>> fetchPlaylists();

  /// Tracks for a specific playlist (for the queue / playlist detail screen).
  Future<List<SongModel>> fetchPlaylistTracks(
    String playlistId, {
    int limit = 100,
  });

  /// Tracks for an album.
  Future<List<SongModel>> fetchAlbumTracks(String browseId);

  /// Tracks from a radio station (up-next).
  Future<List<SongModel>> fetchRadioTracks(String videoId, {int limit = 25});

  /// Static browse categories — always synchronous, never needs the network.
  List<Map<String, dynamic>> fetchCategories();

  /// Returns true if the server currently has valid authentication configured.
  Future<bool> checkAuthStatus();
}
