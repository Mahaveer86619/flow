import 'package:flutter/material.dart';
import '../../domain/entities/home_data.dart';
import 'playlist_model.dart';
import 'song_model.dart';

class HomeDataModel {
  final List<Map<String, dynamic>> rawShelves;
  final List<SongModel> trending;
  final String? profileUrl;
  final String? ytName;
  final List<SongModel> musicVideos;
  final List<SongModel> favArtistsSongs;

  const HomeDataModel({
    required this.rawShelves,
    this.trending = const [],
    this.profileUrl,
    this.ytName,
    this.musicVideos = const [],
    this.favArtistsSongs = const [],
  });

  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    final rawShelves = (json['shelves'] as List<dynamic>? ?? [])
        .map((s) => s as Map<String, dynamic>)
        .toList();

    final trending = ((json['trending'] as List<dynamic>?) ?? [])
        .map((s) => SongModel.fromJson(s as Map<String, dynamic>))
        .toList();

    final musicVideos = ((json['musicVideos'] as List<dynamic>?) ?? [])
        .map((s) => SongModel.fromJson(s as Map<String, dynamic>))
        .toList();

    final favArtistsSongs = ((json['favArtistsSongs'] as List<dynamic>?) ?? [])
        .map((s) => SongModel.fromJson(s as Map<String, dynamic>))
        .toList();

    return HomeDataModel(
      rawShelves: rawShelves,
      trending: trending,
      profileUrl: json['profileUrl'] as String?,
      ytName: json['yt_name'] as String?,
      musicVideos: musicVideos,
      favArtistsSongs: favArtistsSongs,
    );
  }

  Map<String, dynamic> toJson() => {
    'shelves': rawShelves,
    'trending': trending.map((s) => s.toJson()).toList(),
    'profileUrl': profileUrl,
    'yt_name': ytName,
    'musicVideos': musicVideos.map((s) => s.toJson()).toList(),
    'favArtistsSongs': favArtistsSongs.map((s) => s.toJson()).toList(),
  };

  HomeData toEntity() {
    final shelves = rawShelves.map((shelfJson) {
      final title = shelfJson['title'] as String? ?? 'Recommended';
      final section = shelfJson['section'] as String?;
      final items = (shelfJson['items'] as List<dynamic>? ?? []).map((
        itemJson,
      ) {
        final typeStr = itemJson['type'] as String;
        final data = itemJson['data'] as Map<String, dynamic>;

        HomeItemType type;
        dynamic mappedData;

        switch (typeStr) {
          case 'song':
            type = HomeItemType.song;
            mappedData = SongModel.fromJson(data).toEntity();
            break;
          case 'artist':
            type = HomeItemType.artist;
            final name = data['name'] as String? ?? 'Unknown';
            final colors = _artistColors(name);
            mappedData = {
              'name': name,
              'thumbnailUrl': data['thumbnailUrl'] as String?,
              'colorPrimary': colors.$1,
              'colorSecondary': colors.$2,
            };
            break;
          case 'album':
            type = HomeItemType.album;
            mappedData = PlaylistModel.fromJson(data).toEntity();
            break;
          case 'playlist':
            type = HomeItemType.playlist;
            mappedData = PlaylistModel.fromJson(data).toEntity();
            break;
          default:
            type = HomeItemType.song;
            mappedData = SongModel.fromJson(data).toEntity();
        }

        return HomeItem(type: type, data: mappedData);
      }).toList();

      return HomeShelf(title: title, section: section, items: items);
    }).toList();

    return HomeData(
      shelves: shelves,
      trending: trending.map((m) => m.toEntity()).toList(),
      profileUrl: profileUrl,
      ytName: ytName,
      musicVideos: musicVideos.map((m) => m.toEntity()).toList(),
      favArtistsSongs: favArtistsSongs.map((m) => m.toEntity()).toList(),
    );
  }

  static const _colorPairs = [
    (Color(0xFF7C3AED), Color(0xFF2563EB)),
    (Color(0xFFEC4899), Color(0xFFEF4444)),
    (Color(0xFF059669), Color(0xFF0891B2)),
    (Color(0xFFF59E0B), Color(0xFF6366F1)),
    (Color(0xFF0284C7), Color(0xFF059669)),
    (Color(0xFFDB2777), Color(0xFF9333EA)),
    (Color(0xFF14B8A6), Color(0xFF0F766E)),
    (Color(0xFF8B5CF6), Color(0xFF4C1D95)),
  ];

  static (Color, Color) _artistColors(String name) {
    final hash = name.codeUnits.fold(0, (a, b) => a + b);
    return _colorPairs[hash % _colorPairs.length];
  }
}
