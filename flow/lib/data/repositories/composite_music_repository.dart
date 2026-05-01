import '../../domain/entities/track.dart';
import '../../domain/repositories/music_source_adapter.dart';
import '../../domain/repositories/music_repository.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/entities/history_data.dart';

class CompositeMusicRepository implements MusicRepository {
  final List<MusicSourceAdapter> adapters;
  final MusicRepository primaryRemote;

  CompositeMusicRepository({
    required this.adapters,
    required this.primaryRemote,
  });

  @override
  Future<List<Song>> searchSongs(String query, {int limit = 25}) async {
    final List<Track> allTracks = [];
    
    // Search across all adapters
    final results = await Future.wait(adapters.map((a) => a.search(query)));
    for (final list in results) {
      allTracks.addAll(list);
    }

    // Merge tracks by fingerprint to avoid duplicates
    final Map<String, Track> merged = {};
    for (final t in allTracks) {
      final existing = merged[t.fingerprint];
      if (existing == null) {
        merged[t.fingerprint] = t;
      } else {
        // Merge metadata/IDs
        merged[t.fingerprint] = existing.copyWith(
          youtubeId: existing.youtubeId ?? t.youtubeId,
          downloadedPath: existing.downloadedPath ?? t.downloadedPath,
          downloaded: existing.downloaded || t.downloaded,
        );
      }
    }

    // Map back to Song entities for the UI
    // In a real refactor, the UI should use Track, but for now we bridge
    return merged.values.map((t) => _trackToSong(t)).toList();
  }

  Song _trackToSong(Track t) {
    return Song(
      id: t.id,
      title: t.title,
      artist: t.artist,
      album: t.album ?? '',
      duration: const Duration(minutes: 3), // TODO: Real duration
      thumbnailUrl: t.artworkUrl,
      isDownloaded: t.downloaded,
      extras: {
        'artistId': t.artistId,
        'albumId': t.albumId,
        'year': t.year,
        'genres': t.genres,
        'tags': t.tags,
        'youtubeId': t.youtubeId,
        'fingerprint': t.fingerprint,
      },
    );
  }

  @override
  Future<HomeData> getHomeData({int limit = 25}) => primaryRemote.getHomeData(limit: limit);

  @override
  Future<List<Playlist>> getPlaylists() => primaryRemote.getPlaylists();

  @override
  Future<List<Song>> getPlaylistTracks(String playlistId, {int limit = 100}) => primaryRemote.getPlaylistTracks(playlistId, limit: limit);

  @override
  Future<List<Song>> getAlbumTracks(String browseId, {int limit = 25}) => primaryRemote.getAlbumTracks(browseId, limit: limit);

  @override
  Future<List<Song>> getArtistSongs(String channelId) => primaryRemote.getArtistSongs(channelId);

  @override
  Future<List<Song>> getRadioTracks(String videoId, {int limit = 25}) => primaryRemote.getRadioTracks(videoId, limit: limit);

  @override
  Future<void> likeArtist(String channelId) => primaryRemote.likeArtist(channelId);

  @override
  Future<void> unlikeArtist(String channelId) => primaryRemote.unlikeArtist(channelId);

  @override
  Future<List<Song>> getSongsByIds(List<String> ids) => primaryRemote.getSongsByIds(ids);

  @override
  Future<void> prefetchAudio(String videoId) => primaryRemote.prefetchAudio(videoId);

  @override
  Future<void> recordPlay(Song song) => primaryRemote.recordPlay(song);

  @override
  Future<HistoryData> getPersistentHistory() => primaryRemote.getPersistentHistory();

  @override
  Future<void> recordSearch(String query) => primaryRemote.recordSearch(query);

  @override
  List<String> getTopArtists() => primaryRemote.getTopArtists();

  @override
  void recordPodcastInterest(String artistName) => primaryRemote.recordPodcastInterest(artistName);

  @override
  void recordLofiInterest(String artistName) => primaryRemote.recordLofiInterest(artistName);

  @override
  Future<Map<String, dynamic>> getSongDetails(String videoId) => primaryRemote.getSongDetails(videoId);

  @override
  Future<Map<String, dynamic>> getArtistDetails(String browseId) => primaryRemote.getArtistDetails(browseId);

  @override
  List<Map<String, dynamic>> getCategories() => primaryRemote.getCategories();

  @override
  Future<List<Song>> getRecommendations({int limit = 20}) => primaryRemote.getRecommendations(limit: limit);

  @override
  Future<Playlist> createFlowPlaylist({required String title, String description = '', bool isPublic = false}) => primaryRemote.createFlowPlaylist(title: title, description: description, isPublic: isPublic);

  @override
  Future<Playlist> updateFlowPlaylist(String playlistId, {String? title, String? description, bool? isPublic}) => primaryRemote.updateFlowPlaylist(playlistId, title: title, description: description, isPublic: isPublic);

  @override
  Future<void> deleteFlowPlaylist(String playlistId) => primaryRemote.deleteFlowPlaylist(playlistId);

  @override
  Future<void> addTrackToFlowPlaylist(String playlistId, Song song) => primaryRemote.addTrackToFlowPlaylist(playlistId, song);

  @override
  Future<void> removeTrackFromFlowPlaylist(String playlistId, int trackId) => primaryRemote.removeTrackFromFlowPlaylist(playlistId, trackId);

  @override
  Future<void> addCollaborator(String playlistId, String userCode) => primaryRemote.addCollaborator(playlistId, userCode);

  @override
  Future<void> removeCollaborator(String playlistId, String userCode) => primaryRemote.removeCollaborator(playlistId, userCode);
}
