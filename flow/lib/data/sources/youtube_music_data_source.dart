import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../core/logger/app_logger.dart';
import '../../core/storage/local_storage.dart';
import '../../core/network/dio_client.dart';
import '../models/home_data_model.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import 'music_data_source.dart';
import 'stream_resolver.dart';

class YoutubeMusicDataSource implements MusicDataSource {
  // Use the authenticated singleton for metadata to ensure cookies/auth are sent
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
    },
    "user": {
      "lockedSafetyMode": false,
    }
  };

  @override
  Future<HomeDataModel> fetchHomeData({int limit = 25}) async {
    try {
      AppLogger.i(_tag, 'fetchHomeData starting');
      final visitorData =
          LocalStorage.instance.getCachedMetadata('yt_visitor_data') as String?;

      // Primary Home Feed
      final response = await _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {
          "browseId": "FEmusic_home",
          "context": {
            ..._context,
            if (visitorData != null) "visitorData": visitorData,
          }
        },
      );

      if (response.statusCode != 200) return const HomeDataModel(rawShelves: []);

      final data = response.data as Map<String, dynamic>;

      // visitorData update
      final newVisitorData = data['responseContext']?['visitorData'];
      if (newVisitorData != null) {
        LocalStorage.instance.saveCachedMetadata('yt_visitor_data', newVisitorData);
      }

      var model = _parseHomeDataInternal(data);
      
      // Check for missing key shelves and try dedicated endpoints
      final hasListeningAgain = model.rawShelves.any((s) => s['section'] == 'listeningAgain');
      final hasQuickPicks = model.rawShelves.any((s) => s['section'] == 'quickPicks');

      if (!hasListeningAgain || !hasQuickPicks) {
        AppLogger.i(_tag, 'Missing personalized shelves, trying sub-feeds...');
        final List<(String, String)> subFeeds = [];
        if (!hasListeningAgain) subFeeds.add(('FEmusic_listen_again', 'listeningAgain'));
        if (!hasQuickPicks) subFeeds.add(('FEmusic_home', 'quickPicks'));

        for (final feed in subFeeds) {
          try {
             final subResponse = await _dio.post(
                '$_ytmBase/browse?prettyPrint=false',
                data: {
                  "browseId": feed.$1,
                  if (feed.$2 == 'quickPicks' && feed.$1 == 'FEmusic_home')
                    "params": "EgWKAQIIAWoQEAMQBBAJEAoQCxAEEAoQAA==",
                  "context": _context, // Use clean context for sub-feeds
                },
              );
              if (subResponse.statusCode == 200) {
                final subData = subResponse.data as Map<String, dynamic>;
                final subModel = _parseHomeDataInternal(subData);
                
                // Find any shelf from the sub-feed that matches our target type
                final targetShelves = subModel.rawShelves.where(
                  (s) => s['section'] == feed.$2,
                ).toList();

                if (targetShelves.isNotEmpty) {
                  final newShelves = List<Map<String, dynamic>>.from(model.rawShelves);
                  for (final ts in targetShelves) {
                    final shelfCopy = Map<String, dynamic>.from(ts);
                    shelfCopy['section'] = feed.$2;
                    
                    if (!newShelves.any((s) => s['title'] == shelfCopy['title'])) {
                       newShelves.add(shelfCopy);
                    }
                  }
                  model = HomeDataModel(
                    rawShelves: newShelves,
                    profileUrl: model.profileUrl,
                    ytName: model.ytName,
                    trending: model.trending,
                    musicVideos: model.musicVideos,
                    favArtistsSongs: model.favArtistsSongs,
                  );
                } else if (subModel.rawShelves.isNotEmpty) {
                   // Fallback: look for a shelf that matches the target title or is generic
                   final targetTitlePart = feed.$2 == 'quickPicks' ? 'pick' : 'listen';
                   
                   final candidate = subModel.rawShelves.firstWhere(
                     (s) {
                       final t = (s['title'] as String? ?? '').toLowerCase();
                       final currentSection = s['section'] as String? ?? 'standard';
                       
                       // Don't hijack if it's already a different specialized section
                       if (feed.$2 == 'quickPicks' && currentSection == 'listeningAgain') return false;
                       if (feed.$2 == 'listeningAgain' && currentSection == 'quickPicks') return false;
                       
                       return t.contains(targetTitlePart) || currentSection == 'standard' || currentSection == 'mixedForYou';
                     },
                     orElse: () => {},
                   );
                   
                   if (candidate.isNotEmpty) {
                     final shelfCopy = Map<String, dynamic>.from(candidate);
                     shelfCopy['section'] = feed.$2;
                     
                     final newShelves = List<Map<String, dynamic>>.from(model.rawShelves);
                     if (!newShelves.any((s) => s['title'] == shelfCopy['title'])) {
                        newShelves.add(shelfCopy);
                        model = HomeDataModel(
                          rawShelves: newShelves,
                          profileUrl: model.profileUrl,
                          ytName: model.ytName,
                          trending: model.trending,
                          musicVideos: model.musicVideos,
                          favArtistsSongs: model.favArtistsSongs,
                        );
                     }
                   }
                }
              }
          } catch (e) {
            AppLogger.w(_tag, 'Failed to fetch sub-feed ${feed.$1}: $e');
          }
        }
      }

      // Fallback to trending if still empty
      if (model.rawShelves.isEmpty) {
        AppLogger.w(_tag, 'Home feed empty, fetching trending fallback...');
        final trending = await searchSongs('trending hits');
        if (trending.isNotEmpty) {
          model = HomeDataModel(
            rawShelves: [
              {
                'title': 'Trending Hits',
                'section': 'trending',
                'items': trending.map((s) => {
                  'type': 'song',
                  'data': s.toJson(),
                }).toList(),
              }
            ],
          );
        }
      }

      return model;
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchHomeData failed', e, st);
      return const HomeDataModel(rawShelves: []);
    }
  }

  HomeDataModel _parseHomeDataInternal(Map<String, dynamic> data, {String? forcedSectionType}) {
    final List<Map<String, dynamic>> shelves = [];
    final contents = data['contents'];
    if (contents == null) return const HomeDataModel(rawShelves: []);

    List? sectionList = contents['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] ??
                        contents['sectionListRenderer']?['contents'];

    if (sectionList == null) return const HomeDataModel(rawShelves: []);

    for (final section in sectionList) {
      final shelf = section['musicCarouselShelfRenderer'] ?? 
                    section['musicShelfRenderer'] ?? 
                    section['musicTastebuilderShelfRenderer'] ??
                    section['itemSectionRenderer'];
      if (shelf == null) continue;

      final header = shelf['header']?['musicCarouselShelfBasicHeaderRenderer'] ??
          shelf['header']?['musicHeaderRenderer'];

      final title = header?['title']?['runs']?[0]?['text'] ??
          header?['title']?['simpleText'] ??
          shelf['primaryText']?['runs']?[0]?['text'] ??
          shelf['primaryText']?['simpleText'];
      
      if (title != null) {
        AppLogger.d(_tag, 'Parsed shelf title: "$title"');
      }
      
      String sectionType = forcedSectionType ?? 'standard';
      if (forcedSectionType == null && title != null) {
        final t = title.toLowerCase();
        if (t.contains('listen again') || t.contains('recent') || t.contains('frequent')) {
          sectionType = 'listeningAgain';
        } else if (t.contains('quick picks') || t.contains('start radio') || t.contains('speed dial') || t.contains('picks')) {
          sectionType = 'quickPicks';
        } else if (t.contains('mixed for you') || t.contains('recommended') || t.contains('mixes') || t.contains('picked for you') || t.contains('create a mix')) {
          sectionType = 'mixedForYou';
        } else if (t.contains('trending') || t.contains('romance') || t.contains('charts') || t.contains('hits')) {
          sectionType = 'trending';
        } else if (t.contains('music video') || t.contains('videos for you')) {
          sectionType = 'musicVideos';
        } else if (t.contains('long listening')) {
          sectionType = 'longListening';
        } else if (t.contains('podcast')) {
          sectionType = 'podcasts';
        } else if (t.contains('daily discover') || t.contains('new arrival') || t.contains('new release') || t.contains('latest')) {
          sectionType = 'newArrivals';
        } else if (t.contains('album') || t.contains('spotlight')) {
          // Map "Spotlight" shelves to Albums For You as requested
          sectionType = 'albumsForYou';
        }
      }

      final items = <Map<String, dynamic>>[];
      final contentList = (shelf['contents'] as List?) ??
          (shelf['items'] as List?) ??
          (shelf['tastebuilderItems'] as List?);

      if (contentList != null) {
        for (final item in contentList) {
          final parsed = _parseMytmItem(item);
          if (parsed != null) items.add(parsed);
        }
      }

      if (items.isNotEmpty) {
        shelves.add({
          'title': title ?? 'Recommended',
          'section': sectionType,
          'items': items,
        });
      }
    }

    return HomeDataModel(rawShelves: shelves);
  }

  Map<String, dynamic>? _parseMytmItem(dynamic item) {
    final renderer = item['musicTwoColumnItemRenderer'] ?? 
                     item['musicResponsiveListItemRenderer'] ??
                     item['musicNavigationButtonRenderer'] ??
                     item['musicItemRenderer'] ??
                     item['musicMultiRowListItemRenderer'] ??
                     item['musicWideButtonRenderer'] ??
                     item['musicPlaylistRenderer'] ??
                     item['musicVideoRenderer'] ??
                     item['gridVideoRenderer'] ??
                     item['gridPlaylistRenderer'] ??
                     item['musicTwoRowItemRenderer'] ??
                     item['playlistPanelVideoRenderer'];    
    if (renderer == null) return null;

    String? title = renderer['title']?['runs']?[0]?['text'] ?? 
                    renderer['title']?['simpleText'] ??
                    renderer['text']?['runs']?[0]?['text'];

    String? subtitle;
    final subtitleRuns = renderer['subtitle']?['runs'] as List?;
    if (subtitleRuns != null) {
      subtitle = subtitleRuns.map((r) => r['text']).where((t) => t != ' • ').join('');
    } else {
      subtitle = renderer['subtitle']?['simpleText'] ?? 
                 renderer['description']?['runs']?[0]?['text'] ??
                 renderer['longBylineText']?['runs']?[0]?['text'] ??
                 renderer['shortBylineText']?['runs']?[0]?['text'];
    }

    final nav = renderer['navigationEndpoint'] ?? renderer['onTap']?['navigationEndpoint'];
    String? videoId = nav?['watchEndpoint']?['videoId'] ?? 
                      renderer['videoId'] ?? 
                      renderer['playlistItemData']?['videoId'];
                   
    String? browseId = nav?['browseEndpoint']?['browseId'] ??
                       renderer['browseId'] ??
                       renderer['navigationEndpoint']?['browseEndpoint']?['browseId'];

    // Support for musicResponsiveListItemRenderer flexColumns (common in search results)
    if (item['musicResponsiveListItemRenderer'] != null) {
      final flexCols = item['musicResponsiveListItemRenderer']['flexColumns'] as List?;
      if (flexCols != null && flexCols.isNotEmpty) {
        final firstCol = flexCols[0]['musicResponsiveListItemFlexColumnRenderer'];
        title ??= firstCol?['text']?['runs']?[0]?['text'];
        videoId ??= firstCol?['text']?['runs']?[0]?['navigationEndpoint']?['watchEndpoint']?['videoId'];
        
        if (flexCols.length > 1) {
          final secondCol = flexCols[1]['musicResponsiveListItemFlexColumnRenderer'];
          final runs = secondCol?['text']?['runs'] as List?;
          if (runs != null) {
            subtitle ??= runs.map((r) => r['text']).join();
            for (final run in runs) {
              final bId = run['navigationEndpoint']?['browseEndpoint']?['browseId'];
              if (bId != null) {
                browseId ??= bId;
                break;
              }
            }
          }
        }
      }
    }

    if (title == null) return null;

    final thumbNode = renderer['thumbnailRenderer']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']?.last ??
                      renderer['thumbnail']?['thumbnails']?.last ??
                      renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']?.last;
    
    final thumb = thumbNode?['url'];
    final width = thumbNode?['width'] as int?;
    final height = thumbNode?['height'] as int?;
    
    String? highResThumb = thumb;
    if (thumb != null && thumb.contains('=w') && thumb.contains('-h')) {
      if (width != null && height != null && width != height) {
        // Respect aspect ratio for non-square thumbnails
        if (width > height) {
          highResThumb = thumb.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w1280-h720-l90-rj');
        } else {
          highResThumb = thumb.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w720-h1280-l90-rj');
        }
      } else {
        highResThumb = thumb.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w512-h512-l90-rj');
      }
    }

    if (videoId != null) {
      return {
        'type': 'song',
        'data': {
          'id': videoId,
          'title': title,
          'artist': subtitle ?? 'Unknown Artist',
          'thumbnailUrl': highResThumb,
          'thumbnailWidth': width,
          'thumbnailHeight': height,
        }
      };
    } else if (browseId != null) {
      final isArtist = browseId.startsWith('UC') || browseId.startsWith('FBA');
      return {
        'type': isArtist ? 'artist' : 'playlist',
        'data': {
          'id': browseId,
          'name': title,
          'thumbnailUrl': highResThumb,
          'thumbnailWidth': width,
          'thumbnailHeight': height,
          'description': subtitle ?? '',
        }
      };
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
          "context": _context,
        },
      );

      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      
      final List<dynamic> shelves = data['contents']?['tabbedSearchResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] ?? [];
      
      final tracks = <SongModel>[];
      for (final shelf in shelves) {
        final musicShelf = shelf['musicShelfRenderer'] ?? shelf['musicCardShelfRenderer'];
        if (musicShelf == null) continue;
        
        final List<dynamic> results = musicShelf['contents'] ?? [];
        for (final item in results) {
          final mapped = _parseMytmItem(item);
          if (mapped != null && mapped['type'] == 'song') {
            final sData = mapped['data'] as Map<String, dynamic>;
            final colors = _colorsForId(sData['id']);
            tracks.add(SongModel(
              id: sData['id'],
              title: sData['title'],
              artist: sData['artist'],
              album: '',
              duration: Duration.zero,
              thumbnailUrl: sData['thumbnailUrl'],
              thumbnailWidth: sData['thumbnailWidth'],
              thumbnailHeight: sData['thumbnailHeight'],
              colorPrimary: colors.$1,
              colorSecondary: colors.$2,
            ));
          }
        }
      }
      return tracks.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<PlaylistModel>> fetchPlaylists() async => [];

  @override
  Future<List<SongModel>> fetchPlaylistTracks(String playlistId, {int limit = 100}) async {
    try {
      final playlist = await _ytExplode.playlists.get(playlistId);
      final List<Video> videos = await _ytExplode.playlists.getVideos(playlistId).take(limit).toList();

      final tracks = <SongModel>[];
      for (final v in videos) {
        final colors = _colorsForId(v.id.value);
        tracks.add(SongModel(
          id: v.id.value,
          title: v.title,
          artist: v.author,
          album: playlist.title,
          duration: v.duration ?? Duration.zero,
          thumbnailUrl: v.thumbnails.highResUrl,
          colorPrimary: colors.$1,
          colorSecondary: colors.$2,
        ));
      }
      return tracks;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<SongModel>> fetchAlbumTracks(String browseId, {int limit = 25}) async {
    try {
      final response = await _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {
          "browseId": browseId,
          "context": _context,
        },
      );

      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      
      final List<dynamic> contents = data['contents']?['twoColumnBrowseResultsRenderer']?['secondaryContents']?['sectionListRenderer']?['contents'] ?? [];
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
            duration: Duration(milliseconds: sData['durationMs'] ?? 0), 
            thumbnailUrl: sData['thumbnailUrl'],
            thumbnailWidth: sData['thumbnailWidth'],
            thumbnailHeight: sData['thumbnailHeight'],
            colorPrimary: colors.$1, colorSecondary: colors.$2,
          ));
        }
      }
      return tracks.take(limit).toList();
    } catch (e) { return []; }
  }

  @override
  Future<List<SongModel>> fetchArtistSongs(String channelId) async {
    try {
      final response = await _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {
          "browseId": channelId,
          "context": _context,
        },
      );

      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      
      final sectionList = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] as List?;
      if (sectionList == null) return [];

      final tracks = <SongModel>[];
      for (final section in sectionList) {
        final shelf = section['musicShelfRenderer'] ?? section['musicCarouselShelfRenderer'];
        if (shelf == null) continue;
        
        final items = shelf['contents'] as List?;
        if (items == null) continue;

        for (final item in items) {
          final mapped = _parseMytmItem(item);
          if (mapped != null && mapped['type'] == 'song') {
            final sData = mapped['data'] as Map<String, dynamic>;
            final colors = _colorsForId(sData['id']);
            tracks.add(SongModel(
              id: sData['id'], title: sData['title'], artist: sData['artist'], album: '',
              duration: Duration(milliseconds: sData['durationMs'] ?? 0), 
              thumbnailUrl: sData['thumbnailUrl'],
              thumbnailWidth: sData['thumbnailWidth'],
              thumbnailHeight: sData['thumbnailHeight'],
              colorPrimary: colors.$1, colorSecondary: colors.$2,
            ));
          }
        }
      }
      return tracks;
    } catch (e) { return []; }
  }

  @override
  Future<List<SongModel>> fetchRadioTracks(String videoId, {int limit = 25}) async {
    try {
      AppLogger.i(_tag, 'fetchRadioTracks: $videoId');
      final response = await _dio.post('$_ytmBase/next?prettyPrint=false', data: {
          "videoId": videoId,
          "playlistId": "RDAMVM$videoId",
          "context": _context,
      });
      
      if (response.statusCode != 200) {
        AppLogger.e(_tag, 'fetchRadioTracks failed: ${response.statusCode}');
        return [];
      }
      
      final data = response.data as Map<String, dynamic>;
      final watchNext = data['contents']?['singleColumnMusicWatchNextResultsRenderer'] ?? 
                        data['contents']?['twoColumnWatchNextResultsRenderer'];
      
      if (watchNext == null) {
        AppLogger.w(_tag, 'fetchRadioTracks: watchNext not found');
        return [];
      }

      List<dynamic>? contents;
      
      // Try to find the queue in tabbed renderer
      final tabbed = watchNext['tabbedRenderer']?['watchNextTabbedResultsRenderer'];
      if (tabbed != null) {
        final tabs = tabbed['tabs'] as List?;
        if (tabs != null) {
          for (final tab in tabs) {
            final content = tab['tabRenderer']?['content'];
            final queue = content?['musicQueueRenderer']?['content']?['playlistPanelRenderer'];
            if (queue != null) {
              contents = queue['contents'] as List?;
              break;
            }
          }
        }
      }
      
      // Fallback for non-tabbed renderer
      contents ??= watchNext['content']?['musicQueueRenderer']?['content']?['playlistPanelRenderer']?['contents'] as List?;

      if (contents == null || contents.isEmpty) {
        AppLogger.w(_tag, 'fetchRadioTracks: No suggestions found in response');
        return [];
      }
      
      final tracks = <SongModel>[];
      for (final item in contents) {
        final mapped = _parseMytmItem(item);
        if (mapped != null && mapped['type'] == 'song') {
          final sData = mapped['data'] as Map<String, dynamic>;
          // Skip the current video if it's in the suggestions
          if (sData['id'] == videoId) continue;
          
          final colors = _colorsForId(sData['id']);
          tracks.add(SongModel(
            id: sData['id'], title: sData['title'], artist: sData['artist'], album: '',
            duration: Duration(milliseconds: sData['durationMs'] ?? 0), 
            thumbnailUrl: sData['thumbnailUrl'],
            thumbnailWidth: sData['thumbnailWidth'],
            thumbnailHeight: sData['thumbnailHeight'],
            colorPrimary: colors.$1, colorSecondary: colors.$2,
          ));
        }
      }
      
      AppLogger.d(_tag, 'fetchRadioTracks: Found ${tracks.length} tracks');
      return tracks;
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchRadioTracks error', e, st);
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
          duration: v.duration ?? Duration.zero, 
          thumbnailUrl: v.thumbnails.highResUrl,
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
  Future<Map<String, dynamic>> fetchSongDetails(String videoId) async {
    try {
      final response = await _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {
          "browseId": "FEmusic_library_item_details",
          "context": _context,
          "params": videoId,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final Map<String, dynamic> details = {'videoId': videoId};

      final sectionList = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] as List?;
      if (sectionList != null) {
        for (final section in sectionList) {
          final shelf = section['musicDescriptionShelfRenderer'];
          if (shelf != null) {
            details['description'] = shelf['description']?['runs']?[0]?['text'];
            details['footer'] = shelf['footer']?['runs']?[0]?['text'];
            break;
          }
        }
      }
      return details;
    } catch (e) { return {}; }
  }

  @override
  Future<Map<String, dynamic>> fetchArtistDetails(String browseId) async {
    try {
      final response = await _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {
          "browseId": browseId,
          "context": _context,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final Map<String, dynamic> details = {'browseId': browseId};

      final header = data['header']?['musicImmersiveHeaderRenderer'] ?? data['header']?['musicVisualHeaderRenderer'];
      if (header != null) {
        details['name'] = header['title']?['runs']?[0]?['text'];
        final thumb = header['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']?.last?['url'];
        details['thumbnailUrl'] = thumb;
      }

      final sectionList = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] as List?;
      if (sectionList != null) {
        for (final section in sectionList) {
          final shelf = section['musicDescriptionShelfRenderer'];
          if (shelf != null) {
            details['biography'] = shelf['description']?['runs']?[0]?['text'];
            break;
          }
        }
      }
      return details;
    } catch (e) { return {}; }
  }

  @override
  List<Map<String, dynamic>> fetchCategories() {
    return [
      {
        'name': 'Chill',
        'params': 'EgWKAQIIAWoQEAMQBBAJEAoQCxAEEAoQAA==',
        'color': const Color(0xFF7C3AED).value
      },
      {
        'name': 'Energy',
        'params': 'EgWKAQIIAWoQEAMQBBAJEAoQCxAEEAoQAA==',
        'color': const Color(0xFFEF4444).value
      },
      {
        'name': 'Focus',
        'params': 'EgWKAQIIAWoQEAMQBBAJEAoQCxAEEAoQAA==',
        'color': const Color(0xFF059669).value
      },
      {
        'name': 'Workout',
        'params': 'EgWKAQIIAWoQEAMQBBAJEAoQCxAEEAoQAA==',
        'color': const Color(0xFFF59E0B).value
      },
    ];
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
  Future<PlaylistModel> createFlowPlaylist({required String title, String description = '', bool isPublic = false}) async => 
      PlaylistModel(id: '', name: title, description: description, color: _colorPairs[0].$1);
  
  @override
  Future<PlaylistModel> updateFlowPlaylist(String playlistId, {String? title, String? description, bool? isPublic}) async => 
      PlaylistModel(id: playlistId, name: title ?? '', description: description ?? '', color: _colorPairs[0].$1);
  
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

  static (Color, Color) _colorsForId(String id) {
    final hash = id.codeUnits.fold(0, (a, b) => a + b);
    return _colorPairs[hash % _colorPairs.length];
  }

  static const _colorPairs = [
    (Color(0xFF7C3AED), Color(0xFF2563EB)),
    (Color(0xFFEC4899), Color(0xFFEF4444)),
    (Color(0xFF059669), Color(0xFF0891B2)),
    (Color(0xFFF59E0B), Color(0xFF6366F1)),
    (Color(0xFF8B5CF6), Color(0xFF4C1D95)),
    (Color(0xFFE879F9), Color(0xFFBE185D)),
  ];
}
