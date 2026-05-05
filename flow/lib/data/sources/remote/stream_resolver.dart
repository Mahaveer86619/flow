import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import '../../../core/storage/local_storage.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/logger/app_logger.dart';

class StreamResolver {
  static final StreamResolver _instance = StreamResolver._internal();
  static StreamResolver get instance => _instance;

  final Dio _playerDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      validateStatus: (status) => true,
    ),
  );

  StreamResolver._internal();

  static const _tag = 'StreamResolver';

  Future<String?> resolveYoutubeStream(String videoId, {String? title, String? artist, bool forceStandardYouTube = false}) async {
    try {
      AppLogger.i(_tag, 'Resolving stream for videoId: $videoId${title != null ? " ($title)" : ""}');

      // 1. YouTube Audio Strategy: Proactively find a standard YT replacement for music IDs
      if (forceStandardYouTube && title != null && artist != null) {
        AppLogger.i(_tag, 'Priority: Searching for standard YouTube replacement...');
        final replacementId = await _searchStandardReplacement(title, artist);
        if (replacementId != null && replacementId != videoId) {
          AppLogger.i(_tag, 'Found replacement: $replacementId. Resolving standard stream...');
          return resolveYoutubeStream(replacementId, title: title, artist: artist, forceStandardYouTube: false);
        }
      }

      final cookies = await SecureStorageService.instance.getYoutubeCookies();
      
      // 2. Try InnerTube probes first (faster, direct URLs)
      final innerTubeUrl = await _resolveWithInnerTube(videoId, cookies);
      if (innerTubeUrl != null) return innerTubeUrl;

      // 3. Try YoutubeExplode (handles signature decoding & rolling challenges)
      AppLogger.i(_tag, 'InnerTube failed, using YoutubeExplode...');
      final ytExplodeUrl = await _resolveWithYoutubeExplode(videoId, cookies);
      if (ytExplodeUrl != null) return ytExplodeUrl;

      // 4. Final Fallback: If everything else failed, try replacement search one last time
      if (!forceStandardYouTube && title != null && artist != null) {
        AppLogger.i(_tag, 'Direct resolution failed, searching for replacement fallback...');
        final replacementId = await _searchStandardReplacement(title, artist);
        if (replacementId != null && replacementId != videoId) {
          return resolveYoutubeStream(replacementId);
        }
      }

      AppLogger.w(_tag, 'All resolution methods failed for $videoId');
      return null;
    } catch (e, st) {
      AppLogger.e(_tag, 'Stream resolution critical failure', e, st);
      return null;
    }
  }

  Future<String?> _resolveWithInnerTube(String videoId, String? cookies) async {
    // Dynamically fetch or use fresh visitorData to bypass bot detection
    String? visitorData = LocalStorage.instance.getCachedMetadata('yt_visitor_data') as String?;
    if (visitorData == null) {
      visitorData = await _fetchVisitorData();
      if (visitorData != null) LocalStorage.instance.saveCachedMetadata('yt_visitor_data', visitorData);
    }
    visitorData ??= "CgtVRE9Vem9fS3lsayink_m1Bg%3D%3D";
    
    final probes = [
      {
        "name": "ANDROID_VR",
        "client": {
          "clientName": "ANDROID_VR",
          "clientVersion": "1.50.41",
          "osName": "Android",
          "osVersion": "12",
        },
        "userAgent": "com.google.android.apps.videoplayer/1.50.41 (Linux; U; Android 12; en_US) gzip",
        "base": "https://www.youtube.com/youtubei/v1/player",
        "useCookies": false,
        "clientName": "28",
        "clientVersion": "1.50.41",
      },
      {
        "name": "MWEB",
        "client": {
          "clientName": "MWEB",
          "clientVersion": "2.20240409.01.01",
        },
        "userAgent": "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.6261.119 Mobile Safari/537.36",
        "base": "https://www.youtube.com/youtubei/v1/player",
        "useCookies": true,
        "clientName": "MWEB",
        "clientVersion": "2.20240409.01.01",
      },
      {
        "name": "TVHTML5",
        "client": {
          "clientName": "TVHTML5",
          "clientVersion": "7.20240409.01.00",
          "platform": "TV",
        },
        "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
        "base": "https://www.youtube.com/youtubei/v1/player",
        "useCookies": false,
        "clientName": "16",
        "clientVersion": "7.20240409.01.00",
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
          'Origin': 'https://www.youtube.com',
          'Referer': 'https://www.youtube.com/',
          'X-YouTube-Client-Name': probe['clientName'] as String,
          'X-YouTube-Client-Version': probe['clientVersion'] as String,
        };

        if (useCookies && cookies != null) {
          final sapisid = _extractCookie(cookies, 'SAPISID') ?? _extractCookie(cookies, '__Secure-3PAPISID');
          if (sapisid != null) {
            final auth = _generateSapisidHash(sapisid, 'https://www.youtube.com');
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
                "visitorData": visitorData,
              },
              "playbackContext": {
                "contentPlaybackContext": {
                  "signatureTimestamp": 21500,
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
            final formats = (data['streamingData']['adaptiveFormats'] as List? ?? []) +
                          (data['streamingData']['formats'] as List? ?? []);

            final audioFormats = formats.where((f) => 
              (f['mimeType'] as String).contains('audio/') && f['url'] != null
            ).toList();

            if (audioFormats.isNotEmpty) {
              audioFormats.sort((a, b) => (b['bitrate'] as int? ?? 0).compareTo(a['bitrate'] as int? ?? 0));
              final url = audioFormats.first['url'] as String;
              AppLogger.i(_tag, 'Resolved via InnerTube ($probeName): ${url.substring(0, 50)}...');
              return url;
            }
          }
          AppLogger.d(_tag, 'Probe $probeName status: $status');
        }
      } catch (e) {
        AppLogger.d(_tag, 'Probe $probeName error: $e');
      }
    }
    return null;
  }

  Future<String?> _resolveWithYoutubeExplode(String videoId, String? cookies) async {
    try {
      final wrappedClient = _AuthorizedHttpClient(
        cookies: cookies,
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      );

      final yt = YoutubeExplode(httpClient: YoutubeHttpClient(wrappedClient));
      await yt.videos.get(videoId);
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      final url = streamInfo.url.toString();
      yt.close();
      AppLogger.i(_tag, 'Resolved via YoutubeExplode: ${url.substring(0, 50)}...');
      return url;
    } catch (e) {
      AppLogger.w(_tag, 'YoutubeExplode resolution failed: $e');
      return null;
    }
  }

  Future<String?> _searchStandardReplacement(String title, String artist) async {
    try {
      final query = '$title $artist';
      final response = await _playerDio.post(
        'https://www.youtube.com/youtubei/v1/search?prettyPrint=false',
        data: {
          "query": query,
          "context": {
            "client": {
              "clientName": "WEB",
              "clientVersion": "2.20240409.01.01",
              "hl": "en",
              "gl": "US",
              "platform": "DESKTOP",
            },
          },
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final contents = data['contents']?['twoColumnSearchResultsRenderer']?['primaryContents']?['sectionListRenderer']?['contents'];
        if (contents == null) return null;

        for (final section in contents) {
          final itemSection = section['itemSectionRenderer'];
          if (itemSection == null) continue;
          for (final item in itemSection['contents'] ?? []) {
            final video = item['videoRenderer'];
            if (video == null) continue;
            final vidId = video['videoId'] as String?;
            if (vidId != null) return vidId;
          }
        }
      }
    } catch (e) { AppLogger.w(_tag, 'Replacement search failed: $e'); }
    return null;
  }

  Future<String?> _fetchVisitorData() async {
    try {
      final response = await _playerDio.post(
        'https://www.youtube.com/youtubei/v1/browse?prettyPrint=false',
        data: {
          "browseId": "FEmusic_home",
          "context": {
            "client": {
              "clientName": "WEB_REMIX",
              "clientVersion": "1.20240409.01.01",
              "hl": "en",
              "gl": "US",
              "platform": "DESKTOP",
            }
          }
        }
      );
      return response.data?['responseContext']?['visitorData'] as String?;
    } catch (_) { return null; }
  }

  Future<String?> _resolveWithYtDlp(String videoId) async {
    try {
      final result = await Process.run('yt-dlp', [
        '-g', '-f', 'ba', 'https://www.youtube.com/watch?v=$videoId'
      ]);
      if (result.exitCode == 0) {
        final url = result.stdout.toString().trim();
        if (url.isNotEmpty && url.startsWith('http')) return url;
      }
    } catch (_) {}
    return null;
  }

  String? _extractCookie(String cookies, String name) {
    try {
      final cookieList = cookies.split(';');
      for (final cookie in cookieList) {
        final parts = cookie.trim().split('=');
        if (parts.length >= 2 && parts[0] == name) return parts.sublist(1).join('=');
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
}

class _AuthorizedHttpClient extends http.BaseClient {
  final String? cookies;
  final String userAgent;
  final http.Client _inner = http.Client();
  _AuthorizedHttpClient({this.cookies, required this.userAgent});
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (cookies != null) request.headers['Cookie'] = cookies!;
    request.headers['User-Agent'] = userAgent;
    request.headers['user-agent'] = userAgent;
    return _inner.send(request);
  }
  @override
  void close() { _inner.close(); super.close(); }
}
