import 'package:flutter/material.dart';
import '../../domain/entities/home_data.dart';
import 'song_model.dart';

// ── HomeDataModel ─────────────────────────────────────────────────────────────
//
// DTO that mirrors the GET /api/home response:
//   { quickAccess, listeningAgain, forgottenFavorites, musicForYou,
//     trendingArtists }
//
// Each song section is parsed via SongModel.fromJson so colours and thumbnails
// are handled in one place. Artist maps have colours derived from the name
// so ArtistCard can always render a gradient fallback.
// ─────────────────────────────────────────────────────────────────────────────

class HomeDataModel {
  final List<SongModel> quickAccess;
  final List<SongModel> listeningAgain;
  final List<SongModel> forgottenFavorites;
  final List<SongModel> musicForYou;
  final List<Map<String, dynamic>> trendingArtists;
  final List<SongModel> trending;

  const HomeDataModel({
    required this.quickAccess,
    required this.listeningAgain,
    required this.forgottenFavorites,
    required this.musicForYou,
    required this.trendingArtists,
    this.trending = const [],
  });

  // ── JSON ─────────────────────────────────────────────────────────────────────

  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    List<SongModel> parseSongs(String key) => ((json[key] as List<dynamic>?) ?? [])
        .map((s) => SongModel.fromJson(s as Map<String, dynamic>))
        .toList();

    final artists = ((json['trendingArtists'] as List<dynamic>?) ?? [])
        .map((a) {
          final m = a as Map<String, dynamic>;
          final name = m['name'] as String? ?? '';
          final colors = _artistColors(name);
          return <String, dynamic>{
            'name': name,
            'thumbnailUrl': m['thumbnailUrl'] as String?,
            'colorPrimary': colors.$1,
            'colorSecondary': colors.$2,
          };
        })
        .toList();

    return HomeDataModel(
      quickAccess: parseSongs('quickAccess'),
      listeningAgain: parseSongs('listeningAgain'),
      forgottenFavorites: parseSongs('forgottenFavorites'),
      musicForYou: parseSongs('musicForYou'),
      trendingArtists: artists,
      trending: parseSongs('trending'),
    );
  }

  // ── Domain mapping ────────────────────────────────────────────────────────────

  HomeData toEntity() => HomeData(
        quickAccess: quickAccess.map((m) => m.toEntity()).toList(),
        listeningAgain: listeningAgain.map((m) => m.toEntity()).toList(),
        forgottenFavorites: forgottenFavorites.map((m) => m.toEntity()).toList(),
        musicForYou: musicForYou.map((m) => m.toEntity()).toList(),
        trendingArtists: trendingArtists,
        trending: trending.map((m) => m.toEntity()).toList(),
      );

  // ── Artist colour derivation ──────────────────────────────────────────────────

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
