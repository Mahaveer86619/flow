import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/logger/app_logger.dart';

class StreamResolver {
  static final StreamResolver _instance = StreamResolver._internal();
  static StreamResolver get instance => _instance;

  final YoutubeExplode _yt = YoutubeExplode();

  final Dio _playerDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  StreamResolver._internal();

  static const _tag = 'StreamResolver';

  Future<String?> resolveYoutubeStream(String videoId) async {
    try {
      AppLogger.i(_tag, 'Resolving stream for videoId: $videoId');

      final visitorData =
          LocalStorage.instance.getCachedMetadata('yt_visitor_data') as String?;
      final cookies = await SecureStorageService.instance.getYoutubeCookies();

      // Modernized client list
      final clients = [
        {
          "clientName": "ANDROID_TESTSUITE",
          "clientVersion": "1.9.1",
          "osName": "Android",
          "osVersion": "14",
          "platform": "MOBILE",
        },
        {
          "clientName": "ANDROID",
          "clientVersion": "19.30.36",
          "osName": "Android",
          "osVersion": "14",
          "platform": "MOBILE",
        },
        {
          "clientName": "ANDROID_MUSIC",
          "clientVersion": "7.03.52",
          "osName": "Android",
          "osVersion": "14",
          "platform": "MOBILE",
        },
        {
          "clientName": "IOS",
          "clientVersion": "19.29.1",
          "osName": "iOS",
          "osVersion": "17.5.1",
          "platform": "MOBILE",
        },
      ];

      final endpoints = [
        'https://music.youtube.com/youtubei/v1/player',
        'https://www.youtube.com/youtubei/v1/player',
      ];

      for (var client in clients) {
        for (var endpoint in endpoints) {
          try {
            final response = await _playerDio.post(
              '$endpoint?prettyPrint=false',
              options: Options(
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
                  if (cookies != null) 'Cookie': cookies,
                  'Origin': 'https://music.youtube.com',
                  'Referer': 'https://music.youtube.com/',
                },
              ),
              data: {
                "videoId": videoId,
                "context": {
                  "client": {
                    ...client,
                    "hl": "en",
                    "gl": "US",
                    "visitorData": visitorData,
                  },
                },
              },
            );

            if (response.statusCode == 200) {
              final data = response.data as Map<String, dynamic>;

              final playability = data['playabilityStatus'];
              final status = playability?['status'] as String?;

              if (status != 'OK') {
                AppLogger.w(
                  _tag,
                  'Playability status [${client['clientName']}]: $status | Reason: ${playability?['reason']}',
                );
                continue;
              }

              final streamingData = data['streamingData'];
              if (streamingData != null) {
                final List<dynamic> formats =
                    (streamingData['adaptiveFormats'] as List<dynamic>? ?? []) +
                    (streamingData['formats'] as List<dynamic>? ?? []);

                final audioStreams = formats.where((f) {
                  final mimeType = f['mimeType'] as String?;
                  return mimeType != null && mimeType.contains('audio/');
                }).toList();

                if (audioStreams.isNotEmpty) {
                  // Prioritize direct URL formats
                  audioStreams.sort((a, b) {
                    final hasUrlA = a['url'] != null ? 1 : 0;
                    final hasUrlB = b['url'] != null ? 1 : 0;
                    if (hasUrlA != hasUrlB) return hasUrlB.compareTo(hasUrlA);

                    final bitrateA = a['averageBitrate'] ?? a['bitrate'] ?? 0;
                    final bitrateB = b['averageBitrate'] ?? b['bitrate'] ?? 0;
                    return (bitrateB as int).compareTo(bitrateA as int);
                  });

                  final bestStream = audioStreams.firstWhere(
                    (f) => f['url'] != null,
                    orElse: () => null,
                  );

                  if (bestStream != null) {
                    final url = bestStream['url'] as String;
                    AppLogger.i(
                      _tag,
                      'Resolved via InnerTube: ${client['clientName']}',
                    );
                    return url;
                  }
                }
              }
            }
          } catch (e) {
            AppLogger.w(
              _tag,
              'InnerTube attempt failed [${client['clientName']}]: $e',
            );
          }
        }
      }

      AppLogger.w(
        _tag,
        'All InnerTube clients failed, falling back to YoutubeExplode',
      );
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
