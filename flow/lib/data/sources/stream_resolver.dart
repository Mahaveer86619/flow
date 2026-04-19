import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../core/storage/local_storage.dart';
import '../../core/logger/app_logger.dart';
// import '../../core/network/dio_client.dart';

class StreamResolver {
  static final StreamResolver _instance = StreamResolver._internal();
  static StreamResolver get instance => _instance;

  final YoutubeExplode _yt = YoutubeExplode();
  
  // Use a clean Dio instance for player requests to avoid interceptor side-effects (cookies/headers)
  // that can break native-emulated clients.
  final Dio _playerDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  StreamResolver._internal();

  static const _tag = 'StreamResolver';

  Future<String?> resolveYoutubeStream(String videoId) async {
    try {
      AppLogger.i(_tag, 'Resolving stream for videoId: $videoId');

      final visitorData = LocalStorage.instance.getCachedMetadata('yt_visitor_data') as String?;

      // Optimized client list:
      // 1. ANDROID_VR is currently very stable for direct URLs.
      // 2. IOS is a good secondary native client.
      // 3. WEB_REMIX as a reliable web fallback.
      // 4. MWEB for mobile web fallback.
      final clients = [
        {
          "clientName": "ANDROID_VR",
          "clientVersion": "1.50.46",
        },
        {
          "clientName": "IOS",
          "clientVersion": "19.29.1",
        },
        {
          "clientName": "WEB_REMIX",
          "clientVersion": "1.20240409.01.01",
        },
        {
          "clientName": "MWEB",
          "clientVersion": "2.20240210.01.00",
        },
      ];

      final endpoints = [
        'https://www.youtube.com/youtubei/v1/player',
        'https://music.youtube.com/youtubei/v1/player',
      ];

      for (var client in clients) {
        for (var endpoint in endpoints) {
          try {
            final response = await _playerDio.post(
              '$endpoint?prettyPrint=false',
              data: {
                "videoId": videoId,
                "context": {
                  "client": {
                    ...client,
                    "hl": "en",
                    "gl": "US",
                    "visitorData": visitorData,
                  }
                }
              },
            );

            if (response.statusCode == 200) {
              final data = response.data as Map<String, dynamic>;
              
              final playability = data['playabilityStatus'];
              final status = playability?['status'] as String?;
              if (status != null && status != 'OK') {
                continue; // Try next endpoint/client
              }

              final streamingData = data['streamingData'];
              if (streamingData != null) {
                final List<dynamic> formats = (streamingData['adaptiveFormats'] as List<dynamic>? ?? []) + 
                                              (streamingData['formats'] as List<dynamic>? ?? []);
                
                final audioStreams = formats.where((f) {
                  final mimeType = f['mimeType'] as String?;
                  return mimeType != null && mimeType.contains('audio/');
                }).toList();

                if (audioStreams.isNotEmpty) {
                  audioStreams.sort((a, b) {
                    final bitrateA = a['averageBitrate'] ?? a['bitrate'] ?? 0;
                    final bitrateB = b['averageBitrate'] ?? b['bitrate'] ?? 0;
                    return (bitrateB as int).compareTo(bitrateA as int);
                  });

                  // We MUST have a direct 'url'. If it has 'signatureCipher', we skip it
                  // as we don't have a decipherer implemented yet.
                  final bestStream = audioStreams.firstWhere(
                    (f) => f['url'] != null, 
                    orElse: () => null
                  );
                  
                  if (bestStream != null) {
                    final url = bestStream['url'] as String;
                    AppLogger.i(_tag, 'Resolved: ${client['clientName']} (${endpoint.contains('music') ? 'YTM' : 'WWW'})');
                    return url;
                  }
                }
              }
            }
          } catch (e) {
            // Silence and continue
          }
        }
      }
      
      AppLogger.w(_tag, 'All InnerTube clients failed, falling back to YoutubeExplode');
      return _resolveFallback(videoId);
    } catch (e, st) {
      AppLogger.e(_tag, 'Stream resolution critical failure', e, st);
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
