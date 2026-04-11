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
  Future<HomeDataModel> fetchHomeData();

  /// Song search results for the given query.
  Future<List<SongModel>> searchSongs(String query);

  /// Playlist metadata for the library screen (no embedded tracks).
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

  /// Get multiple songs by their IDs.
  Future<List<SongModel>> fetchSongsByIds(List<String> ids);

  /// Static browse categories — always synchronous, never needs the network.
  List<Map<String, dynamic>> fetchCategories();
}
