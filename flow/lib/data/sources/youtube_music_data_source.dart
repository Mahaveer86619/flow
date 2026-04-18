import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../../core/logger/app_logger.dart';
import '../models/home_data_model.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import 'music_data_source.dart';
import 'stream_resolver.dart';
import '../../core/network/dio_client.dart';

class YoutubeMusicDataSource implements MusicDataSource {
  final yt.YoutubeExplode _ytExplode = yt.YoutubeExplode();
  final Dio _dio = DioClient.instance.dio;
  final StreamResolver _resolver = StreamResolver.instance;

  static const _tag = 'YoutubeMusicDataSource';
  static const _ytmBase = 'https://music.youtube.com/youtubei/v1';

  @override
  Future<HomeDataModel> fetchHomeData({int limit = 25}) async {
    try {
      AppLogger.i(_tag, 'fetchHomeData standalone: Calling FEmusic_home');

      final response = await _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {
          "browseId": "FEmusic_home",
          "context": {
            "client": {
              "clientName": "WEB_REMIX",
              "clientVersion": "1.20240320.01.00",
            },
            "user": {
               "lockedSafetyMode": false
            }
          }
        },
      );

      if (response.statusCode != 200) {
        AppLogger.w(_tag, 'FEmusic_home failed (status: ${response.statusCode}), trying public fallback');
        return _fetchPublicHomeData();
      }

      final data = response.data as Map<String, dynamic>;

      final sections = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] as List<dynamic>?;
      if (sections != null) {
        AppLogger.i(_tag, '--- RAW HOME FEED START ---');
        for (var i = 0; i < sections.length; i++) {
          final section = sections[i];
          final shelf = section['musicCarouselShelfRenderer'] ?? section['musicShelfRenderer'] ?? section['musicTastebuilderShelfRenderer'];
          final header = shelf?['header']?['musicCarouselShelfBasicHeaderRenderer'] ?? shelf?['header']?['musicHeaderRenderer'];
          final title = header?['title']?['runs']?[0]?['text'] ?? header?['title']?['simpleText'] ?? 'Unknown Shelf';
          
          AppLogger.i(_tag, 'Section [$i]: "$title" | Keys: ${section.keys} | Shelf Keys: ${shelf?.keys}');
          if (shelf != null && shelf['contents'] != null) {
             final List items = shelf['contents'];
             if (items.isNotEmpty) {
                AppLogger.i(_tag, '  -> First Item Renderer: ${items.first.keys}');
             }
          }
        }
        AppLogger.i(_tag, '--- RAW HOME FEED END ---');
      }

      if (data['contents'] == null) {
        AppLogger.w(_tag, 'FEmusic_home returned empty contents, trying public fallback');
        return _fetchPublicHomeData();
      }

      final model = _parseHomeData(data);

      if (model.rawShelves.isEmpty) {
         AppLogger.w(_tag, 'FEmusic_home parsed to empty shelves, trying search fallback');
         return _fetchSearchFallbackHomeData();
      }

      AppLogger.i(_tag, 'fetchHomeData complete: ${model.rawShelves.length} shelves found');
      return model;
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchHomeData standalone failed, trying search fallback', e, st);
      return _fetchSearchFallbackHomeData();
    }
  }

  Future<HomeDataModel> _fetchPublicHomeData() async {
    try {
      AppLogger.i(_tag, 'Fetching public home data (FEmusic_new_releases)');
      final response = await _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {
          "browseId": "FEmusic_new_releases",
          "context": {
            "client": {
              "clientName": "WEB_REMIX",
              "clientVersion": "1.20240320.01.00",
            }
          }
        },
      );

      if (response.statusCode != 200) return _fetchSearchFallbackHomeData();

      final data = response.data as Map<String, dynamic>;
      final model = _parseHomeData(data);
      
      if (model.rawShelves.isEmpty) {
        return _fetchSearchFallbackHomeData();
      }
      
      return model;
    } catch (e) {
      AppLogger.e(_tag, 'Public home data fetch failed', e);
      return _fetchSearchFallbackHomeData();
    }
  }

  Future<HomeDataModel> _fetchSearchFallbackHomeData() async {
    try {
      AppLogger.i(_tag, 'Fetching search fallback home data (Trending)');
      final songs = await searchSongs('Trending Music', limit: 30);
      
      if (songs.isEmpty) return const HomeDataModel(rawShelves: [], trending: [], musicVideos: [], favArtistsSongs: []);

      final mappedItems = songs.map((s) => {
        'type': 'song',
        'data': {
          'id': s.id,
          'title': s.title,
          'artist': s.artist,
          'thumbnailUrl': s.thumbnailUrl,
          'durationMs': s.duration.inMilliseconds,
        }
      }).toList();

      return HomeDataModel(
        rawShelves: [
          {
            'title': 'Trending Discover',
            'section': 'trending',
            'items': mappedItems,
          }
        ],
        trending: [],
        musicVideos: [],
        favArtistsSongs: [],
      );
    } catch (e) {
      AppLogger.e(_tag, 'Search fallback failed', e);
      return const HomeDataModel(rawShelves: [], trending: [], musicVideos: [], favArtistsSongs: []);
    }
  }

  HomeDataModel _parseHomeData(Map<String, dynamic> data) {
    final shelves = <Map<String, dynamic>>[];

    try {
      final List<dynamic> contents = 
        data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] ?? 
        data['contents']?['sectionListRenderer']?['contents'] ?? [];

      AppLogger.d(_tag, 'Parsing ${contents.length} sections from home feed');

      for (final section in contents) {
        final shelf = section['musicShelfRenderer'] ??
                      section['musicCarouselShelfRenderer'] ??
                      section['musicTastebuilderShelfRenderer'] ??
                      section['musicEditablePlaylistDetailHeaderRenderer'] ??
                      section['itemSectionRenderer']?['contents']?[0]?['musicShelfRenderer'];

        if (shelf == null) continue;

        String? title = shelf['header']?['musicHeaderRenderer']?['title']?['runs']?[0]?['text'] ??
                        shelf['header']?['musicCarouselShelfBasicHeaderRenderer']?['title']?['runs']?[0]?['text'] ??
                        shelf['title']?['runs']?[0]?['text'] ??
                        shelf['title']?['simpleText'];

        String sectionType = 'standard';
        if (title != null) {
          final t = title.toLowerCase();
          if (t.contains('listen again') || t.contains('recent')) {
            sectionType = 'listeningAgain';
          } else if (t.contains('quick picks')) {
            sectionType = 'quickPicks';
          } else if (t.contains('mixed for you')) {
            sectionType = 'mixedForYou';
          } else if (t.contains('trending')) {
            sectionType = 'trending';
          }
        }

        final items = <Map<String, dynamic>>[];
        final List<dynamic> shelfItems = (shelf['contents'] as List<dynamic>?) ?? [];

        for (final item in shelfItems) {
          final actualItem = item['musicResponsiveListItemRenderer'] != null || 
                            item['musicTwoRowItemRenderer'] != null ||
                            item['musicTwoColumnItemRenderer'] != null ||
                            item['playlistPanelVideoRenderer'] != null ||
                            item['musicNavigationButtonRenderer'] != null
                            ? item : (item['navigationEndpoint'] != null ? item : null);
          
          if (actualItem == null) continue;
          
          final mappedItem = _parseMytmItem(actualItem);
          if (mappedItem != null) {
            items.add(mappedItem);
          }
        }

        if (items.isNotEmpty) {
          shelves.add({
            'title': title ?? 'Recommended',
            'section': sectionType,
            'items': items,
          });
          AppLogger.i(_tag, 'Parsed shelf: "$title" (${items.length} items)');
        }
      }
    } catch (e, st) {
      AppLogger.e(_tag, 'Error parsing home shelves', e, st);
    }

    return HomeDataModel(
      rawShelves: shelves,
      trending: [],
      musicVideos: [],
      favArtistsSongs: [],
    );
  }

  Map<String, dynamic>? _parseMytmItem(dynamic item) {
    try {
      final renderer = item['musicResponsiveListItemRenderer'] ??
                       item['musicTwoRowItemRenderer'] ??
                       item['playlistPanelVideoRenderer'] ??
                       item['musicNavigationButtonRenderer'] ??
                       item['musicTwoColumnItemRenderer'];

      if (renderer == null) return null;

      String? title;
      if (renderer['flexColumns'] != null) {
        title = renderer['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'];
      } else if (renderer['title'] != null) {
        title = renderer['title']?['runs']?[0]?['text'] ?? renderer['title']?['simpleText'];
      } else if (renderer['buttonText'] != null) {
        title = renderer['buttonText']?['runs']?[0]?['text'];
      }

      final browseId = renderer['navigationEndpoint']?['browseEndpoint']?['browseId'];
      final videoId = renderer['videoId'] ??
                      renderer['playlistItemData']?['videoId'] ??
                      renderer['navigationEndpoint']?['watchEndpoint']?['videoId'] ??
                      renderer['thumbnailOverlay']?['musicItemThumbnailOverlayRenderer']?['content']?['musicPlayButtonRenderer']?['playNavigationEndpoint']?['watchEndpoint']?['videoId'];

      final thumb = renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']?.last?['url'] ??
                    renderer['thumbnailRenderer']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']?.last?['url'] ??
                    renderer['thumbnail']?['thumbnails']?.last?['url'];
      
      // Clean up thumbnail URL for higher quality
      final highResThumb = thumb?.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w512-h512-l90-rj');

      if (videoId != null) {
        String artist = 'Unknown Artist';
        if (renderer['flexColumns'] != null && (renderer['flexColumns'] as List).length > 1) {
          final runs = renderer['flexColumns']?[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
          if (runs != null && runs.isNotEmpty) {
            artist = runs.map((r) => r['text']).join('');
          }
        } else if (renderer['longBylineText'] != null) {
          final runs = renderer['longBylineText']?['runs'] as List?;
          if (runs != null && runs.isNotEmpty) {
            artist = runs.map((r) => r['text']).join('');
          }
        } else if (renderer['shortBylineText'] != null) {
          final runs = renderer['shortBylineText']?['runs'] as List?;
          if (runs != null && runs.isNotEmpty) {
            artist = runs.map((r) => r['text']).join('');
          }
        } else if (renderer['subtitle'] != null) {
          final runs = renderer['subtitle']?['runs'] as List?;
          if (runs != null && runs.isNotEmpty) {
             artist = runs[0]['text'];
          }
        }

        return {
          'type': 'song',
          'data': {
            'id': videoId,
            'title': title ?? 'Unknown Title',
            'artist': artist,
            'thumbnailUrl': highResThumb ?? thumb,
            'durationMs': 0,
          }
        };
      } else if (browseId != null) {
        if (browseId.startsWith('UC') || browseId.startsWith('F')) {
          return {
            'type': 'artist',
            'data': {
              'name': title ?? 'Unknown Artist',
              'thumbnailUrl': highResThumb ?? thumb,
              'browseId': browseId,
            }
          };
        } else {
          return {
            'type': 'playlist',
            'data': {
              'id': browseId,
              'title': title ?? 'Unknown Title',
              'thumbnailUrl': highResThumb ?? thumb,
            }
          };
        }
      }
    } catch (e) {
      // Ignore parsing errors for individual items
    }
    return null;
  }

  @override
  Future<List<SongModel>> searchSongs(String query, {int limit = 25}) async {
    try {
      AppLogger.i(_tag, 'searchSongs standalone: $query');
      final response = await _dio.post(
        '$_ytmBase/search?prettyPrint=false',
        data: {
          "query": query,
          "params": "EgWKAQIIAWoQEAMQBBAJEAoQCxAEEAoQAA==",
          "context": {
            "client": { "clientName": "WEB_REMIX", "clientVersion": "1.20240320.01.00" }
          }
        },
      );

      if (response.statusCode != 200) return _fallbackSearch(query, limit);
      final data = response.data as Map<String, dynamic>;
      
      final List<dynamic> shelf = data['contents']?['tabbedSearchResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] ?? [];
      final List<dynamic> contents = shelf.isNotEmpty ? (shelf[0]['musicShelfRenderer']?['contents'] ?? []) : [];

      final tracks = <SongModel>[];
      for (final item in contents) {
        final mapped = _parseMytmItem(item);
        if (mapped != null && mapped['type'] == 'song') {
          final sData = mapped['data'] as Map<String, dynamic>;
          final colors = _colorsForId(sData['id']);
          tracks.add(SongModel(
            id: sData['id'], title: sData['title'], artist: sData['artist'], album: '',
            duration: Duration(milliseconds: sData['durationMs'] ?? 0), thumbnailUrl: sData['thumbnailUrl'],
            colorPrimary: colors.$1, colorSecondary: colors.$2,
          ));
        }
      }
      return tracks.isEmpty ? _fallbackSearch(query, limit) : tracks.take(limit).toList();
    } catch (e) {
      return _fallbackSearch(query, limit);
    }
  }

  Future<List<SongModel>> _fallbackSearch(String query, int limit) async {
    final results = await _ytExplode.search.search(query);
    return results.take(limit).map((v) {
      final colors = _colorsForId(v.id.value);
      return SongModel(
        id: v.id.value, title: v.title, artist: v.author, album: '',
        duration: v.duration ?? Duration.zero, thumbnailUrl: v.thumbnails.highResUrl,
        colorPrimary: colors.$1, colorSecondary: colors.$2,
      );
    }).toList();
  }

  @override
  Future<List<PlaylistModel>> fetchPlaylists() async => [];

  @override
  Future<List<SongModel>> fetchPlaylistTracks(String playlistId, {int limit = 100}) async {
    try {
      final playlist = await _ytExplode.playlists.get(playlistId);
      final videos = await _ytExplode.playlists.getVideos(playlistId).take(limit).toList();
      return videos.map((v) {
        final colors = _colorsForId(v.id.value);
        return SongModel(
          id: v.id.value, title: v.title, artist: v.author, album: playlist.title,
          duration: v.duration ?? Duration.zero, thumbnailUrl: v.thumbnails.highResUrl,
          colorPrimary: colors.$1, colorSecondary: colors.$2,
        );
      }).toList();
    } catch (e) { return []; }
  }

  @override
  Future<List<SongModel>> fetchArtistSongs(String channelId) async {
    try {
      AppLogger.i(_tag, 'fetchArtistSongs: $channelId');
      final response = await _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {
          "browseId": channelId,
          "context": {
            "client": { "clientName": "WEB_REMIX", "clientVersion": "1.20240320.01.00" }
          }
        },
      );

      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      
      // Navigate to the "Songs" shelf. This can be complex as it varies by artist.
      // We look for a musicShelfRenderer or a carousel with songs.
      final List<dynamic> sections = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] ?? [];
      
      final tracks = <SongModel>[];
      for (final section in sections) {
        final shelf = section['musicShelfRenderer'] ?? section['musicCarouselShelfRenderer'];
        if (shelf == null) continue;
        
        final contents = shelf['contents'] as List?;
        if (contents == null) continue;

        for (final item in contents) {
          final mapped = _parseMytmItem(item);
          if (mapped != null && mapped['type'] == 'song') {
            final sData = mapped['data'] as Map<String, dynamic>;
            final colors = _colorsForId(sData['id']);
            tracks.add(SongModel(
              id: sData['id'], title: sData['title'], artist: sData['artist'], album: '',
              duration: Duration(milliseconds: sData['durationMs'] ?? 0), thumbnailUrl: sData['thumbnailUrl'],
              colorPrimary: colors.$1, colorSecondary: colors.$2,
            ));
          }
        }
      }
      return tracks;
    } catch (e) { return []; }
  }

  @override
  Future<List<SongModel>> fetchAlbumTracks(String browseId, {int limit = 25}) async {
    try {
      AppLogger.i(_tag, 'fetchAlbumTracks: $browseId');
      final response = await _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {
          "browseId": browseId,
          "context": {
            "client": { "clientName": "WEB_REMIX", "clientVersion": "1.20240320.01.00" }
          }
        },
      );

      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      
      final List<dynamic> contents = data['contents']?['twoColumnBrowseResultsRenderer']?['secondaryContents']?['sectionListRenderer']?['contents'] ?? [];
      // Albums usually have a musicShelfRenderer for tracks
      final shelf = contents.firstOrNull?['musicShelfRenderer'];
      if (shelf == null) return [];

      final items = shelf['contents'] as List?;
      if (items == null) return [];

      final tracks = <SongModel>[];
      for (final item in items) {
        final mapped = _parseMytmItem(item);
        if (mapped != null && mapped['type'] == 'song') {
          final sData = mapped['data'] as Map<String, dynamic>;
          final colors = _colorsForId(sData['id']);
          tracks.add(SongModel(
            id: sData['id'], title: sData['title'], artist: sData['artist'], album: '',
            duration: Duration(milliseconds: sData['durationMs'] ?? 0), thumbnailUrl: sData['thumbnailUrl'],
            colorPrimary: colors.$1, colorSecondary: colors.$2,
          ));
        }
      }
      return tracks.take(limit).toList();
    } catch (e) { return []; }
  }

  @override
  Future<List<SongModel>> fetchRadioTracks(String videoId, {int limit = 25}) async {
    try {
      final response = await _dio.post('$_ytmBase/next?prettyPrint=false', data: {
          "videoId": videoId,
          "context": { "client": { "clientName": "WEB_REMIX", "clientVersion": "1.20240320.01.00" } }
      });
      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      
      final suggestions = data['contents']?['singleColumnMusicWatchNextResultsRenderer']?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['musicQueueRenderer']?['content']?['playlistPanelRenderer']?['contents'] as List<dynamic>? ?? [];
      final tracks = <SongModel>[];
      
      for (final item in suggestions) {
        final mapped = _parseMytmItem(item);
        if (mapped != null && mapped['type'] == 'song') {
          final sData = mapped['data'] as Map<String, dynamic>;
          final colors = _colorsForId(sData['id']);
          tracks.add(SongModel(
            id: sData['id'], title: sData['title'], artist: sData['artist'], album: '',
            duration: Duration(milliseconds: sData['durationMs'] ?? 0), thumbnailUrl: sData['thumbnailUrl'],
            colorPrimary: colors.$1, colorSecondary: colors.$2,
          ));
        }
      }
      return tracks;
    } catch (e) {
      // Return empty list on failure
      return [];
    }
  }

  @override
  Future<List<SongModel>> fetchSongsByIds(List<String> ids) async {
    final songs = <SongModel>[];
    for (final id in ids) {
      try {
        final v = await _ytExplode.videos.get(id);
        final colors = _colorsForId(v.id.value);
        songs.add(SongModel(
          id: v.id.value, title: v.title, artist: v.author, album: '',
          duration: v.duration ?? Duration.zero, thumbnailUrl: v.thumbnails.highResUrl,
          colorPrimary: colors.$1, colorSecondary: colors.$2,
        ));
      } catch (e) {}
    }
    return songs;
  }

  @override
  Future<void> prefetchAudio(String videoId) async {
    await _resolver.resolveYoutubeStream(videoId);
  }

  @override
  Future<void> recordPlay(SongModel song) async {}
  @override
  Future<Map<String, dynamic>> fetchPersistentHistory() async => {};
  @override
  List<Map<String, dynamic>> fetchCategories() => [];

  static const _colorPairs = [
    (Color(0xFF7C3AED), Color(0xFF2563EB)),
    (Color(0xFFEC4899), Color(0xFFEF4444)),
    (Color(0xFF059669), Color(0xFF0891B2)),
    (Color(0xFFF59E0B), Color(0xFF6366F1)),
    (Color(0xFF0284C7), Color(0xFF059669)),
    (Color(0xFFDB2777), Color(0xFF9333EA)),
    (Color(0xFF14B8A6), Color(0xFF0F766E)),
    (Color(0xFF8B5CF6), Color(0xFF4C1D95)),
  ];

  (Color, Color) _colorsForId(String id) {
    final hash = id.codeUnits.fold(0, (a, b) => a + b);
    return _colorPairs[hash % _colorPairs.length];
  }

  @override
  Future<String> createPlaylist({required String title, String? description, String? privacyStatus, List<String>? videoIds, String? sourcePlaylist}) async => '';
  @override
  Future<void> editPlaylist({required String playlistId, String? title, String? description, String? privacyStatus}) async {}
  @override
  Future<void> deletePlaylist(String playlistId) async {}
  @override
  Future<void> addPlaylistItems({required String playlistId, required List<String> videoIds, String? sourcePlaylist, bool duplicates = false}) async {}
  @override
  Future<void> removePlaylistItems({required String playlistId, required List<Map<String, dynamic>> videos}) async {}
  @override
  Future<void> likeArtist(String channelId) async {}
  @override
  Future<void> unlikeArtist(String channelId) async {}
  @override
  Future<PlaylistModel> createFlowPlaylist({required String title, String description = '', bool isPublic = false}) async => throw UnimplementedError();
  @override
  Future<PlaylistModel> updateFlowPlaylist(String playlistId, {String? title, String? description, bool? isPublic}) async => throw UnimplementedError();
  @override
  Future<void> deleteFlowPlaylist(String playlistId) async {}
  @override
  Future<void> addTrackToFlowPlaylist(String playlistId, Map<String, dynamic> songData) async {}
  @override
  Future<void> removeTrackFromFlowPlaylist(String playlistId, int trackId) async {}
  @override
  Future<void> addCollaborator(String playlistId, String userCode) async {}
  @override
  Future<void> removeCollaborator(String playlistId, String userCode) async {}
}