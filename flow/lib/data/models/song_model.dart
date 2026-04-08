import 'package:flutter/material.dart';
import '../../domain/entities/song.dart';

// ── Data Transfer Object ──────────────────────────────────────────────────────
//
// SongModel is the data-layer representation of a song.
// It owns serialization concerns (fromJson / toJson) so the domain entity
// stays clean.  toEntity() converts to the domain Song for use in business
// logic and presentation.
//
// When a real API is connected:
//   - Populate fromJson() from the API response schema.
//   - The rest of the app changes nothing — domain and presentation are
//     insulated by the repository + use-case boundaries.
// ─────────────────────────────────────────────────────────────────────────────

class SongModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final Color colorPrimary;
  final Color colorSecondary;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.colorPrimary,
    required this.colorSecondary,
  });

  // ── JSON ─────────────────────────────────────────────────────────────────────

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      duration: Duration(milliseconds: json['durationMs'] as int),
      colorPrimary: Color(json['colorPrimary'] as int),
      colorSecondary: Color(json['colorSecondary'] as int),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'durationMs': duration.inMilliseconds,
    'colorPrimary': colorPrimary.value,
    'colorSecondary': colorSecondary.value,
  };

  // ── Domain mapping ────────────────────────────────────────────────────────────

  Song toEntity() => Song(
    id: id,
    title: title,
    artist: artist,
    album: album,
    duration: duration,
    colorPrimary: colorPrimary,
    colorSecondary: colorSecondary,
  );
}
