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

  /// Placeholder gradient colors used until real artwork URLs are available.
  final Color colorPrimary;
  final Color colorSecondary;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.colorPrimary,
    required this.colorSecondary,
  });
}

class Playlist {
  final String id;
  final String name;
  final String description;
  final List<Song> songs;
  final Color color;

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.songs,
    required this.color,
  });
}
