import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../core/logger/app_logger.dart';

class StreamResolver {
  static final StreamResolver _instance = StreamResolver._internal();
  static StreamResolver get instance => _instance;

  final YoutubeExplode _yt = YoutubeExplode();

  StreamResolver._internal();

  static const _tag = 'StreamResolver';

  Future<String?> resolveYoutubeStream(String videoId) async {
    try {
      AppLogger.i(_tag, 'Resolving stream for videoId: $videoId');
      
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      
      // We want audio only streams, preferably high quality
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      
      if (streamInfo != null) {
        AppLogger.d(_tag, 'Stream resolved: ${streamInfo.url}');
        return streamInfo.url.toString();
      } else {
        AppLogger.w(_tag, 'No audio stream found for $videoId');
        return null;
      }
    } catch (e) {
      AppLogger.e(_tag, 'Error resolving YouTube stream', e);
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}
