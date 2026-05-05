import 'dart:ui';
import 'package:dio/dio.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/network/dio_client.dart';
import '../../models/home_data_model.dart';
import '../../models/playlist_model.dart';
import '../../models/song_model.dart';
import 'music_data_source.dart';

class YoutubeMusicDataSource implements MusicDataSource {
  final Dio _dio = DioClient.instance.dio;
  static const _tag = 'YoutubeMusicDataSource';

  static const _baseUrl = 'https://www.youtube.com/youtubei/v1';

  final Map<String, dynamic> _context = {
    "client": {
      "clientName": "ANDROID_TESTSUITE",
      "clientVersion": "1.9.31.1",
      "hl": "en",
      "gl": "US",
      "utcOffsetMinutes": 0,
    },
    "user": {"lockedSafetyMode": false},
  };

  // ── Public API ──────────────────────────────────────────────────────────────

  @override
  Future<HomeDataModel> fetchHomeData({int limit = 25}) async {
    try {
      AppLogger.i(_tag, 'fetchHomeData starting');
      final visitorData =
          LocalStorage.instance.getCachedMetadata('yt_visitor_data') as String?;

      final response = await _dio.post(
        '$_baseUrl/browse?prettyPrint=false',
        data: {
          "browseId": "FEmusic_home",
          "context": {
            ..._context,
            if (visitorData != null) "visitorData": visitorData,
          },
        },
      );

      if (response.statusCode != 200) {
        AppLogger.w(_tag, 'fetchHomeData returned ${response.statusCode}');
        if (response.statusCode == 400) {
          LocalStorage.instance.saveCachedMetadata('yt_visitor_data', null);
          throw const SourceException(
            message:
                'YouTube Music returned a 400 error. Your connection may be invalid.',
            statusCode: 400,
          );
        }
        throw SourceException(
          message: 'Failed to fetch home data from YouTube Music.',
          statusCode: response.statusCode,
        );
      }

      final data = response.data as Map<String, dynamic>;

      // Persist new visitor data for continuity
      final newVisitorData = data['responseContext']?['visitorData'] as String?;
      if (newVisitorData != null) {
        LocalStorage.instance.saveCachedMetadata(
          'yt_visitor_data',
          newVisitorData,
        );
      }

      final shelves = _parseShelves(data);
      AppLogger.i(_tag, 'fetchHomeData succeeded: ${shelves.length} shelves');
      return HomeDataModel(rawShelves: shelves);
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
        '$_baseUrl/search?prettyPrint=false',
        data: {
          "query": query,
          // Songs filter param
          "params": "EgWKAQIIAWoQEAMQBBAJEAoQCxAEEAoQAA==",
          "context": _context,
        },
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

  /// Walks the InnerTube section list and converts each shelf into a raw map
  /// that [HomeDataModel] / [YtmMapper] can consume.
  List<Map<String, dynamic>> _parseShelves(Map<String, dynamic> data) {
    final contents =
        data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];

    if (contents == null) {
      AppLogger.w(_tag, 'parseShelves: contents is null');
      return [];
    }

    final shelves = <Map<String, dynamic>>[];

    for (final section in contents as List) {
      // ── Skip non-music shelves ──────────────────────────────────────────────
      if (section.containsKey('musicTastebuilderShelfRenderer')) {
        AppLogger.d(_tag, 'Skipping musicTastebuilderShelfRenderer');
        continue;
      }

      final shelf =
          section['musicCarouselShelfRenderer'] ??
          section['musicShelfRenderer'];
      if (shelf == null) continue;

      final title = _shelfTitle(shelf);
      final itemSize = shelf['itemSize'] as String? ?? '';
      final items = <Map<String, dynamic>>[];

      for (final item in shelf['contents'] as List? ?? []) {
        final mapped = _parseItem(item);
        if (mapped != null) items.add(mapped);
      }

      if (items.isEmpty) continue;

      shelves.add({
        'title': title,
        'section': null, // domain layer classifies this
        'itemSize': itemSize, // forwarded for layout hints
        'items': items,
      });
    }

    return shelves;
  }

  // ── Header title extraction ─────────────────────────────────────────────────

  /// Correct path: header → musicCarouselShelfBasicHeaderRenderer → title
  String _shelfTitle(Map<String, dynamic> shelf) {
    // Primary path (musicCarouselShelfRenderer)
    final basic = shelf['header']?['musicCarouselShelfBasicHeaderRenderer'];
    if (basic != null) {
      final fromRuns = basic['title']?['runs']?[0]?['text'] as String?;
      if (fromRuns != null && fromRuns.isNotEmpty) return fromRuns;
    }

    // Fallback: musicShelfRenderer uses a top-level title node
    final legacyRuns = shelf['title']?['runs']?[0]?['text'] as String?;
    if (legacyRuns != null && legacyRuns.isNotEmpty) return legacyRuns;

    return 'More';
  }

  // ── Per-item parsing ────────────────────────────────────────────────────────

  Map<String, dynamic>? _parseItem(Map<String, dynamic> item) {
    try {
      // Only musicTwoRowItemRenderer and musicResponsiveListItemRenderer appear
      // in home-feed shelves; musicItemRenderer is rare but guard it too.
      final renderer =
          item['musicTwoRowItemRenderer'] ??
          item['musicResponsiveListItemRenderer'] ??
          item['musicItemRenderer'];
      if (renderer == null) return null;

      // ── 1. Title ────────────────────────────────────────────────────────────
      final title = _titleText(renderer);
      if (title == null || title.isEmpty) return null;

      // ── 2. Navigation endpoints ─────────────────────────────────────────────
      final nav = renderer['navigationEndpoint'] as Map<String, dynamic>? ?? {};
      final watchEp = nav['watchEndpoint'] as Map<String, dynamic>?;
      final browseEp = nav['browseEndpoint'] as Map<String, dynamic>?;

      final videoId = watchEp?['videoId'] as String?;
      final browseId = browseEp?['browseId'] as String?;

      // Also check inner playlistItemData (some list renderers put it here)
      final fallbackVideoId =
          renderer['playlistItemData']?['videoId'] as String?;

      final effectiveVideoId = videoId ?? fallbackVideoId;

      // ── 3. Thumbnail ────────────────────────────────────────────────────────
      // Correct path: thumbnailRenderer → musicThumbnailRenderer → thumbnail → thumbnails
      // (NOT renderer['thumbnail']['musicThumbnailRenderer'] — that path doesn't exist)
      final thumb = _extractThumbnail(renderer, effectiveVideoId);

      // ── 4. Subtitle / artist ────────────────────────────────────────────────
      final subtitle = _subtitleText(renderer);

      // ── 5. Aspect ratio — discriminates songs vs music-videos ───────────────
      final aspectRatio = renderer['aspectRatio'] as String? ?? '';
      final isWidescreen =
          aspectRatio.contains('16_9') || aspectRatio.contains('RECTANGLE');

      // ── 6. Music video type (UGC, ATV, OMV, etc.) ──────────────────────────
      final musicVideoType =
          watchEp?['watchEndpointMusicSupportedConfigs']?['watchEndpointMusicConfig']?['musicVideoType']
              as String?;

      // ── 7. Browse page type for albums / playlists ──────────────────────────
      final pageType =
          browseEp?['browseEndpointContextSupportedConfigs']?['browseEndpointContextMusicConfig']?['pageType']
              as String?;

      // ── 8. Classify item ────────────────────────────────────────────────────
      if (effectiveVideoId != null) {
        // Has a videoId → playable media
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
        // No videoId → navigable entity (playlist / album / artist)
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

  // ── Thumbnail extraction (the fixed critical path) ──────────────────────────

  /// Correct thumbnail path:
  ///   renderer['thumbnailRenderer']['musicThumbnailRenderer']['thumbnail']['thumbnails']
  ///
  /// The old code tried `renderer['thumbnail']['musicThumbnailRenderer']` which
  /// is wrong — `thumbnail` (without "Renderer") is absent on home-feed items.
  String? _extractThumbnail(Map<String, dynamic> renderer, String? videoId) {
    final thumbnails =
        (renderer['thumbnailRenderer']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']
                as List?)
            ?.cast<Map<String, dynamic>>();

    if (thumbnails != null && thumbnails.isNotEmpty) {
      // Pick the largest available thumbnail
      var best = thumbnails.last;
      for (final t in thumbnails) {
        if ((t['width'] as int? ?? 0) > (best['width'] as int? ?? 0)) {
          best = t;
        }
      }
      var url = best['url'] as String?;
      if (url != null) {
        // Normalise Google image server URLs to a fixed 512×512 size
        if (url.contains('googleusercontent.com') &&
            url.contains('=w') &&
            url.contains('-h')) {
          url = url.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w512-h512-l90-rj');
        }
        return url;
      }
    }

    // Fallback: for video items the thumbnail can be inferred from the videoId
    if (videoId != null) {
      return 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
    }
    return null;
  }

  // ── Title extraction ────────────────────────────────────────────────────────

  String? _titleText(Map<String, dynamic> renderer) {
    // musicTwoRowItemRenderer: title.runs[0].text
    final fromTitle = renderer['title']?['runs']?[0]?['text'] as String?;
    if (fromTitle != null) return fromTitle;

    // musicResponsiveListItemRenderer: flexColumns[0].text.runs[0].text
    final flexCols = renderer['flexColumns'] as List?;
    if (flexCols != null && flexCols.isNotEmpty) {
      return flexCols[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text']
          as String?;
    }
    return null;
  }

  // ── Subtitle / artist extraction ────────────────────────────────────────────

  String? _subtitleText(Map<String, dynamic> renderer) {
    // musicTwoRowItemRenderer: subtitle.runs[*].text (skip bullet separators)
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

    // musicResponsiveListItemRenderer: flexColumns[1]
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

  // ── Browsable classification (playlist / album / artist) ───────────────────

  Map<String, dynamic> _classifyBrowsable({
    required String browseId,
    required String? pageType,
    required String title,
    required String? subtitle,
    required String? thumb,
  }) {
    // ── Artist ────────────────────────────────────────────────────────────────
    // UC* = YouTube channel, FBA* = YTM artist
    if (browseId.startsWith('UC') || browseId.startsWith('FBA')) {
      return {
        'type': 'artist',
        'data': {'name': title, 'thumbnailUrl': thumb},
      };
    }

    // ── Album ─────────────────────────────────────────────────────────────────
    // MPRE* = YTM album browseId
    // MUSIC_PAGE_TYPE_ALBUM / MUSIC_PAGE_TYPE_SINGLE signals from InnerTube
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

    // ── Playlist ──────────────────────────────────────────────────────────────
    // VL* = watch-list variant of a playlist browseId (strip "VL" to get the
    // raw playlistId used by /browse and /next endpoints)
    final playlistId = browseId.startsWith('VL')
        ? browseId.substring(2)
        : browseId;

    return {
      'type': 'playlist',
      'data': {
        'id': playlistId, // canonical playlistId without VL prefix
        'browseId': browseId, // original browseId for /browse calls
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
        '$_baseUrl/search?prettyPrint=false',
        data: {"query": query, "context": _context},
      );
      if (response.statusCode != 200) return [];
      return _extractSongsFromSearch(
        response.data as Map<String, dynamic>,
      ).take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Unimplemented stubs (unchanged from original) ──────────────────────────

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
    bool? isPublic,
  }) async => PlaylistModel(
    id: playlistId,
    name: title ?? '',
    description: description ?? '',
    color: const Color(0xFF7C3AED),
  );
}
