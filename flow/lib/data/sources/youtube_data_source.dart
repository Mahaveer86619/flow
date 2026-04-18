import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../../core/logger/app_logger.dart';
import '../models/home_data_model.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import 'song_data_source.dart';
import 'stream_resolver.dart';
import '../../core/network/dio_client.dart';

class YoutubeDataSource implements SongDataSource {
  final yt.YoutubeExplode _ytExplode = yt.YoutubeExplode();
  final Dio _dio = DioClient.instance.dio;
  final StreamResolver _resolver = StreamResolver.instance;

  static const _tag = 'YoutubeDataSource';
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
            }
          }
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch home from YTM: ${response.statusCode}');
      }

      final data = response.data as Map<String, dynamic>;
      final model = _parseHomeData(data);
      
      AppLogger.i(_tag, 'fetchHomeData complete: ${model.rawShelves.length} shelves found');
      return model;
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchHomeData standalone failed', e, st);
      return const HomeDataModel(
        rawShelves: [],
        trending: [],
        musicVideos: [],
        favArtistsSongs: [],
      );
    }
  }

  HomeDataModel _parseHomeData(Map<String, dynamic> data) {
    final shelves = <Map<String, dynamic>>[];
    
    try {
      // YouTube Music Home JSON structure is deeply nested and varies
      final List<dynamic> contents = data['contents']?['singleColumnBrowseResultsRenderer']
          ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] ?? [];

      for (final section in contents) {
        final shelf = section['musicShelfRenderer'] ?? 
                      section['musicCarouselShelfRenderer'] ??
                      section['musicEditablePlaylistDetailHeaderRenderer'];
        
        if (shelf == null) continue;

        // Extract title
        String? title = shelf['header']?['musicHeaderRenderer']?['title']?['runs']?[0]?['text'] ?? 
                        shelf['title']?['runs']?[0]?['text'] ?? 
                        shelf['title']?['simpleText'];
        
        // Map section types for the UI
        String sectionType = 'standard';
        if (title != null) {
           final t = title.toLowerCase();
           if (t.contains('listen again') || t.contains('recent')) sectionType = 'listeningAgain';
           else if (t.contains('quick picks')) sectionType = 'quickPicks';
           else if (t.contains('mixed for you')) sectionType = 'mixedForYou';
           else if (t.contains('trending')) sectionType = 'trending';
        }

        final items = <Map<String, dynamic>>[];
        final shelfItems = shelf['contents'] as List<dynamic>? ?? 
                           shelf['items'] as List<dynamic>? ?? [];

        for (final item in shelfItems) {
          final mappedItem = _parseMytmItem(item);
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
          AppLogger.d(_tag, 'Parsed shelf: "$title" with ${items.length} items');
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
                       item['musicTwoColumnItemRenderer'] ??
                       item['playlistPanelVideoRenderer'] ??
                       item['musicNavigationButtonRenderer'];
      
      if (renderer == null) return null;

      // Extract basic info
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
                      renderer['navigationEndpoint']?['watchEndpoint']?['videoId'];

      final thumb = renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']?.last?['url'] ??
                    renderer['thumbnailRenderer']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']?.last?['url'] ??
                    renderer['thumbnail']?['thumbnails']?.last?['url'];

      if (videoId != null) {
        // It's a song
        String artist = 'Unknown Artist';
        if (renderer['flexColumns'] != null && (renderer['flexColumns'] as List).length > 1) {
          final runs = renderer['flexColumns']?[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
          if (runs != null && runs.isNotEmpty) {
            artist = runs[0]['text'];
          }
        } else if (renderer['longBylineText'] != null) {
          artist = renderer['longBylineText']?['runs']?[0]?['text'] ?? 'Unknown Artist';
        } else if (renderer['shortBylineText'] != null) {
          artist = renderer['shortBylineText']?['runs']?[0]?['text'] ?? 'Unknown Artist';
        }

        return {
          'type': 'song',
          'data': {
            'id': videoId,
            'title': title ?? 'Unknown Title',
            'artist': artist,
            'thumbnailUrl': thumb,
            'durationMs': 0,
          }
        };
      } else if (browseId != null) {
        if (browseId.startsWith('UC') || browseId.startsWith('F')) {
          // It's an artist
          return {
            'type': 'artist',
            'data': {
              'name': title ?? 'Unknown Artist',
              'thumbnailUrl': thumb,
              'browseId': browseId,
            }
          };
        } else {
          // It's an album or playlist
          return {
            'type': 'playlist',
            'data': {
              'id': browseId,
              'title': title ?? 'Unknown Title',
              'thumbnailUrl': thumb,
            }
          };
        }
      }
    } catch (e) {
      // Silent fail for individual items
    }
    return null;
  }

  @override
  Future<List<SongModel>> searchSongs(String query, {int limit = 25}) async {
    try {
      AppLogger.i(_tag, 'searchSongs standalone: $query');
      final results = await _ytExplode.search.search(query);
      
      return results.take(limit).map((video) {
        final colors = _colorsForId(video.id.value);
        return SongModel(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          album: '',
          duration: video.duration ?? Duration.zero,
          thumbnailUrl: video.thumbnails.highResUrl,
          colorPrimary: colors.$1,
          colorSecondary: colors.$2,
        );
      }).toList();
    } catch (e) {
      AppLogger.e(_tag, 'searchSongs standalone failed', e);
      return [];
    }
  }

  @override
  Future<List<PlaylistModel>> fetchPlaylists() async => [];

  @override
  Future<List<SongModel>> fetchPlaylistTracks(String playlistId, {int limit = 100}) async {
    try {
      final playlist = await _ytExplode.playlists.get(playlistId);
      final videos = await _ytExplode.playlists.getVideos(playlistId).take(limit).toList();
      
      return videos.map((video) {
        final colors = _colorsForId(video.id.value);
        return SongModel(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          album: playlist.title,
          duration: video.duration ?? Duration.zero,
          thumbnailUrl: video.thumbnails.highResUrl,
          colorPrimary: colors.$1,
          colorSecondary: colors.$2,
        );
      }).toList();
    } catch (e) {
      AppLogger.e(_tag, 'fetchPlaylistTracks standalone failed', e);
      return [];
    }
  }

  @override
  Future<List<SongModel>> fetchAlbumTracks(String browseId, {int limit = 25}) async => [];

  @override
  Future<List<SongModel>> fetchArtistSongs(String channelId) async => [];

  @override
  Future<List<SongModel>> fetchRadioTracks(String videoId, {int limit = 25}) async {
    try {
      AppLogger.i(_tag, 'fetchRadioTracks standalone for $videoId');
      
      final response = await _dio.post(
        '$_ytmBase/next?prettyPrint=false',
        data: {
          "videoId": videoId,
          "context": {
            "client": {
              "clientName": "WEB_REMIX",
              "clientVersion": "1.20240320.01.00",
            }
          }
        },
      );

      if (response.statusCode != 200) return [];

      final data = response.data as Map<String, dynamic>;
      
      final suggestions = data['contents']?['singleColumnMusicWatchNextResultsRenderer']
          ?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs']?[0]?['tabRenderer']
          ?['content']?['musicQueueRenderer']?['contents'] as List<dynamic>? ?? [];

      final tracks = <SongModel>[];
      for (final item in suggestions) {
        final mapped = _parseMytmItem(item);
        if (mapped != null && mapped['type'] == 'song') {
          final sData = mapped['data'] as Map<String, dynamic>;
          final colors = _colorsForId(sData['id']);
          tracks.add(SongModel(
            id: sData['id'],
            title: sData['title'],
            artist: sData['artist'],
            album: '',
            duration: Duration(milliseconds: sData['durationMs'] ?? 0),
            thumbnailUrl: sData['thumbnailUrl'],
            colorPrimary: colors.$1,
            colorSecondary: colors.$2,
          ));
        }
      }
      return tracks.take(limit).toList();
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchRadioTracks failed', e, st);
      return [];
    }
  }

  @override
  Future<List<SongModel>> fetchSongsByIds(List<String> ids) async {
    final songs = <SongModel>[];
    for (final id in ids) {
      try {
        final video = await _ytExplode.videos.get(id);
        final colors = _colorsForId(video.id.value);
        songs.add(SongModel(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          album: '',
          duration: video.duration ?? Duration.zero,
          thumbnailUrl: video.thumbnails.highResUrl,
          colorPrimary: colors.$1,
          colorSecondary: colors.$2,
        ));
      } catch (e) {
        AppLogger.w(_tag, 'Failed to fetch video $id: $e');
      }
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

  // --- Consistent colors based on ID ---
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

  // Implementation for the rest of the methods as empty/no-op for now
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
