import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/network/dio_client.dart';
import '../../models/home_data_model.dart';
import '../../models/playlist_model.dart';
import '../../models/song_model.dart';
import 'music_data_source.dart';

class YoutubeMusicDataSource implements MusicDataSource {
  final Dio _dio = DioClient.instance.dio;
  static const _tag = 'YoutubeMusicDataSource';

  static const _baseUrl = 'https://music.youtube.com/youtubei/v1';

  // ── InnerTube client context ────────────────────────────────────────────────
  // FIX: ANDROID_TESTSUITE returns 404. WEB_REMIX is the official YTM web
  // client and is the most stable choice for authenticated home-feed requests.
  // The API key is required for WEB_REMIX calls on the music subdomain.
  static const _apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';

  final Map<String, dynamic> _context = {
    "client": {
      "clientName": "WEB_REMIX",
      "clientVersion": "1.20250101.01.00",
      "hl": "en",
      "gl": "IN",
      "utcOffsetMinutes": 330,
    },
    "user": {"lockedSafetyMode": false},
  };

  // ── Public API ──────────────────────────────────────────────────────────────

  @override
  Future<HomeDataModel> fetchHomeData({
    int limit = 25,
    String? continuationToken,
  }) async {
    try {
      AppLogger.i(_tag, 'fetchHomeData starting (continuation: ${continuationToken != null})');

      // visitorData is intentionally omitted: a stale guest visitorData token
      // causes an identity collision that causes the backend to ignore auth cookies.
      final Map<String, dynamic> requestBody = continuationToken != null
          ? {
              "context": _context,
              "continuation": continuationToken,
            }
          : {
              "browseId": "FEmusic_home",
              "context": _context,
            };

      final response = await _dio.post(
        '$_baseUrl/browse?prettyPrint=false&key=$_apiKey',
        data: requestBody,
        options: Options(
          headers: {
            // Required for WEB_REMIX authenticated requests
            'X-Youtube-Client-Name': '67',
            'X-Youtube-Client-Version': '1.20250101.01.00',
            'Origin': 'https://music.youtube.com',
            'Referer': 'https://music.youtube.com/',
          },
        ),
      );

      if (response.statusCode != 200) {
        AppLogger.w(_tag, 'fetchHomeData returned ${response.statusCode}');
        throw SourceException(
          message: 'Failed to fetch home data from YouTube Music.',
          statusCode: response.statusCode,
        );
      }

      final data = response.data as Map<String, dynamic>;

      final (shelves, nextToken) = _parseShelves(data);
      AppLogger.i(_tag, 'fetchHomeData succeeded: ${shelves.length} shelves, hasNextPage: ${nextToken != null}');
      return HomeDataModel(rawShelves: shelves, continuationToken: nextToken);
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchHomeData failed', e, st);
      return const HomeDataModel(rawShelves: []);
    }
  }

  @override
  Future<List<SongModel>> searchSongs(String query, {int limit = 25}) async {
    try {
      AppLogger.i(_tag, 'searchSongs("$query")');
      final response = await _dio.post(
        '$_baseUrl/search?prettyPrint=false&key=$_apiKey',
        data: {
          "query": query,
          "params": "EgWKAQIIAWoQEAMQBBAJEAoQCxAEEAoQAA==",
          "context": _context,
        },
        options: Options(
          headers: {
            'X-Youtube-Client-Name': '67',
            'X-Youtube-Client-Version': '1.20250101.01.00',
            'Origin': 'https://music.youtube.com',
            'Referer': 'https://music.youtube.com/',
          },
        ),
      );
      if (response.statusCode != 200) return [];

      final data = response.data as Map<String, dynamic>;
      final tracks = _extractSongsFromSearch(data);

      if (tracks.isEmpty) {
        return _searchGeneral(query, limit: limit);
      }
      return tracks.take(limit).toList();
    } catch (e) {
      AppLogger.e(_tag, 'searchSongs failed', e);
      return [];
    }
  }

  // ── Shelf Parsing ───────────────────────────────────────────────────────────

  (List<Map<String, dynamic>>, String?) _parseShelves(Map<String, dynamic> data) {
    final contents =
        data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];

    if (contents == null) {
      AppLogger.w(_tag, 'parseShelves: contents is null');
      return ([], null);
    }

    final shelves = <Map<String, dynamic>>[];
    String? continuationToken;

    for (final sectionObj in contents as List) {
      final section = sectionObj as Map<String, dynamic>;
      if (section.containsKey('musicTastebuilderShelfRenderer')) {
        AppLogger.d(_tag, 'Skipping musicTastebuilderShelfRenderer');
        continue;
      }

      if (section.containsKey('continuationItemRenderer')) {
        continuationToken = section['continuationItemRenderer']
            ?['continuationEndpoint']
            ?['continuationCommand']
            ?['token'] as String?;
        AppLogger.d(_tag, 'Found continuation token: ${continuationToken != null}');
        continue;
      }

      final shelf =
          section['musicCarouselShelfRenderer'] as Map<String, dynamic>? ??
          section['musicShelfRenderer'] as Map<String, dynamic>? ??
          section['gridRenderer'] as Map<String, dynamic>? ??
          section['musicDescriptionShelfRenderer'] as Map<String, dynamic>?;
      if (shelf == null) continue;

      final title = _shelfTitle(shelf);
      final itemSize = shelf['itemSize'] as String? ?? '';
      final items = <Map<String, dynamic>>[];

      final shelfContents = shelf['contents'] as List? ?? [];
      for (final item in shelfContents) {
        final mapped = _parseItem(item as Map<String, dynamic>);
        if (mapped != null) items.add(mapped);
      }

      if (items.isEmpty) {
        AppLogger.d(_tag, 'Shelf "$title" skipped: items is empty');
        continue;
      }

      final titleLower = title.toLowerCase();
      String? sectionType;

      // Eager classification for UI consistency if Intelligence is inactive
      final intelligenceActive =
          dotenv.env['INTELLIGENCE_ACTIVE']?.toLowerCase() == 'true';

      if (intelligenceActive) {
        if (titleLower.contains('quick picks')) {
          sectionType = 'quickPicks';
        } else if (titleLower.contains('listen again')) {
          sectionType = 'listeningAgain';
        } else if (titleLower.contains('video')) {
          sectionType = 'musicVideos';
        } else if (titleLower.contains('podcast')) {
          sectionType = 'podcasts';
        } else if (titleLower.contains('album')) {
          sectionType = 'albums';
        } else if (titleLower.contains('long listen')) {
          sectionType = 'longListening';
        } else if (titleLower.contains('flow')) {
          sectionType = 'flowIntelligence';
        }
      }

      AppLogger.i(
        _tag,
        'Parsed shelf: "$title" (Intelligence: $intelligenceActive, Section: $sectionType) with ${items.length} items',
      );

      shelves.add({
        'title': title,
        'section': sectionType,
        'itemSize': itemSize,
        'items': items,
      });
    }

    AppLogger.i(_tag, 'Total shelves parsed in DataSource: ${shelves.length}');
    return (shelves, continuationToken);
  }

  // ── Header title extraction ─────────────────────────────────────────────────

  String _shelfTitle(Map<String, dynamic> shelf) {
    final basic = shelf['header']?['musicCarouselShelfBasicHeaderRenderer'];
    if (basic != null) {
      final fromRuns = basic['title']?['runs']?[0]?['text'] as String?;
      if (fromRuns != null && fromRuns.isNotEmpty) return fromRuns;
    }

    final legacyRuns = shelf['title']?['runs']?[0]?['text'] as String?;
    if (legacyRuns != null && legacyRuns.isNotEmpty) return legacyRuns;

    return 'More';
  }

  // ── Per-item parsing ────────────────────────────────────────────────────────

  Map<String, dynamic>? _parseItem(Map<String, dynamic> item) {
    try {
      final renderer =
          item['musicTwoRowItemRenderer'] ??
          item['musicResponsiveListItemRenderer'] ??
          item['musicItemRenderer'];
      if (renderer == null) return null;

      final title = _titleText(renderer);
      if (title == null || title.isEmpty) return null;

      final nav = renderer['navigationEndpoint'] as Map<String, dynamic>? ?? {};
      final watchEp = nav['watchEndpoint'] as Map<String, dynamic>?;
      final browseEp = nav['browseEndpoint'] as Map<String, dynamic>?;

      final videoId = watchEp?['videoId'] as String?;
      final browseId = browseEp?['browseId'] as String?;
      final fallbackVideoId =
          renderer['playlistItemData']?['videoId'] as String?;
      final effectiveVideoId = videoId ?? fallbackVideoId;

      final thumb = _extractThumbnail(renderer, effectiveVideoId);
      final subtitle = _subtitleText(renderer);

      final aspectRatio = renderer['aspectRatio'] as String? ?? '';
      final isWidescreen =
          aspectRatio.contains('16_9') || aspectRatio.contains('RECTANGLE');

      final musicVideoType =
          watchEp?['watchEndpointMusicSupportedConfigs']?['watchEndpointMusicConfig']?['musicVideoType']
              as String?;

      final pageType =
          browseEp?['browseEndpointContextSupportedConfigs']?['browseEndpointContextMusicConfig']?['pageType']
              as String?;

      if (effectiveVideoId != null) {
        final isMusicVideo =
            isWidescreen ||
            (musicVideoType != null &&
                musicVideoType != 'MUSIC_VIDEO_TYPE_ATV');
        final type = isMusicVideo ? 'video' : 'song';

        return {
          'type': type,
          'data': {
            'id': effectiveVideoId,
            'title': title.trim(),
            'artist': subtitle ?? 'Unknown',
            'album': '',
            'durationMs': 0,
            'thumbnailUrl': thumb,
            'isWidescreen': isMusicVideo,
            'musicVideoType': musicVideoType,
          },
        };
      } else if (browseId != null) {
        return _classifyBrowsable(
          browseId: browseId,
          pageType: pageType,
          title: title.trim(),
          subtitle: subtitle,
          thumb: thumb,
        );
      }
    } catch (e) {
      AppLogger.w(_tag, 'parseItem failed: $e');
    }
    return null;
  }

  // ── Thumbnail extraction ────────────────────────────────────────────────────

  String? _extractThumbnail(Map<String, dynamic> renderer, String? videoId) {
    final thumbnails =
        (renderer['thumbnailRenderer']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']
                as List?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList();

    if (thumbnails != null && thumbnails.isNotEmpty) {
      var best = thumbnails.last;
      for (final t in thumbnails) {
        if ((t['width'] as int? ?? 0) > (best['width'] as int? ?? 0)) {
          best = t;
        }
      }
      var url = best['url'] as String?;
      if (url != null) {
        if (url.contains('googleusercontent.com') &&
            url.contains('=w') &&
            url.contains('-h')) {
          url = url.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w512-h512-l90-rj');
        }
        return url;
      }
    }

    if (videoId != null) {
      return 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
    }
    return null;
  }

  // ── Title extraction ────────────────────────────────────────────────────────

  String? _titleText(Map<String, dynamic> renderer) {
    final fromTitle = renderer['title']?['runs']?[0]?['text'] as String?;
    if (fromTitle != null) return fromTitle;

    final flexCols = renderer['flexColumns'] as List?;
    if (flexCols != null && flexCols.isNotEmpty) {
      return flexCols[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text']
          as String?;
    }
    return null;
  }

  // ── Subtitle / artist extraction ────────────────────────────────────────────

  String? _subtitleText(Map<String, dynamic> renderer) {
    final subtitleRuns =
        renderer['subtitle']?['runs'] as List? ??
        renderer['longBylineText']?['runs'] as List? ??
        renderer['shortBylineText']?['runs'] as List?;

    if (subtitleRuns != null) {
      final parts = <String>[];
      for (final run in subtitleRuns) {
        final text = (run['text'] as String? ?? '').trim();
        if (text.isNotEmpty && text != '•' && text != '\u2022') {
          parts.add(text);
        }
      }
      if (parts.isNotEmpty) return parts.first;
    }

    final flexCols = renderer['flexColumns'] as List?;
    if (flexCols != null && flexCols.length > 1) {
      final runs =
          flexCols[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']
              as List?;
      if (runs != null) {
        for (final run in runs) {
          final text = (run['text'] as String? ?? '').trim();
          if (text.isNotEmpty && text != '•' && text != '\u2022') return text;
        }
      }
    }
    return null;
  }

  // ── Browsable classification ────────────────────────────────────────────────

  Map<String, dynamic> _classifyBrowsable({
    required String browseId,
    required String? pageType,
    required String title,
    required String? subtitle,
    required String? thumb,
  }) {
    if (browseId.startsWith('UC') || browseId.startsWith('FBA')) {
      return {
        'type': 'artist',
        'data': {'name': title, 'thumbnailUrl': thumb},
      };
    }

    final isAlbum =
        browseId.startsWith('MPRE') ||
        browseId.startsWith('FEmusic_album') ||
        pageType == 'MUSIC_PAGE_TYPE_ALBUM' ||
        pageType == 'MUSIC_PAGE_TYPE_SINGLE' ||
        pageType == 'MUSIC_PAGE_TYPE_EP';

    if (isAlbum) {
      return {
        'type': 'album',
        'data': {
          'id': browseId,
          'name': title,
          'description': subtitle ?? '',
          'thumbnailUrl': thumb,
          'isAlbum': true,
          'artistName': subtitle,
        },
      };
    }

    final playlistId = browseId.startsWith('VL')
        ? browseId.substring(2)
        : browseId;

    return {
      'type': 'playlist',
      'data': {
        'id': playlistId,
        'browseId': browseId,
        'name': title,
        'description': subtitle ?? '',
        'thumbnailUrl': thumb,
        'isAlbum': false,
      },
    };
  }

  // ── Search helpers ──────────────────────────────────────────────────────────

  List<SongModel> _extractSongsFromSearch(Map<String, dynamic> data) {
    final tracks = <SongModel>[];
    final contents =
        data['contents']?['tabbedSearchResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents']
            as List?;
    if (contents == null) return tracks;

    for (final section in contents) {
      final shelf = section['musicShelfRenderer'];
      if (shelf == null) continue;
      for (final item in shelf['contents'] as List? ?? []) {
        final mapped = _parseItem(item);
        if (mapped != null &&
            (mapped['type'] == 'song' || mapped['type'] == 'video')) {
          tracks.add(
            SongModel.fromJson(mapped['data'] as Map<String, dynamic>),
          );
        }
      }
    }
    return tracks;
  }

  Future<List<SongModel>> _searchGeneral(String query, {int limit = 25}) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/search?prettyPrint=false&key=$_apiKey',
        data: {"query": query, "context": _context},
        options: Options(
          headers: {
            'X-Youtube-Client-Name': '67',
            'X-Youtube-Client-Version': '1.20250101.01.00',
            'Origin': 'https://music.youtube.com',
            'Referer': 'https://music.youtube.com/',
          },
        ),
      );
      if (response.statusCode != 200) return [];
      return _extractSongsFromSearch(
        response.data as Map<String, dynamic>,
      ).take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Unimplemented stubs ─────────────────────────────────────────────────────

  @override
  Future<List<SongModel>> fetchPlaylistTracks(
    String playlistId, {
    int limit = 100,
  }) async => [];
  @override
  Future<List<SongModel>> fetchAlbumTracks(
    String browseId, {
    int limit = 25,
  }) async => [];
  @override
  Future<List<SongModel>> fetchArtistSongs(String channelId) async => [];
  @override
  Future<List<PlaylistModel>> fetchPlaylists() async => [];
  @override
  Future<Map<String, dynamic>> fetchArtistDetails(String browseId) async => {};
  @override
  Future<Map<String, dynamic>> fetchSongDetails(String videoId) async => {};
  @override
  List<Map<String, dynamic>> fetchCategories() => [];
  @override
  Future<List<SongModel>> fetchRecommendations({int limit = 20}) async => [];
  @override
  Future<List<SongModel>> fetchBlendedRecommendations(
    String friendId, {
    int limit = 20,
  }) async => [];
  @override
  Future<String> createPlaylist({
    required String title,
    String? description,
    String? privacyStatus,
    List<String>? videoIds,
    String? sourcePlaylist,
  }) async => '';
  @override
  Future<void> editPlaylist({
    required String playlistId,
    String? title,
    String? description,
    String? privacyStatus,
  }) async {}
  @override
  Future<void> deletePlaylist(String playlistId) async {}
  @override
  Future<void> addPlaylistItems({
    required String playlistId,
    required List<String> videoIds,
    String? sourcePlaylist,
    bool duplicates = false,
  }) async {}
  @override
  Future<void> removePlaylistItems({
    required String playlistId,
    required List<Map<String, dynamic>> videos,
  }) async {}
  @override
  Future<void> addCollaborator(String playlistId, String userCode) async {}
  @override
  Future<void> addTrackToFlowPlaylist(
    String playlistId,
    SongModel song,
  ) async {}
  @override
  Future<PlaylistModel> createFlowPlaylist({
    required String title,
    String description = '',
    bool isPublic = false,
  }) async => PlaylistModel(
    id: 'temp',
    name: title,
    description: description,
    color: const Color(0xFF7C3AED),
  );
  @override
  Future<void> deleteFlowPlaylist(String playlistId) async {}
  @override
  Future<Map<String, dynamic>> fetchPersistentHistory() async => {};
  @override
  Future<List<SongModel>> fetchRadioTracks(
    String videoId, {
    int limit = 25,
  }) async => [];
  @override
  Future<List<SongModel>> fetchSongsByIds(List<String> ids) async => [];
  @override
  Future<void> likeArtist(String channelId) async {}
  @override
  Future<void> prefetchAudio(String videoId) async {}
  @override
  Future<void> recordPlay(SongModel song) async {}
  @override
  Future<void> removeCollaborator(String playlistId, String userCode) async {}
  @override
  Future<void> removeTrackFromFlowPlaylist(
    String playlistId,
    int trackId,
  ) async {}
  @override
  Future<void> unlikeArtist(String channelId) async {}
  @override
  Future<PlaylistModel> updateFlowPlaylist(
    String playlistId, {
    String? title,
    String? description,
    bool? isPublic = false,
  }) async => PlaylistModel(
    id: playlistId,
    name: title ?? '',
    description: description ?? '',
    color: const Color(0xFF7C3AED),
  );
}
