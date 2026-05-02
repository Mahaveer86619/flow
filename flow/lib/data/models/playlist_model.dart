import 'package:flutter/material.dart' show Color;
import '../../domain/entities/song.dart';
import 'song_model.dart';

class PlaylistModel {
  final String id;
  final String name;
  final String description;
  final List<SongModel>? songs;
  final int? trackCount;
  final Color color;
  final String? thumbnailUrl;
  final String type;
  final bool isAlbum;
  final String? artistName;
  final String? ownerCode;

  const PlaylistModel({
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

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      songs: (json['songs'] as List<dynamic>?)
          ?.map((s) => SongModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      trackCount: json['trackCount'] as int?,
      color: Color(json['color'] as int? ?? 0xFF7C3AED),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      type: json['type'] as String? ?? 'yt',
      isAlbum: json['isAlbum'] as bool? ?? false,
      artistName: json['artistName'] as String?,
      ownerCode: json['ownerCode'] as String?,
    );
  }

  factory PlaylistModel.fromEntity(Playlist p) {
    return PlaylistModel(
      id: p.id,
      name: p.name,
      description: p.description,
      songs: p.songs?.map((s) => SongModel.fromEntity(s)).toList(),
      trackCount: p.trackCount,
      color: p.color,
      thumbnailUrl: p.thumbnailUrl,
      type: p.type,
      isAlbum: p.isAlbum,
      artistName: p.artistName,
      ownerCode: p.ownerCode,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'songs': songs?.map((s) => s.toJson()).toList(),
    'trackCount': trackCount,
    'color': color.toARGB32(),
    'thumbnailUrl': thumbnailUrl,
    'type': type,
    'isAlbum': isAlbum,
    'artistName': artistName,
    'ownerCode': ownerCode,
  };

  Playlist toEntity() {
    return Playlist(
      id: id,
      name: name,
      description: description,
      songs: songs?.map((m) => m.toEntity()).toList(),
      trackCount: trackCount,
      color: color,
      thumbnailUrl: thumbnailUrl,
      type: type,
      isAlbum: isAlbum,
      artistName: artistName,
      ownerCode: ownerCode,
    );
  }
}
