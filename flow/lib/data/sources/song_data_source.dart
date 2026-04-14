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
  Future<HomeDataModel> fetchHomeData({int limit = 25});

  /// Song search results for the given query.
  Future<List<SongModel>> searchSongs(String query, {int limit = 25});

  /// Playlist metadata for the library screen (no embedded tracks).
  Future<List<PlaylistModel>> fetchPlaylists();

  /// Tracks for a specific playlist (for the queue / playlist detail screen).
  Future<List<SongModel>> fetchPlaylistTracks(
    String playlistId, {
    int limit = 100,
  });

  /// Tracks for an album.
  Future<List<SongModel>> fetchAlbumTracks(String browseId, {int limit = 25});

  /// Tracks for an artist.
  Future<List<SongModel>> fetchArtistSongs(String channelId);

  /// Tracks from a radio station (up-next).
  Future<List<SongModel>> fetchRadioTracks(String videoId, {int limit = 25});

  /// Get multiple songs by their IDs.
  Future<List<SongModel>> fetchSongsByIds(List<String> ids);

  /// Proactively trigger background extraction.
  Future<void> prefetchAudio(String videoId);

  /// Record a song play in persistent history.
  Future<void> recordPlay(SongModel song);

  /// Fetch persistent play history with date segmentation.
  Future<Map<String, dynamic>> fetchPersistentHistory();

  /// Static browse categories — always synchronous, never needs the network.
  List<Map<String, dynamic>> fetchCategories();

  // --- Playlist Management ---

  /// Create a new playlist.
  Future<String> createPlaylist({
    required String title,
    String? description,
    String? privacyStatus,
    List<String>? videoIds,
    String? sourcePlaylist,
  });

  /// Edit an existing playlist.
  Future<void> editPlaylist({
    required String playlistId,
    String? title,
    String? description,
    String? privacyStatus,
  });

  /// Delete a playlist.
  Future<void> deletePlaylist(String playlistId);

  /// Add tracks to a playlist.
  Future<void> addPlaylistItems({
    required String playlistId,
    required List<String> videoIds,
    String? sourcePlaylist,
    bool duplicates = false,
  });

  /// Remove tracks from a playlist.
  Future<void> removePlaylistItems({
    required String playlistId,
    required List<Map<String, dynamic>> videos,
  });

  // --- Artist Management ---

  /// Like/Subscribe to an artist.
  Future<void> likeArtist(String channelId);

  /// Unlike/Unsubscribe from an artist.
  Future<void> unlikeArtist(String channelId);
}
