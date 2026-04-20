import 'package:flutter/material.dart';
import '../../domain/entities/song.dart';

// ── Data Transfer Object ──────────────────────────────────────────────────────
//
// SongModel is the data-layer representation of a song.
// It owns serialization concerns (fromJson / toJson) so the domain entity
// stays clean.  toEntity() converts to the domain Song for use in business
// logic and presentation.
//
// fromJson handles the normalised shape produced by the backend:
//   { id, title, artist, album, durationMs, thumbnailUrl }
//
// colorPrimary / colorSecondary are derived deterministically from [id] when
// the API does not supply them (i.e. always for live data).
// ─────────────────────────────────────────────────────────────────────────────

class SongModel {
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
  final DateTime? playedAt;
  final Map<String, dynamic>? extras;

  const SongModel({
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

  // ── JSON ─────────────────────────────────────────────────────────────────────

  factory SongModel.fromEntity(Song song) {
    return SongModel(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: song.duration,
      thumbnailUrl: song.thumbnailUrl,
      thumbnailWidth: song.thumbnailWidth,
      thumbnailHeight: song.thumbnailHeight,
      colorPrimary: song.colorPrimary,
      colorSecondary: song.colorSecondary,
      isDownloaded: song.isDownloaded,
      playedAt: song.playedAt,
      extras: song.extras,
    );
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final colors = _colorsForId(id);
    return SongModel(
      id: id,
      title: json['title'] as String? ?? 'Unknown',
      artist: json['artist'] as String? ?? 'Unknown',
      album: json['album'] as String? ?? '',
      duration: Duration(
        milliseconds:
            (json['durationMs'] as num?)?.toInt() ??
            (json['duration'] as num?)?.toInt() ??
            0,
      ),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      thumbnailWidth: json['thumbnailWidth'] as int?,
      thumbnailHeight: json['thumbnailHeight'] as int?,
      colorPrimary: json['colorPrimary'] != null
          ? Color(json['colorPrimary'] as int)
          : colors.$1,
      colorSecondary: json['colorSecondary'] != null
          ? Color(json['colorSecondary'] as int)
          : colors.$2,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      playedAt: json['playedAt'] != null
          ? DateTime.tryParse(json['playedAt'] as String)
          : null,
      extras: json['extras'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'durationMs': duration.inMilliseconds,
    'thumbnailUrl': thumbnailUrl,
    'thumbnailWidth': thumbnailWidth,
    'thumbnailHeight': thumbnailHeight,
    'colorPrimary': colorPrimary.value,
    'colorSecondary': colorSecondary.value,
    'isDownloaded': isDownloaded,
    'playedAt': playedAt?.toIso8601String(),
    if (extras != null) 'extras': extras,
  };

  // ── Domain mapping ────────────────────────────────────────────────────────────

  Song toEntity() => Song(
    id: id,
    title: title,
    artist: artist,
    album: album,
    duration: duration,
    thumbnailUrl: thumbnailUrl,
    thumbnailWidth: thumbnailWidth,
    thumbnailHeight: thumbnailHeight,
    colorPrimary: colorPrimary,
    colorSecondary: colorSecondary,
    isDownloaded: isDownloaded,
    playedAt: playedAt,
    extras: extras,
  );

  // ── Color derivation ──────────────────────────────────────────────────────────

  static const _colorPairs = [
    (Color(0xFF7C3AED), Color(0xFF2563EB)),
    (Color(0xFFEC4899), Color(0xFFEF4444)),
    (Color(0xFF059669), Color(0xFF0891B2)),
    (Color(0xFFF59E0B), Color(0xFFEF4444)),
    (Color(0xFF6366F1), Color(0xFF8B5CF6)),
    (Color(0xFF0284C7), Color(0xFF059669)),
    (Color(0xFFDB2777), Color(0xFF9333EA)),
    (Color(0xFF14B8A6), Color(0xFF0F766E)),
    (Color(0xFF8B5CF6), Color(0xFF4C1D95)),
    (Color(0xFFE879F9), Color(0xFFBE185D)),
  ];

  static (Color, Color) _colorsForId(String id) {
    final hash = id.codeUnits.fold(0, (a, b) => a + b);
    return _colorPairs[hash % _colorPairs.length];
  }
}
