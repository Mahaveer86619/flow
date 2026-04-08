import 'package:flutter/material.dart';
import '../../domain/entities/song.dart';
import 'song_model.dart';

// ── Data Transfer Object ──────────────────────────────────────────────────────
//
// PlaylistModel mirrors SongModel's pattern: owns JSON serialization and
// converts to the domain Playlist entity via toEntity().
// ─────────────────────────────────────────────────────────────────────────────

class PlaylistModel {
  final String id;
  final String name;
  final String description;
  final List<SongModel> songs;
  final Color color;

  const PlaylistModel({
    required this.id,
    required this.name,
    required this.description,
    required this.songs,
    required this.color,
  });

  // ── JSON ─────────────────────────────────────────────────────────────────────

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      songs: (json['songs'] as List<dynamic>)
          .map((s) => SongModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      color: Color(json['color'] as int),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'songs': songs.map((s) => s.toJson()).toList(),
    'color': color.value,
  };

  // ── Domain mapping ────────────────────────────────────────────────────────────

  Playlist toEntity() => Playlist(
    id: id,
    name: name,
    description: description,
    songs: songs.map((s) => s.toEntity()).toList(),
    color: color,
  );
}
