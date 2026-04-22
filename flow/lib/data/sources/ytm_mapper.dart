import 'dart:ui';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../models/home_data_model.dart';
import 'ytm_models.dart';

class YtmMapper {
  /// Maps an internal [YtmItem] to the app's [SongModel].
  static SongModel toSongModel(YtmItem item) {
    return SongModel(
      id: item.id,
      title: item.title,
      artist: item.artist ?? item.subtitle ?? 'Unknown Artist',
      album: item.album ?? '',
      duration: _parseDuration(item.duration),
      thumbnailUrl: item.thumbnailUrl,
      colorPrimary: const Color(
        0xFF7C3AED,
      ), // Default, will be derived by model
      colorSecondary: const Color(0xFF2563EB),
    );
  }

  /// Maps an internal [YtmItem] to the app's [PlaylistModel].
  static PlaylistModel toPlaylistModel(YtmItem item) {
    return PlaylistModel(
      id: item.id,
      name: item.title,
      owner: item.artist ?? item.subtitle ?? 'YouTube Music',
      thumbnailUrl: item.thumbnailUrl,
      songCount: 0, // Not always available in list view
    );
  }

  /// Maps an internal [YtmShelf] to a format suitable for [HomeDataModel].
  static Map<String, dynamic> shelfToRaw(YtmShelf shelf) {
    return {
      'title': shelf.title,
      'section': shelf.sectionType,
      'items': shelf.items.map((item) {
        return {
          'type': item.type.name,
          'data': item.type == YtmItemType.song
              ? toSongModel(item).toJson()
              : toPlaylistModel(item).toJson(),
        };
      }).toList(),
    };
  }

  static Duration _parseDuration(String? duration) {
    if (duration == null) return Duration.zero;
    final parts = duration.split(':');
    if (parts.length == 2) {
      return Duration(
        minutes: int.tryParse(parts[0]) ?? 0,
        seconds: int.tryParse(parts[1]) ?? 0,
      );
    } else if (parts.length == 3) {
      return Duration(
        hours: int.tryParse(parts[0]) ?? 0,
        minutes: int.tryParse(parts[1]) ?? 0,
        seconds: int.tryParse(parts[2]) ?? 0,
      );
    }
    return Duration.zero;
  }

  // --- Parser logic (to be filled during research) ---

  static YtmItem? parseItemRenderer(Map<String, dynamic> renderer) {
    final Map<String, dynamic> data =
        renderer['musicTwoRowItemRenderer'] ??
        renderer['musicResponsiveListItemRenderer'] ??
        renderer['musicItemRenderer'] ??
        renderer['musicMultiRowListItemRenderer'] ??
        renderer['musicVideoRenderer'] ??
        renderer['playlistPanelVideoRenderer'] ??
        {};

    if (data.isEmpty) return null;

    // 1. Extract Title
    String? title =
        _runText(data['title']) ??
        _runText(data['text']) ??
        data['title']?['simpleText'];
    if (title == null) {
      // musicResponsiveListItemRenderer specific
      final flexCols = data['flexColumns'] as List?;
      if (flexCols != null && flexCols.isNotEmpty) {
        final firstCol =
            flexCols[0]['musicResponsiveListItemFlexColumnRenderer'];
        title = _runText(firstCol?['text']);
      }
    }
    if (title == null) return null;

    // 2. Extract IDs
    final nav =
        data['navigationEndpoint'] ?? data['onTap']?['navigationEndpoint'];
    String? videoId =
        nav?['watchEndpoint']?['videoId'] ??
        data['videoId'] ??
        data['playlistItemData']?['videoId'];
    String? browseId = nav?['browseEndpoint']?['browseId'] ?? data['browseId'];

    // 3. Extract Subtitle/Artist
    String? subtitle =
        _runText(data['subtitle']) ??
        _runText(data['longBylineText']) ??
        _runText(data['shortBylineText']);
    if (subtitle == null) {
      final flexCols = data['flexColumns'] as List?;
      if (flexCols != null && flexCols.length > 1) {
        final secondCol =
            flexCols[1]['musicResponsiveListItemFlexColumnRenderer'];
        subtitle = _runText(secondCol?['text']);
        browseId ??= _runBrowseId(secondCol?['text']);
      }
    }

    // 4. Extract Thumbnail
    final thumbnails =
        data['thumbnailRenderer']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] ??
        data['thumbnail']?['thumbnails'] ??
        data['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'];

    String? thumb = (thumbnails as List?)?.last?['url'];
    if (thumb != null) {
      if (thumb.contains('=w') && thumb.contains('-h')) {
        thumb = thumb.replaceAll(
          RegExp(r'=w\d+-h\d+.*'),
          '=w512-h512-p-l90-rj',
        );
      } else if (thumb.contains('ytimg.com') && videoId != null) {
        thumb = 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
      }
    }

    // 5. Determine Type
    YtmItemType type = YtmItemType.song;
    if (videoId != null) {
      type = YtmItemType.song;
    } else if (browseId != null) {
      if (browseId.startsWith('UC') || browseId.startsWith('FBA')) {
        type = YtmItemType.artist;
      } else if (browseId.startsWith('MPREb') ||
          browseId.startsWith('FEmusic_album')) {
        type = YtmItemType.album;
      } else {
        type = YtmItemType.playlist;
      }
    }

    return YtmItem(
      id: videoId ?? browseId ?? '',
      title: title,
      subtitle: subtitle,
      thumbnailUrl: thumb,
      type: type,
      raw: renderer,
    );
  }

  static String? _runText(dynamic runNode) {
    if (runNode == null) return null;
    final runs = runNode['runs'] as List?;
    if (runs != null && runs.isNotEmpty) {
      return runs.map((r) => r['text']).join('');
    }
    return runNode['simpleText'];
  }

  static String? _runBrowseId(dynamic runNode) {
    if (runNode == null) return null;
    final runs = runNode['runs'] as List?;
    if (runs != null) {
      for (final r in runs) {
        final bId = r['navigationEndpoint']?['browseEndpoint']?['browseId'];
        if (bId != null) return bId;
      }
    }
    return null;
  }
}
