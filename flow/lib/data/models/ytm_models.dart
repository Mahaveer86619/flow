import 'package:flutter/foundation.dart';

/// Represents a standardized item from YouTube Music (Song, Album, Playlist, Artist).
@immutable
class YtmItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? artist;
  final String? album;
  final String? duration;
  final String? thumbnailUrl;
  final YtmItemType type;
  final Map<String, dynamic> raw;

  const YtmItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.artist,
    this.album,
    this.duration,
    this.thumbnailUrl,
    required this.type,
    this.raw = const {},
  });
}

enum YtmItemType { song, album, playlist, artist, video }

/// Represents a collection of items (e.g., a row on the home feed).
@immutable
class YtmShelf {
  final String title;
  final List<YtmItem> items;
  final String? browseId;
  final String sectionType;

  const YtmShelf({
    required this.title,
    required this.items,
    this.browseId,
    required this.sectionType,
  });
}

/// Represents the Home Feed structure.
@immutable
class YtmHomeFeed {
  final List<YtmShelf> shelves;
  final String? visitorData;

  const YtmHomeFeed({required this.shelves, this.visitorData});
}
