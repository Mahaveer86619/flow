import 'package:spotify/spotify.dart' as sp;
import '../../../domain/entities/track.dart';
import '../../../domain/repositories/music_source_adapter.dart';
import 'spotify_service.dart';
import '../../../core/logger/app_logger.dart';

class SpotifyAdapter implements MusicSourceAdapter {
  final SpotifyService _service = SpotifyService.instance;
  static const _tag = 'SpotifyAdapter';

  @override
  Future<List<Track>> search(String query) async {
    if (_service.api == null) return [];

    try {
      final results = await _service.api!.search.get(query, types: [sp.SearchType.track]).first(10);
      final tracks = <Track>[];

      for (final pages in results) {
        if (pages.items != null) {
          for (final item in pages.items!) {
            if (item is sp.Track) {
              tracks.add(_mapSpotifyTrack(item));
            }
          }
        }
      }
      return tracks;
    } catch (e) {
      AppLogger.e(_tag, 'Search failed', e);
      return [];
    }
  }

  Track _mapSpotifyTrack(sp.Track t) {
    return Track(
      id: t.id ?? 'sp:${t.hashCode}',
      title: t.name ?? 'Unknown',
      artist: t.artists?.first.name ?? 'Unknown Artist',
      artistId: t.artists?.first.id ?? 'unknown',
      album: t.album?.name,
      albumId: t.album?.id,
      year: t.album?.releaseDate,
      artworkUrl: t.album?.images?.first.url,
      spotifyId: t.id,
      // Metadata only
    );
  }

  @override
  Future<StreamUrl?> getStreamUrl(Track track, {Quality quality = Quality.high}) async {
    // Spotify is metadata-only as per idea.md
    return null;
  }

  @override
  Future<List<Track>> getUserLibrary() async => []; // Requires OAuth PKCE for real library

  @override
  Future<List<Track>> getCreatorTracks(String creatorId) async => [];

  @override
  Future<List<Track>> getAlbumTracks(String albumId) async => [];

  @override
  Future<List<Track>> getSimilar(Track seed) async => [];
}
