import 'dart:ui' show Color;

// ── Domain Entities ───────────────────────────────────────────────────────────
//
// Pure business objects. No Flutter widget dependencies — only dart:ui Color,
// which is engine-level and safe in the domain layer.
//
// These are the canonical types passed between all three layers.
// The data layer maps network/DB models TO these. The presentation layer
// reads FROM these — never the other way around.
// ─────────────────────────────────────────────────────────────────────────────

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;

  /// Remote thumbnail URL from the backend. Null for mock / offline songs.
  final String? thumbnailUrl;
  final int? thumbnailWidth;
  final int? thumbnailHeight;

  /// Gradient fallback colors used when [thumbnailUrl] is null or fails to load.
  final Color colorPrimary;
  final Color colorSecondary;

  final bool isDownloaded;

  /// Timestamp when the song was last played (for history).
  final DateTime? playedAt;

  /// Additional metadata like artist biography, related info, etc.
  final Map<String, dynamic>? extras;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.thumbnailUrl,
    this.thumbnailWidth,
    this.thumbnailHeight,
    required this.colorPrimary,
    required this.colorSecondary,
    this.isDownloaded = false,
    this.playedAt,
    this.extras,
  });

  Song copyWith({
    bool? isDownloaded,
    DateTime? playedAt,
    Map<String, dynamic>? extras,
    int? thumbnailWidth,
    int? thumbnailHeight,
  }) {
    return Song(
      id: id,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      thumbnailUrl: thumbnailUrl,
      thumbnailWidth: thumbnailWidth ?? this.thumbnailWidth,
      thumbnailHeight: thumbnailHeight ?? this.thumbnailHeight,
      colorPrimary: colorPrimary,
      colorSecondary: colorSecondary,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      playedAt: playedAt ?? this.playedAt,
      extras: extras ?? this.extras,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Song(id: $id, title: $title, artist: $artist)';
}

class Playlist {
  final String id;
  final String name;
  final String description;
  final List<Song> songs;
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
    required this.songs,
    required this.color,
    this.thumbnailUrl,
    this.type = 'yt',
    this.isAlbum = false,
    this.artistName,
    this.ownerCode,
  });
}
