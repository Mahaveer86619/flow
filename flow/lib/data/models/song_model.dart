import 'package:flutter/material.dart' show Color;
import '../../domain/entities/song.dart';

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
  final Map<String, dynamic>? extras;
  final String source; // 'yt' or 'ytm'

  const SongModel({
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
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String? ?? '',
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      thumbnailWidth: json['thumbnailWidth'] as int?,
      thumbnailHeight: json['thumbnailHeight'] as int?,
      colorPrimary: Color(json['colorPrimary'] as int? ?? 0xFF7C3AED),
      colorSecondary: Color(json['colorSecondary'] as int? ?? 0xFFBC9AFF),
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      extras: json['extras'] as Map<String, dynamic>?,
      source: json['source'] as String? ?? 'ytm',
    );
  }

  factory SongModel.fromEntity(Song s) {
    return SongModel(
      id: s.id,
      title: s.title,
      artist: s.artist,
      album: s.album,
      duration: s.duration,
      thumbnailUrl: s.thumbnailUrl,
      thumbnailWidth: s.thumbnailWidth,
      thumbnailHeight: s.thumbnailHeight,
      colorPrimary: s.colorPrimary,
      colorSecondary: s.colorSecondary,
      isDownloaded: s.isDownloaded,
      extras: s.extras,
      source: s.source,
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
    'colorPrimary': colorPrimary.toARGB32(),
    'colorSecondary': colorSecondary.toARGB32(),
    'isDownloaded': isDownloaded,
    'extras': extras,
    'source': source,
  };

  Song toEntity() {
    return Song(
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
      extras: extras,
      source: source,
    );
  }
}
