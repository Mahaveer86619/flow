import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
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
      validateStatus: (status) => true,
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
      if (cookies != null) {
        AppLogger.d(_tag, 'Current Cookies: $cookies');
      }


      // Highly optimized InnerTube probes
      // Ordered by resilience/reliability
      final probes = [
        {
          "name": "ANDROID_VR",
          "client": {
            "clientName": "ANDROID_VR",
            "clientVersion": "1.50.41",
            "osName": "Android",
            "osVersion": "12",
            "platform": "MOBILE",
          },
          "userAgent":
              "com.google.android.apps.videoplayer/1.50.41 (Linux; U; Android 12; en_US) gzip",
          "base": "https://www.youtube.com/youtubei/v1/player",
          "useCookies": false, // VR usually works better without cookies
          "clientName": "28",
          "clientVersion": "1.50.41",
        },
        {
          "name": "IOS",
          "client": {
            "clientName": "IOS",
            "clientVersion": "19.29.1",
            "osName": "iOS",
            "osVersion": "17.5.1",
            "platform": "MOBILE",
          },
          "userAgent":
              "com.google.ios.youtube/19.29.1 (iPhone16,2; U; CPU iOS 17_5_1 like Mac OS X; en_US)",
          "base": "https://www.youtube.com/youtubei/v1/player",
          "useCookies": true,
          "clientName": "5",
          "clientVersion": "19.29.1",
        },
        {
          "name": "ANDROID_MUSIC",
          "client": {
            "clientName": "ANDROID_MUSIC",
            "clientVersion": "7.03.52",
            "androidSdkVersion": 34,
            "osName": "Android",
            "osVersion": "14",
            "platform": "MOBILE",
          },
          "userAgent":
              "com.google.android.apps.youtube.music/7.03.52 (Linux; U; Android 14; en_US) gzip",
          "base": "https://music.youtube.com/youtubei/v1/player",
          "useCookies": true,
          "clientName": "67",
          "clientVersion": "7.03.52",
        },
        {
          "name": "ANDROID_TESTSUITE",
          "client": {
            "clientName": "ANDROID_TESTSUITE",
            "clientVersion": "1.9.3.1",
          },
          "userAgent":
              "com.google.android.youtube/1.9.3.1 (Linux; U; Android 9; en_US) gzip",
          "base": "https://www.youtube.com/youtubei/v1/player",
          "useCookies": true,
          "clientName": "30",
          "clientVersion": "1.9.3.1",
        },
        {
          "name": "WEB_REMIX",
          "client": {
            "clientName": "WEB_REMIX",
            "clientVersion": "1.20240409.01.01",
          },
          "userAgent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
          "base": "https://music.youtube.com/youtubei/v1/player",
          "useCookies": true,
          "clientName": "1",
          "clientVersion": "1.20240409.01.01",
        },
      ];

      for (var probe in probes) {
        final probeName = probe['name'] as String;
        final clientParams = probe['client'] as Map<String, dynamic>;
        final userAgent = probe['userAgent'] as String;
        final base = probe['base'] as String;
        final useCookies = probe['useCookies'] as bool;

        try {
          final Map<String, String> headers = {
            'User-Agent': userAgent,
            if (useCookies && cookies != null) 'Cookie': cookies,
            'Origin': 'https://music.youtube.com',
            'Referer': 'https://music.youtube.com/',
            'X-Goog-AuthUser': '0',
            'X-YouTube-Client-Name': probe['clientName'] as String,
            'X-YouTube-Client-Version': probe['clientVersion'] as String,
          };

          if (useCookies && cookies != null) {
            final sapisid = _extractCookie(cookies, 'SAPISID');
            if (sapisid != null) {
              final auth = _generateSapisidHash(
                sapisid,
                'https://music.youtube.com',
              );
              headers['Authorization'] = 'SAPISIDHASH $auth';
            }
          }

          final response = await _playerDio.post(
            '$base?prettyPrint=false',
            options: Options(headers: headers),
            data: {
              "videoId": videoId,
              "context": {
                "client": {
                  ...clientParams,
                  "hl": "en",
                  "gl": "US",
                  // Only use visitorData if NOT using cookies to avoid context mismatch
                  if (!useCookies && visitorData != null)
                    "visitorData": visitorData,
                },
                "playbackContext": {
                  "contentPlaybackContext": {
                    "signatureTimestamp": 19800, // Fallback timestamp
                  },
                },
              },
            },
          );

          if (response.statusCode == 200) {
            final data = response.data as Map<String, dynamic>;
            final playability = data['playabilityStatus'];
            final status = playability?['status'] as String?;

            if (status == 'OK' && data['streamingData'] != null) {
              final List<dynamic> formats =
                  (data['streamingData']['adaptiveFormats'] as List? ?? []) +
                  (data['streamingData']['formats'] as List? ?? []);

              // Filter for audio formats with URLs
              final audioFormats = formats.where(
                (f) =>
                    (f['mimeType'] as String).contains('audio/') &&
                    f['url'] != null,
              ).toList();

              if (audioFormats.isNotEmpty) {
                // Sort by bitrate to get best quality
                audioFormats.sort((a, b) {
                  final b1 = a['bitrate'] as int? ?? 0;
                  final b2 = b['bitrate'] as int? ?? 0;
                  return b2.compareTo(b1);
                });

                final bestStream = audioFormats.first;
                AppLogger.i(
                  _tag,
                  'Resolved via InnerTube ($probeName): ${bestStream['url'].toString().substring(0, 50)}...',
                );
                return bestStream['url'] as String;
              } else {
                AppLogger.d(
                  _tag,
                  'Probe $probeName: OK but no direct URL (likely ciphered)',
                );
              }
            } else {
              AppLogger.d(
                _tag,
                'Probe $probeName playability: $status. Reason: ${playability?['reason']}',
              );
            }
          } else {
            AppLogger.d(
              _tag,
              'Probe $probeName failed with status: ${response.statusCode}',
            );
          }
        } catch (e) {
          AppLogger.d(_tag, 'Probe $probeName error: $e');
        }
      }

      // Try yt-dlp on desktop as a high-fidelity fallback
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        AppLogger.i(_tag, 'InnerTube failed, trying yt-dlp fallback');
        final ytdlpUrl = await _resolveWithYtDlp(videoId);
        if (ytdlpUrl != null) return ytdlpUrl;
      }

      AppLogger.w(
        _tag,
        'InnerTube resolution failed, using YoutubeExplode fallback',
      );
      return _resolveFallback(videoId);
    } catch (e, st) {
      AppLogger.e(_tag, 'Stream resolution critical failure', e, st);
      return null;
    }
  }

  Future<String?> _resolveWithYtDlp(String videoId) async {
    try {
      final result = await Process.run('yt-dlp', [
        '-g',
        '-f', 'ba',
        'https://www.youtube.com/watch?v=$videoId'
      ]);
      if (result.exitCode == 0) {
        final url = result.stdout.toString().trim();
        if (url.isNotEmpty && url.startsWith('http')) {
          AppLogger.i(_tag, 'Resolved via yt-dlp');
          return url;
        }
      }
    } catch (e) {
      AppLogger.d(_tag, 'yt-dlp not available or failed: $e');
    }
    return null;
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

  String? _extractCookie(String cookies, String name) {
    try {
      final cookieList = cookies.split(';');
      for (final cookie in cookieList) {
        final parts = cookie.trim().split('=');
        if (parts.length >= 2 && parts[0] == name) {
          return parts.sublist(1).join('=');
        }
      }
    } catch (_) {}
    return null;
  }

  String _generateSapisidHash(String sapisid, String origin) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payload = '$timestamp $sapisid $origin';
    final hash = sha1.convert(utf8.encode(payload)).toString();
    return '${timestamp}_$hash';
  }

  void dispose() {
    _yt.close();
  }
}

