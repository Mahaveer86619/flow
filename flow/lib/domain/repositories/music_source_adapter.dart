import '../entities/track.dart';

enum Quality { low, medium, high }

class StreamUrl {
  final String url;
  final Quality quality;
  final String? format;

  StreamUrl({required this.url, required this.quality, this.format});
}

abstract class MusicSourceAdapter {
  Future<List<Track>> search(String query);
  Future<StreamUrl?> getStreamUrl(Track track, {Quality quality = Quality.high});
  Future<List<Track>> getUserLibrary();
  Future<List<Track>> getCreatorTracks(String creatorId);
  Future<List<Track>> getAlbumTracks(String albumId);
  Future<List<Track>> getSimilar(Track seed);
}
