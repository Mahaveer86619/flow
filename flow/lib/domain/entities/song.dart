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

  /// Gradient fallback colors used when [thumbnailUrl] is null or fails to load.
  final Color colorPrimary;
  final Color colorSecondary;

  final bool isDownloaded;

  /// Timestamp when the song was last played (for history).
  final DateTime? playedAt;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.thumbnailUrl,
    required this.colorPrimary,
    required this.colorSecondary,
    this.isDownloaded = false,
    this.playedAt,
  });

  Song copyWith({bool? isDownloaded, DateTime? playedAt}) {
    return Song(
      id: id,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      thumbnailUrl: thumbnailUrl,
      colorPrimary: colorPrimary,
      colorSecondary: colorSecondary,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      playedAt: playedAt ?? this.playedAt,
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

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.songs,
    required this.color,
    this.thumbnailUrl,
  });
}
