import 'package:flutter/material.dart';
import '../models/home_data_model.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import 'song_data_source.dart';

// ── Mock Data Source ──────────────────────────────────────────────────────────
//
// In-memory implementation of [SongDataSource].
// Set USE_MOCK=true in .env to use this without a running backend.
// ─────────────────────────────────────────────────────────────────────────────

class MockSongDataSource implements SongDataSource {
  // ── Raw song catalogue ───────────────────────────────────────────────────────

  static const List<SongModel> _songs = [
    SongModel(
      id: '1',
      title: 'Midnight Dreams',
      artist: 'Luna Echo',
      album: 'Neon Nights',
      duration: Duration(minutes: 3, seconds: 42),
      colorPrimary: Color(0xFF7C3AED),
      colorSecondary: Color(0xFF2563EB),
    ),
    SongModel(
      id: '2',
      title: 'Solar Drift',
      artist: 'Wavelength',
      album: 'Frequencies',
      duration: Duration(minutes: 4, seconds: 15),
      colorPrimary: Color(0xFFEC4899),
      colorSecondary: Color(0xFFEF4444),
    ),
    SongModel(
      id: '3',
      title: 'Quiet Storm',
      artist: 'The Ambient',
      album: 'Still Waters',
      duration: Duration(minutes: 5, seconds: 3),
      colorPrimary: Color(0xFF059669),
      colorSecondary: Color(0xFF0891B2),
    ),
    SongModel(
      id: '4',
      title: 'Electric Pulse',
      artist: 'Neon Drive',
      album: 'Synthwave',
      duration: Duration(minutes: 3, seconds: 58),
      colorPrimary: Color(0xFFF59E0B),
      colorSecondary: Color(0xFFEF4444),
    ),
    SongModel(
      id: '5',
      title: 'Falling Stars',
      artist: 'Celestial',
      album: 'Cosmos',
      duration: Duration(minutes: 4, seconds: 30),
      colorPrimary: Color(0xFF6366F1),
      colorSecondary: Color(0xFF8B5CF6),
    ),
    SongModel(
      id: '6',
      title: 'Ocean Floor',
      artist: 'Deep Blue',
      album: 'Depths',
      duration: Duration(minutes: 3, seconds: 22),
      colorPrimary: Color(0xFF0284C7),
      colorSecondary: Color(0xFF059669),
    ),
    SongModel(
      id: '7',
      title: 'City Lights',
      artist: 'Urban Canvas',
      album: 'Metropolis',
      duration: Duration(minutes: 4, seconds: 8),
      colorPrimary: Color(0xFFDB2777),
      colorSecondary: Color(0xFF9333EA),
    ),
    SongModel(
      id: '8',
      title: 'Horizon Line',
      artist: 'Luna Echo',
      album: 'Neon Nights',
      duration: Duration(minutes: 3, seconds: 55),
      colorPrimary: Color(0xFF0EA5E9),
      colorSecondary: Color(0xFF7C3AED),
    ),
    SongModel(
      id: '9',
      title: 'Summer Breeze',
      artist: 'Chill Wave',
      album: 'Vibes',
      duration: Duration(minutes: 3, seconds: 15),
      colorPrimary: Color(0xFFFBBF24),
      colorSecondary: Color(0xFFF59E0B),
    ),
    SongModel(
      id: '10',
      title: 'Night Owl',
      artist: 'The Nocturnals',
      album: 'After Dark',
      duration: Duration(minutes: 4, seconds: 42),
      colorPrimary: Color(0xFF4F46E5),
      colorSecondary: Color(0xFF312E81),
    ),
    SongModel(
      id: '11',
      title: 'Mountain Peak',
      artist: 'High Altitude',
      album: 'Summit',
      duration: Duration(minutes: 5, seconds: 12),
      colorPrimary: Color(0xFF10B981),
      colorSecondary: Color(0xFF047857),
    ),
    SongModel(
      id: '12',
      title: 'Desert Wind',
      artist: 'Sandstorm',
      album: 'Mirage',
      duration: Duration(minutes: 3, seconds: 50),
      colorPrimary: Color(0xFFD97706),
      colorSecondary: Color(0xFFB45309),
    ),
    SongModel(
      id: '13',
      title: 'Crystal Clear',
      artist: 'Glass Heart',
      album: 'Reflections',
      duration: Duration(minutes: 4, seconds: 5),
      colorPrimary: Color(0xFF38BDF8),
      colorSecondary: Color(0xFF0369A1),
    ),
    SongModel(
      id: '14',
      title: 'Echo Chamber',
      artist: 'Soundscape',
      album: 'Resonance',
      duration: Duration(minutes: 6, seconds: 0),
      colorPrimary: Color(0xFF8B5CF6),
      colorSecondary: Color(0xFF4C1D95),
    ),
    SongModel(
      id: '15',
      title: 'Velvet Sky',
      artist: 'Stargazer',
      album: 'Astral',
      duration: Duration(minutes: 3, seconds: 33),
      colorPrimary: Color(0xFFE879F9),
      colorSecondary: Color(0xFFBE185D),
    ),
    SongModel(
      id: '16',
      title: 'Neon Drift',
      artist: 'Synthwave',
      album: 'Retrograde',
      duration: Duration(minutes: 4, seconds: 20),
      colorPrimary: Color(0xFF14B8A6),
      colorSecondary: Color(0xFF0F766E),
    ),
  ];

  // ── Playlists ────────────────────────────────────────────────────────────────

  static const List<PlaylistModel> _playlists = [
    PlaylistModel(
      id: 'p1',
      name: 'Late Night Drive',
      description: '4 songs',
      trackCount: 4,
      color: Color(0xFF1E40AF),
    ),
    PlaylistModel(
      id: 'p2',
      name: 'Morning Focus',
      description: '4 songs',
      trackCount: 4,
      color: Color(0xFF059669),
    ),
    PlaylistModel(
      id: 'p3',
      name: 'Workout Mix',
      description: '4 songs',
      trackCount: 4,
      color: Color(0xFFDC2626),
    ),
    PlaylistModel(
      id: 'p4',
      name: 'Chill Vibes',
      description: '4 songs',
      trackCount: 4,
      color: Color(0xFF7C3AED),
    ),
  ];

  static final Map<String, List<SongModel>> _playlistTracks = {
    'p1': [_songs[0], _songs[1], _songs[2], _songs[3]],
    'p2': [_songs[4], _songs[5], _songs[6], _songs[7]],
    'p3': [_songs[8], _songs[9], _songs[10], _songs[11]],
    'p4': [_songs[12], _songs[13], _songs[14], _songs[15]],
  };

  // ── Categories ───────────────────────────────────────────────────────────────

  static const List<Map<String, dynamic>> _categories = [
    {'name': 'Electronic', 'color': Color(0xFF7C3AED)},
    {'name': 'Hip-Hop', 'color': Color(0xFFDC2626)},
    {'name': 'Ambient', 'color': Color(0xFF059669)},
    {'name': 'Pop', 'color': Color(0xFFEC4899)},
    {'name': 'Jazz', 'color': Color(0xFFF59E0B)},
    {'name': 'Rock', 'color': Color(0xFF374151)},
    {'name': 'Classical', 'color': Color(0xFF0891B2)},
    {'name': 'R&B', 'color': Color(0xFFDB2777)},
    {'name': 'Podcasts', 'color': Color(0xFF6366F1)},
    {'name': 'Metal', 'color': Color(0xFF1F2937)},
  ];

  // ── SongDataSource impl ──────────────────────────────────────────────────────

  @override
  Future<HomeDataModel> fetchHomeData() async {
    final artists = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final s in _songs) {
      if (seen.add(s.artist)) {
        artists.add({
          'name': s.artist,
          'thumbnailUrl': null,
          'colorPrimary': s.colorPrimary,
          'colorSecondary': s.colorSecondary,
        });
      }
    }

    return HomeDataModel(
      quickAccess: _songs.sublist(0, 6),
      listeningAgain: _songs.sublist(0, 6),
      forgottenFavorites: _songs.reversed.take(6).toList(),
      musicForYou: List.unmodifiable(_songs),
      trendingArtists: artists.take(8).toList(),
    );
  }

  @override
  Future<List<SongModel>> searchSongs(String query) async {
    if (query.trim().isEmpty) return const [];
    final q = query.toLowerCase();
    return _songs.where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<List<PlaylistModel>> fetchPlaylists() async =>
      List.unmodifiable(_playlists);

  @override
  Future<List<SongModel>> fetchPlaylistTracks(
    String playlistId, {
    int limit = 100,
  }) async => List.unmodifiable(
    (_playlistTracks[playlistId] ?? []).take(limit).toList(),
  );

  @override
  Future<List<SongModel>> fetchAlbumTracks(String browseId) async =>
      List.unmodifiable(_songs.take(10).toList());

  @override
  Future<List<SongModel>> fetchRadioTracks(
    String videoId, {
    int limit = 25,
  }) async => List.unmodifiable(_songs.take(limit).toList());

  @override
  Future<List<SongModel>> fetchSongsByIds(List<String> ids) async {
    final set = ids.toSet();
    return _songs.where((s) => set.contains(s.id)).toList();
  }

  @override
  List<Map<String, dynamic>> fetchCategories() =>
      List.unmodifiable(_categories);
}
