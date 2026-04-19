import '../entities/home_data.dart';
import '../entities/song.dart';
import '../entities/history_data.dart';

// ── Repository Interface ──────────────────────────────────────────────────────
//
// One method per screen's data need. The concrete implementation (data layer)
// is injected at the composition root — the domain never knows which source.
// ─────────────────────────────────────────────────────────────────────────────

abstract class MusicRepository {
  /// Structured home screen data — all sections in one call.
  Future<HomeData> getHomeData({int limit = 25});

  /// Songs matching [query] via the backend search or local filter.
  Future<List<Song>> searchSongs(String query, {int limit = 25});

  /// User playlist metadata for the library screen.
  Future<List<Playlist>> getPlaylists();

  /// Tracks for a playlist (for queue loading / playlist detail).
  Future<List<Song>> getPlaylistTracks(String playlistId, {int limit = 100});

  /// Tracks for an album.
  Future<List<Song>> getAlbumTracks(String browseId, {int limit = 25});

  /// Tracks for an artist.
  Future<List<Song>> getArtistSongs(String channelId);

  /// Tracks from a radio station (up-next).
  Future<List<Song>> getRadioTracks(String videoId, {int limit = 25});

  /// Like/Subscribe to an artist.
  Future<void> likeArtist(String channelId);

  /// Unlike/Unsubscribe from an artist.
  Future<void> unlikeArtist(String channelId);

  /// Get multiple songs by their IDs.
  Future<List<Song>> getSongsByIds(List<String> ids);

  /// Trigger background extraction for a track.
  Future<void> prefetchAudio(String videoId);

  /// Record a song play in persistent history.
  Future<void> recordPlay(Song song);

  /// Fetch persistent play history with date segmentation.
  Future<HistoryData> getPersistentHistory();

  /// Static browse categories — synchronous, never needs the network.
  List<Map<String, dynamic>> getCategories();

  // ── Flow Playlist CRUD ────────────────────────────────────────────────────────

  /// Create a new Flow playlist owned by the current user.
  Future<Playlist> createFlowPlaylist({
    required String title,
    String description = '',
    bool isPublic = false,
  });

  /// Update title/description/visibility of a Flow playlist.
  Future<Playlist> updateFlowPlaylist(
    String playlistId, {
    String? title,
    String? description,
    bool? isPublic,
  });

  /// Permanently delete a Flow playlist (owner only).
  Future<void> deleteFlowPlaylist(String playlistId);

  /// Add a song to a Flow playlist (owner or collaborator).
  Future<void> addTrackToFlowPlaylist(String playlistId, Song song);

  /// Remove a track from a Flow playlist by its DB track id.
  Future<void> removeTrackFromFlowPlaylist(String playlistId, int trackId);

  /// Add a collaborator by their user code (e.g. "mahaveer#1234").
  Future<void> addCollaborator(String playlistId, String userCode);

  /// Remove a collaborator by their user code.
  Future<void> removeCollaborator(String playlistId, String userCode);
}
