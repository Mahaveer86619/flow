import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/network/dio_client.dart';
import '../../models/home_data_model.dart';
import '../../models/playlist_model.dart';
import '../../models/song_model.dart';
import 'music_data_source.dart';
import 'stream_resolver.dart';

class YoutubeMusicDataSource implements MusicDataSource {
  final Dio _dio = DioClient.instance.dio;
  final YoutubeExplode _ytExplode = YoutubeExplode();
  final StreamResolver _resolver = StreamResolver.instance;

  static const _tag = 'YoutubeMusicDataSource';
  static const _ytmBase = 'https://music.youtube.com/youtubei/v1';

  final Map<String, dynamic> _context = {
    "client": {
      "clientName": "WEB_REMIX",
      "clientVersion": "1.20240409.01.01",
      "hl": "en",
      "gl": "US",
      "utcOffsetMinutes": 0,
      "osName": "Windows",
      "osVersion": "10.0",
      "platform": "DESKTOP",
    },
    "user": {"lockedSafetyMode": false},
  };

  final Map<String, dynamic> _standardContext = {
    "client": {
      "clientName": "WEB",
      "clientVersion": "2.20240409.01.01",
      "hl": "en",
      "gl": "US",
      "utcOffsetMinutes": 0,
      "osName": "Windows",
      "osVersion": "10.0",
      "platform": "DESKTOP",
    },
    "user": {"lockedSafetyMode": false},
  };

  @override
  Future<HomeDataModel> fetchHomeData({int limit = 25}) async {
    try {
      AppLogger.i(_tag, 'fetchHomeData starting');
      final visitorData =
          LocalStorage.instance.getCachedMetadata('yt_visitor_data') as String?;

      final primaryFuture = _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {
          "browseId": "FEmusic_home",
          "context": {
            ..._context,
            if (visitorData != null) "visitorData": visitorData,
          },
        },
      );

      final subFeedSpecs = [
        ('FEmusic_listen_again', null, 'listeningAgain'),
        ('FEmusic_home', 'EgWKAQIIAWoQEAMQBBAJEAoQCxAEEAoQAA==', 'quickPicks'),
        ('FEmusic_home', 'EgWKAQIIAWoQEAMQBBAJEAoQCxAEEAoQAA==', 'podcasts'),
        ('FEmusic_home', 'EgWKAQIIAWoQEAMQBBAJEAoQCxAEEAoQAA==', 'relax'),
      ];

      final subFeedFutures = subFeedSpecs.map(
        (spec) => _fetchShelf(spec.$1, params: spec.$2, forcedSection: spec.$3),
      );
      final results = await Future.wait([primaryFuture, ...subFeedFutures]);

      final primaryResponse = results[0] as Response;
      if (primaryResponse.statusCode != 200) {
        return const HomeDataModel(rawShelves: []);
      }

      final primaryData = primaryResponse.data as Map<String, dynamic>;
      final mainModel = _parseHomeDataInternal(primaryData);
      final List<Map<String, dynamic>> finalShelves = List.from(mainModel.rawShelves);

      for (int i = 0; i < subFeedSpecs.length; i++) {
        final sectionType = subFeedSpecs[i].$3;
        final shelves = results[i + 1] as List<Map<String, dynamic>>;

        if (shelves.isNotEmpty) {
          final shelfCopy = Map<String, dynamic>.from(shelves.first);
          shelfCopy['section'] = sectionType;
          finalShelves.add(shelfCopy);
        }
      }

      return HomeDataModel(
        rawShelves: finalShelves,
        trending: mainModel.trending,
      );
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchHomeData failed', e, st);
      return const HomeDataModel(rawShelves: []);
    }
  }

  @override
  Future<List<SongModel>> searchSongs(String query, {int limit = 25}) async {
    try {
      AppLogger.i(_tag, 'Mixed searchSongs("$query")');
      final results = await Future.wait([
        _searchYtMusic(query, limit: limit),
        _searchStandardYouTube(query, limit: limit),
      ]);

      final ytMusicTracks = results[0];
      final standardTracks = results[1];

      final Map<String, SongModel> merged = {};
      for (final t in ytMusicTracks) {
        merged[t.id] = t;
      }
      for (final t in standardTracks) {
        if (!merged.containsKey(t.id)) {
          merged[t.id] = t;
        }
      }

      return merged.values.toList().take(limit).toList();
    } catch (e) {
      AppLogger.e(_tag, 'searchSongs failed', e);
      return [];
    }
  }

  Future<List<SongModel>> _searchYtMusic(String query, {int limit = 25}) async {
    try {
      final response = await _dio.post(
        '$_ytmBase/search?prettyPrint=false',
        data: {
          "query": query,
          "params": "EgWKAQIIAWoQEAMQBBAJEAoQCxAEEAoQAA==",
          "context": _context,
        },
      );
      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      final tracks = <SongModel>[];

      final contents = data['contents']?['tabbedSearchResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      if (contents == null) return [];

      for (final section in contents) {
        final shelf = section['musicShelfRenderer'];
        if (shelf == null) continue;
        for (final item in shelf['contents'] ?? []) {
          final track = _parseMytmItem(item);
          if (track != null && track['type'] == 'song') {
            tracks.add(SongModel.fromJson(track['data']));
          }
        }
      }
      return tracks;
    } catch (_) {
      return [];
    }
  }

  Future<List<SongModel>> _searchStandardYouTube(String query, {int limit = 25}) async {
    try {
      final response = await _dio.post(
        'https://www.youtube.com/youtubei/v1/search?prettyPrint=false',
        data: {
          "query": query,
          "context": _standardContext,
        },
      );
      
      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      final tracks = <SongModel>[];

      final contents = data['contents']?['twoColumnSearchResultsRenderer']?['primaryContents']?['sectionListRenderer']?['contents'];
      if (contents == null) return [];

      for (final section in contents) {
        final itemSection = section['itemSectionRenderer'];
        if (itemSection == null) continue;
        for (final item in itemSection['contents'] ?? []) {
          final video = item['videoRenderer'];
          if (video == null) continue;

          final videoId = video['videoId'];
          final title = video['title']?['runs']?[0]?['text'] ?? 'Unknown';
          final artist = video['ownerText']?['runs']?[0]?['text'] ?? 'Unknown Artist';
          final durationStr = video['lengthText']?['simpleText'] ?? '0:00';
          final duration = _parseDuration(durationStr);
          final thumb = video['thumbnail']?['thumbnails']?.last?['url'];

          tracks.add(SongModel(
            id: videoId,
            title: title,
            artist: artist,
            album: 'YouTube',
            duration: duration,
            thumbnailUrl: thumb,
            source: 'yt',
          ));
        }
      }
      return tracks;
    } catch (_) {
      return [];
    }
  }

  Duration _parseDuration(String text) {
    try {
      final parts = text.split(':');
      if (parts.length == 2) {
        return Duration(minutes: int.parse(parts[0]), seconds: int.parse(parts[1]));
      } else if (parts.length == 3) {
        return Duration(hours: int.parse(parts[0]), minutes: int.parse(parts[1]), seconds: int.parse(parts[2]));
      }
    } catch (_) {}
    return Duration.zero;
  }

  Future<List<Map<String, dynamic>>> _fetchShelf(String browseId, {String? params, String? forcedSection}) async {
    try {
      final response = await _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {
          "browseId": browseId,
          if (params != null) "params": params,
          "context": _context,
        },
      );
      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      
      final contents = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      if (contents == null) return [];

      final results = <Map<String, dynamic>>[];
      for (final section in contents) {
        final shelf = section['musicShelfRenderer'] ?? section['musicCarouselShelfRenderer'];
        if (shelf == null) continue;
        
        final items = <Map<String, dynamic>>[];
        final contentList = shelf['contents'] ?? [];
        for (final item in contentList) {
          final mapped = _parseMytmItem(item);
          if (mapped != null) items.add(mapped);
        }

        results.add({
          'title': shelf['title']?['runs']?[0]?['text'] ?? (forcedSection ?? 'More'),
          'items': items,
        });
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  HomeDataModel _parseHomeDataInternal(Map<String, dynamic> data) {
    final shelves = <Map<String, dynamic>>[];
    final contents = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
    
    if (contents != null) {
      for (final section in contents) {
        final shelf = section['musicCarouselShelfRenderer'] ?? section['musicShelfRenderer'];
        if (shelf == null) continue;
        
        final items = <Map<String, dynamic>>[];
        for (final item in shelf['contents'] ?? []) {
          final mapped = _parseMytmItem(item);
          if (mapped != null) items.add(mapped);
        }
        
        shelves.add({
          'title': shelf['title']?['runs']?[0]?['text'] ?? 'More',
          'items': items,
        });
      }
    }
    return HomeDataModel(rawShelves: shelves);
  }

  Map<String, dynamic>? _parseMytmItem(Map<String, dynamic> item) {
    try {
      final renderer = item['musicTwoRowItemRenderer'] ?? item['musicResponsiveListItemRenderer'];
      if (renderer == null) return null;

      final title = renderer['title']?['runs']?[0]?['text'] ?? renderer['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'];
      final videoId = renderer['navigationEndpoint']?['watchEndpoint']?['videoId'] ?? renderer['playlistItemData']?['videoId'];
      final browseId = renderer['navigationEndpoint']?['browseEndpoint']?['browseId'];
      final thumb = (renderer['thumbnail']?['musicThumbnailRenderer'] ?? renderer['thumbnail'])?['thumbnail']?['thumbnails']?.last?['url'];

      if (videoId != null) {
        return {
          'type': 'song',
          'data': {
            'id': videoId,
            'title': title,
            'artist': 'Various',
            'album': 'Album',
            'durationMs': 0,
            'thumbnailUrl': thumb,
          }
        };
      } else if (browseId != null) {
        return {
          'type': 'playlist',
          'data': {
            'id': browseId,
            'name': title,
            'description': '',
            'thumbnailUrl': thumb,
          }
        };
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<SongModel>> fetchPlaylistTracks(String playlistId, {int limit = 100}) async => [];

  @override
  Future<List<SongModel>> fetchAlbumTracks(String browseId, {int limit = 25}) async => [];

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
  Future<List<SongModel>> fetchBlendedRecommendations(String friendId, {int limit = 20}) async => [];

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
  Future<void> addCollaborator(String playlistId, String userCode) async {}

  @override
  Future<void> addTrackToFlowPlaylist(String playlistId, SongModel song) async {}

  @override
  Future<PlaylistModel> createFlowPlaylist({required String title, String description = '', bool isPublic = false}) async {
     return PlaylistModel(id: 'temp', name: title, description: description, color: const Color(0xFF7C3AED));
  }

  @override
  Future<void> deleteFlowPlaylist(String playlistId) async {}

  @override
  Future<Map<String, dynamic>> fetchPersistentHistory() async => {};

  @override
  Future<List<SongModel>> fetchRadioTracks(String videoId, {int limit = 25}) async => [];

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
  Future<void> removeTrackFromFlowPlaylist(String playlistId, int trackId) async {}

  @override
  Future<void> unlikeArtist(String channelId) async {}

  @override
  Future<PlaylistModel> updateFlowPlaylist(String playlistId, {String? title, String? description, bool? isPublic}) async {
    return PlaylistModel(id: playlistId, name: title ?? '', description: description ?? '', color: const Color(0xFF7C3AED));
  }
}
