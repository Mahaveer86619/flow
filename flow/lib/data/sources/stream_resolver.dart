import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../core/logger/app_logger.dart';
import '../../core/network/dio_client.dart';

class StreamResolver {
  static final StreamResolver _instance = StreamResolver._internal();
  static StreamResolver get instance => _instance;

  final YoutubeExplode _yt = YoutubeExplode();
  final Dio _dio = DioClient.instance.dio;

  StreamResolver._internal();

  static const _tag = 'StreamResolver';

  Future<String?> resolveYoutubeStream(String videoId) async {
    try {
      AppLogger.i(_tag, 'Resolving stream for videoId: $videoId (InnerTube Player)');

      final response = await _dio.post(
        'https://music.youtube.com/youtubei/v1/player?prettyPrint=false',
        data: {
          "videoId": videoId,
          "context": {
            "client": {
              "clientName": "ANDROID_MUSIC",
              "clientVersion": "6.01.51",
              "hl": "en",
              "gl": "US"
            }
          }
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final streamingData = data['streamingData'];
        
        if (streamingData != null && streamingData['adaptiveFormats'] != null) {
          final List<dynamic> formats = streamingData['adaptiveFormats'];
          
          // Filter for audio only streams
          final audioStreams = formats.where((f) {
            final mimeType = f['mimeType'] as String?;
            return mimeType != null && mimeType.startsWith('audio/');
          }).toList();

          if (audioStreams.isNotEmpty) {
            // Sort by bitrate descending to get best quality
            audioStreams.sort((a, b) {
              final bitrateA = a['averageBitrate'] ?? a['bitrate'] ?? 0;
              final bitrateB = b['averageBitrate'] ?? b['bitrate'] ?? 0;
              return (bitrateB as int).compareTo(bitrateA as int);
            });

            final bestStream = audioStreams.first;
            final url = bestStream['url'] as String?;
            
            if (url != null) {
              AppLogger.d(_tag, 'InnerTube resolved: $url');
              return url;
            }
          }
        }
      }
      
      AppLogger.w(_tag, 'InnerTube player failed or returned no streams, falling back to YoutubeExplode');
      return _resolveFallback(videoId);
    } catch (e, st) {
      AppLogger.e(_tag, 'InnerTube player exception, falling back', e, st);
      return _resolveFallback(videoId);
    }
  }

  Future<String?> _resolveFallback(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      return streamInfo.url.toString();
    } catch (e) {
      AppLogger.e(_tag, 'Fallback resolution failed', e);
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}
