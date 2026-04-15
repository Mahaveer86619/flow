import 'package:flutter/material.dart';
import '../../domain/entities/song.dart';

// ── Data Transfer Object ──────────────────────────────────────────────────────
//
// PlaylistModel handles the normalised playlist shape from the backend:
//   { id, name, description, thumbnailUrl, trackCount }
//
// Songs are NOT embedded in library listings — they are fetched separately
// when the user opens a playlist (/api/playlists/{id}/tracks).
// ─────────────────────────────────────────────────────────────────────────────

class PlaylistModel {
  final String id;
  final String name;
  final String description;
  final String? thumbnailUrl;
  final int trackCount;
  final Color color;
  final String type;
  final bool isAlbum;
  final String? artistName;
  final String? ownerCode;

  const PlaylistModel({
    required this.id,
    required this.name,
    required this.description,
    this.thumbnailUrl,
    this.trackCount = 0,
    required this.color,
    this.type = 'yt',
    this.isAlbum = false,
    this.artistName,
    this.ownerCode,
  });

  // ── JSON ─────────────────────────────────────────────────────────────────────

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    return PlaylistModel(
      id: id,
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      trackCount: (json['trackCount'] as num?)?.toInt() ?? 0,
      color: json['color'] != null
          ? Color(json['color'] as int)
          : _colorForId(id),
      type: json['type'] as String? ?? 'yt',
      isAlbum: json['isAlbum'] as bool? ?? false,
      artistName: json['artistName'] as String?,
      ownerCode: json['ownerCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'thumbnailUrl': thumbnailUrl,
        'trackCount': trackCount,
        'color': color.value,
        'type': type,
        'isAlbum': isAlbum,
        'artistName': artistName,
        'ownerCode': ownerCode,
      };

  // ── Domain mapping ────────────────────────────────────────────────────────────

  Playlist toEntity() => Playlist(
        id: id,
        name: name,
        description: description,
        songs: const [],
        color: color,
        thumbnailUrl: thumbnailUrl,
        type: type,
        isAlbum: isAlbum,
        artistName: artistName,
        ownerCode: ownerCode,
      );

  // ── Color derivation ──────────────────────────────────────────────────────────

  static const _colors = [
    Color(0xFF1E40AF),
    Color(0xFF059669),
    Color(0xFFDC2626),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFFD97706),
    Color(0xFF9333EA),
    Color(0xFF0F766E),
  ];

  static Color _colorForId(String id) {
    final hash = id.codeUnits.fold(0, (a, b) => a + b);
    return _colors[hash % _colors.length];
  }
}
