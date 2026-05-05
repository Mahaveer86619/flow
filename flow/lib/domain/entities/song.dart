import 'dart:ui' show Color;

// ── Domain Entities ──────────────────────────────────────────────────────────
//
// These are "pure" Dart objects representing the core business data.
// They don't know about JSON, Hive, or InnerTube.
// ─────────────────────────────────────────────────────────────────────────────

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String? thumbnailUrl;
  final int? thumbnailWidth;
  final int? thumbnailHeight;
  final Color colorPrimary;
  final Color colorSecondary;
  final bool isDownloaded;
  final Map<String, dynamic>? extras;
  final String source; // 'yt' or 'ytm'
  final DateTime? playedAt;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.thumbnailUrl,
    this.thumbnailWidth,
    this.thumbnailHeight,
    this.colorPrimary = const Color(0xFF7C3AED),
    this.colorSecondary = const Color(0xFFBC9AFF),
    this.isDownloaded = false,
    this.extras,
    this.source = 'ytm',
    this.playedAt,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? thumbnailUrl,
    int? thumbnailWidth,
    int? thumbnailHeight,
    Color? colorPrimary,
    Color? colorSecondary,
    bool? isDownloaded,
    Map<String, dynamic>? extras,
    String? source,
    DateTime? playedAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      thumbnailWidth: thumbnailWidth ?? this.thumbnailWidth,
      thumbnailHeight: thumbnailHeight ?? this.thumbnailHeight,
      colorPrimary: colorPrimary ?? this.colorPrimary,
      colorSecondary: colorSecondary ?? this.colorSecondary,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      extras: extras ?? this.extras,
      source: source ?? this.source,
      playedAt: playedAt ?? this.playedAt,
    );
  }
}

class Playlist {
  final String id;
  final String name;
  final String description;
  final List<Song>? songs;
  final int? trackCount;
  final Color color;

  /// Remote thumbnail URL from the backend.
  final String? thumbnailUrl;

  /// 'flow' for user-created playlists stored in our DB, 'yt' for YouTube Music playlists.
  final String type;

  /// True when this entry represents a YT Music album/single/EP rather than a playlist.
  final bool isAlbum;

  /// Primary artist name — populated for albums.
  final String? artistName;

  /// The owner's user code (e.g. "mahaveer#1234") — populated for Flow playlists.
  final String? ownerCode;

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    this.songs,
    this.trackCount,
    required this.color,
    this.thumbnailUrl,
    this.type = 'yt',
    this.isAlbum = false,
    this.artistName,
    this.ownerCode,
  });
}
