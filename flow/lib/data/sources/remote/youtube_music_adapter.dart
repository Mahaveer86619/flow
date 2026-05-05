import '../../../domain/entities/track.dart';
import '../../../domain/repositories/music_source_adapter.dart';
import 'youtube_music_data_source.dart';
import 'music_data_source.dart';
import 'stream_resolver.dart';

class YoutubeMusicAdapter implements MusicSourceAdapter {
  final MusicDataSource dataSource;
  final StreamResolver resolver;

  YoutubeMusicAdapter({required this.dataSource, required this.resolver});


  @override
  Future<List<Track>> search(String query) async {
    final results = await dataSource.searchSongs(query);
    // results is List<SongModel>, need to map to Track
    return results.map((m) => Track.fromSong(m.toEntity())).toList();
  }

  @override
  Future<StreamUrl?> getStreamUrl(Track track, {Quality quality = Quality.high}) async {
    final videoId = track.youtubeId ?? track.id;
    final url = await resolver.resolveYoutubeStream(videoId);
    if (url != null) {
      return StreamUrl(url: url, quality: Quality.high);
    }
    return null;
  }

  @override
  Future<List<Track>> getUserLibrary() async => [];

  @override
  Future<List<Track>> getCreatorTracks(String creatorId) async => [];

  @override
  Future<List<Track>> getAlbumTracks(String albumId) async => [];

  @override
  Future<List<Track>> getSimilar(Track seed) async => [];
}
