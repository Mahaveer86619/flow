import '../../models/home_data_model.dart';
import '../../models/playlist_model.dart';
import '../../models/song_model.dart';

// ── Data Source Interface ─────────────────────────────────────────────────────
//
// One method per screen — each returns exactly the data that screen needs.
// Swap implementations (mock ↔ API) in main.dart without touching anything above.
// ─────────────────────────────────────────────────────────────────────────────

abstract class MusicDataSource {
  /// Structured home screen data — maps to the five UI sections in one call.
  /// Pass [continuationToken] to fetch the next page of the home feed.
  Future<HomeDataModel> fetchHomeData({int limit = 25, String? continuationToken});

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

  /// Trigger background extraction for a track.
  Future<void> prefetchAudio(String videoId);

  /// Record a song play in persistent history.
  Future<void> recordPlay(SongModel song);

  /// Fetch persistent play history with date segmentation.
  Future<Map<String, dynamic>> fetchPersistentHistory();

  /// Get detailed metadata for a specific song (biography, etc.)
  Future<Map<String, dynamic>> fetchSongDetails(String videoId);

  /// Get detailed info for an artist (bio, image, etc.)
  Future<Map<String, dynamic>> fetchArtistDetails(String browseId);

  /// Static browse categories.
  List<Map<String, dynamic>> fetchCategories();

  /// Get personalized recommendations.
  Future<List<SongModel>> fetchRecommendations({int limit = 20});

  /// Get blended recommendations.
  Future<List<SongModel>> fetchBlendedRecommendations(String friendId, {int limit = 20});

  // ── Flow Playlist CRUD ────────────────────────────────────────────────────────

  /// Create a new Flow playlist.
  Future<PlaylistModel> createFlowPlaylist({
    required String title,
    String description = '',
    bool isPublic = false,
  });

  /// Update title/description/visibility of a Flow playlist.
  Future<PlaylistModel> updateFlowPlaylist(
    String playlistId, {
    String? title,
    String? description,
    bool? isPublic,
  });

  /// Permanently delete a Flow playlist.
  Future<void> deleteFlowPlaylist(String playlistId);

  /// Add a song to a Flow playlist.
  Future<void> addTrackToFlowPlaylist(
    String playlistId,
    SongModel song,
  );

  /// Remove a track from a Flow playlist.
  Future<void> removeTrackFromFlowPlaylist(String playlistId, int trackId);

  /// Add a collaborator by their user code.
  Future<void> addCollaborator(String playlistId, String userCode);

  /// Remove a collaborator by their user code.
  Future<void> removeCollaborator(String playlistId, String userCode);

  /// Like/Subscribe to an artist.
  Future<void> likeArtist(String channelId);

  /// Unlike/Unsubscribe from an artist.
  Future<void> unlikeArtist(String channelId);
}
