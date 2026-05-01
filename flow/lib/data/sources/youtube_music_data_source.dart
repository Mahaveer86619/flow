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

  @override
  Future<HomeDataModel> fetchHomeData({int limit = 25}) async {
    try {
      AppLogger.i(_tag, 'fetchHomeData starting (Parallel Shell Execution)');
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
        (
          'FEmusic_home',
          'ggNCSgQIDBADSgQICBABSgQIDhABSgQICRABSgQIBxABSgQIBRAB',
          'podcasts',
        ),
        (
          'FEmusic_home',
          'ggNCSgQIDBABSgQICBABSgQIDhABSgQICRABSgQIBxADSgQIBRAB',
          'relax',
        ),
      ];

      final subFeedFutures = subFeedSpecs.map(
        (spec) => _fetchShelf(spec.$1, params: spec.$2, forcedSection: spec.$3),
      );
      final results = await Future.wait([primaryFuture, ...subFeedFutures]);

      final primaryResponse = results[0] as Response;
      if (primaryResponse.statusCode != 200)
        return const HomeDataModel(rawShelves: []);

      final primaryData = primaryResponse.data as Map<String, dynamic>;
      final mainModel = _parseHomeDataInternal(primaryData);
      final List<Map<String, dynamic>> finalShelves = [];

      // 2. Merge Sub-feeds (STRICT Filtering for Square vs Rectangle)
      for (int i = 0; i < subFeedSpecs.length; i++) {
        final sectionType = subFeedSpecs[i].$3;
        final shelves = results[i + 1] as List<Map<String, dynamic>>;

        if (shelves.isNotEmpty) {
          final shelfCopy = Map<String, dynamic>.from(shelves.first);
          shelfCopy['section'] = sectionType;

          final items = List<Map<String, dynamic>>.from(
            shelfCopy['items'] ?? [],
          );

          if (sectionType == 'listeningAgain' || sectionType == 'quickPicks') {
            // Strictly SQUARE audio songs for these (relaxed slightly to 1.3)
            shelfCopy['items'] = items.where((it) {
              if (it['type'] != 'song') return false;
              final data = it['data'] as Map<String, dynamic>;
              final w = data['thumbnailWidth'] as int? ?? 1;
              final h = data['thumbnailHeight'] as int? ?? 1;
              return (w / h) < 1.3; // Filter out very wide 16:9 videos
            }).toList();
          }
          finalShelves.add(shelfCopy);
        }
      }

      // 3. Post-process Music Videos (Rectangle check)
      final List<Map<String, dynamic>> musicVideoItems = [];
      final allCandidateShelves = [...mainModel.rawShelves, ...finalShelves];

      for (var shelf in allCandidateShelves) {
        final items = shelf['items'] as List<Map<String, dynamic>>;
        for (var item in items) {
          if (item['type'] == 'song') {
            final data = item['data'] as Map<String, dynamic>;
            final w = data['thumbnailWidth'] as int? ?? 1;
            final h = data['thumbnailHeight'] as int? ?? 1;
            if (w / h >= 1.3) musicVideoItems.add(item);
          }
        }
      }

      if (musicVideoItems.isNotEmpty) {
        finalShelves.add({
          'title': 'Music Videos',
          'section': 'musicVideos',
          'items': musicVideoItems.toSet().toList(),
        });
      }

      // 4. Merge all other shelves from main feed that aren't already there
      for (var shelf in mainModel.rawShelves) {
        final section = shelf['section'] as String;
        final title = shelf['title'] as String;

        // Skip if we already have this section or title
        bool alreadyExists = finalShelves.any(
          (s) => s['section'] == section || s['title'] == title,
        );

        if (!alreadyExists) {
          finalShelves.add(shelf);
        }
      }

      return HomeDataModel(
        rawShelves: finalShelves
            .where((s) => (s['items'] as List).isNotEmpty)
            .toList(),
        profileUrl: mainModel.profileUrl,
        ytName: mainModel.ytName,
      );
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchHomeData failed', e, st);
      return const HomeDataModel(rawShelves: []);
    }
  }

  HomeDataModel _parseHomeDataInternal(
    Map<String, dynamic> data, {
    String? forcedSectionType,
  }) {
    final List<Map<String, dynamic>> shelves = [];
    final contents = data['contents'];
    if (contents == null) return const HomeDataModel(rawShelves: []);

    List? sectionList =
        contents['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] ??
        contents['sectionListRenderer']?['contents'];

    if (sectionList == null) return const HomeDataModel(rawShelves: []);

    for (final section in sectionList) {
      final shelf =
          section['musicCarouselShelfRenderer'] ??
          section['musicShelfRenderer'] ??
          section['musicTastebuilderShelfRenderer'] ??
          section['gridRenderer'] ??
          section['itemSectionRenderer'];
      if (shelf == null) continue;

      final header =
          shelf['header']?['musicCarouselShelfBasicHeaderRenderer'] ??
          shelf['header']?['musicHeaderRenderer'] ??
          shelf['header']?['gridHeaderRenderer'];

      final title =
          header?['title']?['runs']?[0]?['text'] ??
          header?['title']?['simpleText'] ??
          shelf['primaryText']?['runs']?[0]?['text'] ??
          shelf['title']?['runs']?[0]?['text'] ??
          shelf['title']?['simpleText'];

      String sectionType = forcedSectionType ?? 'standard';
      if (forcedSectionType == null && title != null) {
        final t = title.toLowerCase();
        if (t.contains('listen again') || t.contains('recent'))
          sectionType = 'listeningAgain';
        else if (t.contains('quick picks') || t.contains('picks'))
          sectionType = 'quickPicks';
        else if (t.contains('music video') || t.contains('videos for you'))
          sectionType = 'musicVideos';
        else if (t.contains('album') || t.contains('spotlight'))
          sectionType = 'albumsForYou';
        else if (t.contains('podcast'))
          sectionType = 'podcasts';
        else if (t.contains('lofi') || t.contains('long listening'))
          sectionType = 'longListening';
      }

      final items = <Map<String, dynamic>>[];
      final contentList =
          (shelf['contents'] as List?) ??
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
    final renderer =
        item['musicTwoColumnItemRenderer'] ??
        item['musicResponsiveListItemRenderer'] ??
        item['musicItemRenderer'] ??
        item['musicPlaylistRenderer'] ??
        item['musicVideoRenderer'] ??
        item['gridVideoRenderer'] ??
        item['musicTwoRowItemRenderer'] ??
        item['playlistPanelVideoRenderer'];
    if (renderer == null) return null;

    String? title =
        renderer['title']?['runs']?[0]?['text'] ??
        renderer['title']?['simpleText'] ??
        renderer['text']?['runs']?[0]?['text'];

    String? subtitle;
    final subtitleRuns = renderer['subtitle']?['runs'] as List?;
    if (subtitleRuns != null) {
      subtitle = subtitleRuns
          .map((r) => r['text'])
          .where((t) => t != ' • ')
          .join('');
    } else {
      subtitle =
          renderer['subtitle']?['simpleText'] ??
          renderer['description']?['runs']?[0]?['text'] ??
          renderer['longBylineText']?['runs']?[0]?['text'];
    }

    final nav =
        renderer['navigationEndpoint'] ??
        renderer['onTap']?['navigationEndpoint'];
    String? videoId = nav?['watchEndpoint']?['videoId'] ?? renderer['videoId'];
    String? browseId =
        nav?['browseEndpoint']?['browseId'] ?? renderer['browseId'];

    // CRITICAL FIX: Add flexColumns support for search results
    if (item['musicResponsiveListItemRenderer'] != null) {
      final flexCols =
          item['musicResponsiveListItemRenderer']['flexColumns'] as List?;
      if (flexCols != null && flexCols.isNotEmpty) {
        final firstCol =
            flexCols[0]['musicResponsiveListItemFlexColumnRenderer'];
        title ??= firstCol?['text']?['runs']?[0]?['text'];
        videoId ??=
            firstCol?['text']?['runs']?[0]?['navigationEndpoint']?['watchEndpoint']?['videoId'];

        if (flexCols.length > 1) {
          final secondCol =
              flexCols[1]['musicResponsiveListItemFlexColumnRenderer'];
          final runs = secondCol?['text']?['runs'] as List?;
          if (runs != null) {
            subtitle ??= runs.map((r) => r['text']).join('');
            for (final run in runs) {
              final bId =
                  run['navigationEndpoint']?['browseEndpoint']?['browseId'];
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

    final thumbNode =
        renderer['thumbnailRenderer']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']
            ?.last ??
        renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']
            ?.last ??
        renderer['thumbnail']?['thumbnails']?.last;

    final thumb = thumbNode?['url'] as String?;
    final width = thumbNode?['width'] as int?;
    final height = thumbNode?['height'] as int?;

    String? highResThumb = thumb;
    if (thumb != null) {
      if (thumb.contains('googleusercontent.com') ||
          thumb.contains('ggpht.com')) {
        highResThumb = thumb.replaceAll(
          RegExp(r'=w\d+-h\d+.*'),
          '=w512-h512-l90-rj',
        );
        if (!highResThumb.contains('='))
          highResThumb = '$highResThumb=w512-h512-l90-rj';
      } else if (thumb.contains('ytimg.com') && videoId != null) {
        highResThumb = 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';
      }
    }

    if (videoId != null) {
      final views = _parseViews(renderer);
      return {
        'type': 'song',
        'data': {
          'id': videoId,
          'title': title,
          'artist': subtitle ?? 'Unknown Artist',
          'thumbnailUrl': highResThumb,
          'thumbnailWidth': width,
          'thumbnailHeight': height,
          'extras': views != null ? {'views': views} : null,
        },
      };
    } else if (browseId != null) {
      final isArtist = browseId.startsWith('UC') || browseId.startsWith('FBA');
      final isAlbum =
          browseId.startsWith('FEmusic_album') ||
          (subtitle?.toLowerCase().contains('album') ?? false);

      return {
        'type': isArtist ? 'artist' : (isAlbum ? 'album' : 'playlist'),
        'data': {
          'id': browseId,
          'name': title,
          'thumbnailUrl': highResThumb,
          'thumbnailWidth': width,
          'thumbnailHeight': height,
          'description': subtitle ?? '',
          'isAlbum': isAlbum,
        },
      };
    }
    return null;
  }

  int? _parseViews(dynamic renderer) {
    try {
      final flexColumns = renderer['flexColumns'] as List?;
      if (flexColumns == null || flexColumns.isEmpty) return null;

      // Views are usually in the 3rd column for responsive items
      String? viewText;
      if (flexColumns.length >= 3) {
        final col = flexColumns[2]['musicResponsiveListItemFlexColumnRenderer'];
        viewText = col?['text']?['runs']?[0]?['text'];
      }

      // Fallback: check subtitle if 3rd column didn't work
      if (viewText == null || !viewText.contains('play')) {
        final subtitleRuns = renderer['subtitle']?['runs'] as List?;
        if (subtitleRuns != null) {
          for (final run in subtitleRuns) {
            final t = run['text'] as String;
            if (t.contains('play') || t.contains('view')) {
              viewText = t;
              break;
            }
          }
        }
      }

      // Final fallback: check for explicit view count fields
      viewText ??=
          renderer['shortViewCountText']?['runs']?[0]?['text'] ??
          renderer['viewCountText']?['runs']?[0]?['text'] ??
          renderer['shortViewCountText']?['simpleText'] ??
          renderer['viewCountText']?['simpleText'];

      if (viewText == null) return null;
      return _parseViewCount(viewText);
    } catch (_) {
      return null;
    }
  }

  int? _parseViewCount(String text) {
    try {
      final clean = text
          .toLowerCase()
          .replaceAll('plays', '')
          .replaceAll('views', '')
          .replaceAll(' ', '')
          .trim();
      double multiplier = 1;
      String numberPart = clean;

      if (clean.endsWith('k')) {
        multiplier = 1000;
        numberPart = clean.substring(0, clean.length - 1);
      } else if (clean.endsWith('m')) {
        multiplier = 1000000;
        numberPart = clean.substring(0, clean.length - 1);
      } else if (clean.endsWith('b')) {
        multiplier = 1000000000;
        numberPart = clean.substring(0, clean.length - 1);
      }

      return (double.parse(numberPart) * multiplier).toInt();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SongModel>> searchSongs(String query, {int limit = 25}) async {
    try {
      // We try searching with the "Songs" filter first for quality,
      // but we will also look for "did you mean" or top results.
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

      // Navigate to contents
      final List<dynamic> contents =
          data['contents']?['tabbedSearchResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] ??
          [];

      for (final section in contents) {
        // 1. Regular Shelves (Songs, Videos, etc.)
        final shelf =
            section['musicShelfRenderer'] ?? section['musicCardShelfRenderer'];
        if (shelf != null) {
          for (final item in shelf['contents'] ?? []) {
            final mapped = _parseMytmItem(item);
            if (mapped != null && mapped['type'] == 'song') {
              final sData = mapped['data'] as Map<String, dynamic>;
              if (!tracks.any((t) => t.id == sData['id'])) {
                final colors = _colorsForId(sData['id']);
                tracks.add(
                  SongModel(
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
                    extras: sData['extras'] as Map<String, dynamic>?,
                  ),
                );
              }
            }
          }
        }

        // 2. Item Sections (Top result, Corrections)
        final itemSection = section['itemSectionRenderer'];
        if (itemSection != null) {
          for (final item in itemSection['contents'] ?? []) {
            final mapped = _parseMytmItem(item);
            if (mapped != null && mapped['type'] == 'song') {
              // ... same addition logic as above ...
              final sData = mapped['data'] as Map<String, dynamic>;
              if (!tracks.any((t) => t.id == sData['id'])) {
                final colors = _colorsForId(sData['id']);
                tracks.add(
                  SongModel(
                    id: sData['id'],
                    title: sData['title'],
                    artist: sData['artist'],
                    album: '',
                    duration: Duration.zero,
                    thumbnailUrl: sData['thumbnailUrl'],
                    colorPrimary: colors.$1,
                    colorSecondary: colors.$2,
                    extras: sData['extras'] as Map<String, dynamic>?,
                  ),
                );
              }
            }
          }
        }
      }

      // Removed re-ordering to keep "Best Match" first as per user request
      /*
      tracks.sort((a, b) {
        final vA = a.extras?['views'] as int? ?? 0;
        final vB = b.extras?['views'] as int? ?? 0;
        return vB.compareTo(vA);
      });
      */

      return tracks.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<PlaylistModel>> fetchPlaylists() async {
    final List<PlaylistModel> allPlaylists = [];
    try {
      final locals = LocalStorage.instance.localPlaylists;
      for (final l in locals)
        allPlaylists.add(PlaylistModel.fromJson({...l, 'type': 'local'}));
    } catch (_) {}
    return allPlaylists;
  }

  @override
  Future<List<SongModel>> fetchPlaylistTracks(
    String playlistId, {
    int limit = 100,
  }) async {
    try {
      final playlist = await _ytExplode.playlists.get(playlistId);
      final List<Video> videos = await _ytExplode.playlists
          .getVideos(playlistId)
          .take(limit)
          .toList();
      final tracks = <SongModel>[];
      for (final v in videos) {
        final colors = _colorsForId(v.id.value);
        tracks.add(
          SongModel(
            id: v.id.value,
            title: v.title,
            artist: v.author,
            album: playlist.title,
            duration: v.duration ?? Duration.zero,
            thumbnailUrl: v.thumbnails.highResUrl,
            colorPrimary: colors.$1,
            colorSecondary: colors.$2,
          ),
        );
      }
      return tracks;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<SongModel>> fetchAlbumTracks(
    String browseId, {
    int limit = 25,
  }) async {
    try {
      final response = await _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {"browseId": browseId, "context": _context},
      );
      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      final List<dynamic> contents =
          data['contents']?['twoColumnBrowseResultsRenderer']?['secondaryContents']?['sectionListRenderer']?['contents'] ??
          [];
      final shelf = contents.firstOrNull?['musicShelfRenderer'];
      if (shelf == null) return [];
      final tracks = <SongModel>[];
      for (final item in shelf['contents'] as List? ?? []) {
        final mapped = _parseMytmItem(item);
        if (mapped != null && mapped['type'] == 'song') {
          final sData = mapped['data'] as Map<String, dynamic>;
          final colors = _colorsForId(sData['id']);
          tracks.add(
            SongModel(
              id: sData['id'],
              title: sData['title'],
              artist: sData['artist'],
              album: '',
              duration: Duration.zero,
              thumbnailUrl: sData['thumbnailUrl'],
              colorPrimary: colors.$1,
              colorSecondary: colors.$2,
            ),
          );
        }
      }
      return tracks.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<SongModel>> fetchArtistSongs(String channelId) async {
    try {
      final response = await _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {"browseId": channelId, "context": _context},
      );
      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      final sectionList =
          data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents']
              as List?;
      if (sectionList == null) return [];
      final tracks = <SongModel>[];
      for (final section in sectionList) {
        final shelf =
            section['musicShelfRenderer'] ??
            section['musicCarouselShelfRenderer'];
        if (shelf == null) continue;
        for (final item in shelf['contents'] as List? ?? []) {
          final mapped = _parseMytmItem(item);
          if (mapped != null && mapped['type'] == 'song') {
            final sData = mapped['data'] as Map<String, dynamic>;
            final colors = _colorsForId(sData['id']);
            tracks.add(
              SongModel(
                id: sData['id'],
                title: sData['title'],
                artist: sData['artist'],
                album: '',
                duration: Duration.zero,
                thumbnailUrl: sData['thumbnailUrl'],
                colorPrimary: colors.$1,
                colorSecondary: colors.$2,
              ),
            );
          }
        }
      }
      return tracks;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<SongModel>> fetchRadioTracks(
    String videoId, {
    int limit = 25,
  }) async {
    try {
      final response = await _dio.post(
        '$_ytmBase/next?prettyPrint=false',
        data: {
          "videoId": videoId,
          "playlistId": "RDAMVM$videoId",
          "context": _context,
        },
      );
      if (response.statusCode != 200) return [];
      final data = response.data as Map<String, dynamic>;
      final watchNext =
          data['contents']?['singleColumnMusicWatchNextResultsRenderer'] ??
          data['contents']?['twoColumnWatchNextResultsRenderer'];
      if (watchNext == null) return [];
      final contents =
          watchNext['content']?['musicQueueRenderer']?['content']?['playlistPanelRenderer']?['contents']
              as List?;
      if (contents == null) return [];
      final tracks = <SongModel>[];
      for (final item in contents) {
        final mapped = _parseMytmItem(item);
        if (mapped != null && mapped['type'] == 'song') {
          final sData = mapped['data'] as Map<String, dynamic>;
          if (sData['id'] == videoId) continue;
          final colors = _colorsForId(sData['id']);
          tracks.add(
            SongModel(
              id: sData['id'],
              title: sData['title'],
              artist: sData['artist'],
              album: '',
              duration: Duration.zero,
              thumbnailUrl: sData['thumbnailUrl'],
              colorPrimary: colors.$1,
              colorSecondary: colors.$2,
            ),
          );
        }
      }
      return tracks;
    } catch (e) {
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
        songs.add(
          SongModel(
            id: v.id.value,
            title: v.title,
            artist: v.author,
            album: '',
            duration: v.duration ?? Duration.zero,
            thumbnailUrl: v.thumbnails.highResUrl,
            colorPrimary: colors.$1,
            colorSecondary: colors.$2,
          ),
        );
      } catch (_) {}
    }
    return songs;
  }

  @override
  Future<void> prefetchAudio(String videoId) async {
    await _resolver.resolveYoutubeStream(videoId);
  }

  @override
  Future<void> recordPlay(SongModel song) async {
    try {
      final storage = LocalStorage.instance;
      storage.saveCachedMetadata('song_meta_${song.id}', song.toJson());
      final history =
          storage.getCachedMetadata('persistent_history_events') as List? ?? [];
      if (history.length > 200) history.removeAt(0);
      history.add({'id': song.id, 'ts': DateTime.now().millisecondsSinceEpoch});
      storage.saveCachedMetadata('persistent_history_events', history);
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>> fetchPersistentHistory() async {
    try {
      final storage = LocalStorage.instance;
      final history =
          storage.getCachedMetadata('persistent_history_events') as List? ?? [];
      final now = DateTime.now();
      final today = <SongModel>[];
      final thisWeek = <SongModel>[];
      final thisMonth = <SongModel>[];
      final processedIds = <String>{};
      for (final event in history.reversed) {
        final id = event['id'] as String;
        if (!processedIds.add(id)) continue;
        final songData = storage.getCachedMetadata('song_meta_$id');
        if (songData == null) continue;
        final song = SongModel.fromJson(
          Map<String, dynamic>.from(songData as Map),
        );
        final ts = DateTime.fromMillisecondsSinceEpoch(event['ts'] as int);
        final diff = now.difference(ts);
        if (diff.inDays == 0 && now.day == ts.day)
          today.add(song);
        else if (diff.inDays < 7)
          thisWeek.add(song);
        else if (diff.inDays < 30)
          thisMonth.add(song);
      }
      return {
        'today': today.map((s) => s.toJson()).toList(),
        'thisWeek': thisWeek.map((s) => s.toJson()).toList(),
        'thisMonth': thisMonth.map((s) => s.toJson()).toList(),
      };
    } catch (_) {
      return {};
    }
  }

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
      final details = {'videoId': videoId};
      final sectionList =
          data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents']
              as List?;
      if (sectionList != null) {
        for (final section in sectionList) {
          final shelf = section['musicDescriptionShelfRenderer'];
          if (shelf != null) {
            details['description'] = shelf['description']?['runs']?[0]?['text'];
            break;
          }
        }
      }
      return details;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> fetchArtistDetails(String browseId) async {
    try {
      final response = await _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {"browseId": browseId, "context": _context},
      );
      final data = response.data as Map<String, dynamic>;
      final details = {'browseId': browseId};
      final header =
          data['header']?['musicImmersiveHeaderRenderer'] ??
          data['header']?['musicVisualHeaderRenderer'];
      if (header != null) {
        details['name'] = header['title']?['runs']?[0]?['text'];
        details['thumbnailUrl'] =
            header['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']
                ?.last?['url'];
      }
      return details;
    } catch (_) {
      return {};
    }
  }

  @override
  List<Map<String, dynamic>> fetchCategories() {
    return [
      {
        'name': 'Chill',
        'params': 'EgWKAQIIAWoQEAMQBBAJEAoQCxAEEAoQAA==',
        'color': 0xFF7C3AED,
      },
      {
        'name': 'Energy',
        'params': 'EgWKAQIIAWoQEAMQBBAJEAoQCxAEEAoQAA==',
        'color': 0xFFEF4444,
      },
    ];
  }

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
  Future<void> likeArtist(String channelId) async {}
  @override
  Future<void> unlikeArtist(String channelId) async {}
  @override
  Future<PlaylistModel> createFlowPlaylist({
    required String title,
    String description = '',
    bool isPublic = false,
  }) async => PlaylistModel(
    id: '',
    name: title,
    description: description,
    color: const Color(0xFF7C3AED),
  );
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
  @override
  Future<void> deleteFlowPlaylist(String playlistId) async {}
  @override
  Future<void> addTrackToFlowPlaylist(
    String playlistId,
    Map<String, dynamic> songData,
  ) async {}
  @override
  Future<void> removeTrackFromFlowPlaylist(
    String playlistId,
    int trackId,
  ) async {}
  @override
  Future<void> addCollaborator(String playlistId, String userCode) async {}
  @override
  Future<void> removeCollaborator(String playlistId, String userCode) async {}

  Future<List<Map<String, dynamic>>> _fetchShelf(
    String browseId, {
    String? params,
    String? forcedSection,
  }) async {
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
      return _parseHomeDataInternal(
        response.data as Map<String, dynamic>,
        forcedSectionType: forcedSection,
      ).rawShelves;
    } catch (_) {
      return [];
    }
  }

  static (Color, Color) _colorsForId(String id) {
    final hash = id.codeUnits.fold(0, (a, b) => a + b);
    final pairs = [
      (const Color(0xFF7C3AED), const Color(0xFF2563EB)),
      (const Color(0xFFEC4899), const Color(0xFFEF4444)),
    ];
    return pairs[hash % pairs.length];
  }
}
