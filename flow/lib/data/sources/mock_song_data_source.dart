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
    {'name': 'Electronic', 'color': Color(0xFF8B5CF6)},
    {'name': 'Hip-Hop', 'color': Color(0xFFEF4444)},
    {'name': 'Ambient', 'color': Color(0xFF10B981)},
    {'name': 'Pop', 'color': Color(0xFFF472B6)},
    {'name': 'Jazz', 'color': Color(0xFFFBBF24)},
    {'name': 'Rock', 'color': Color(0xFF4B5563)},
    {'name': 'Classical', 'color': Color(0xFF22D3EE)},
    {'name': 'R&B', 'color': Color(0xFFFB7185)},
    {'name': 'Podcasts', 'color': Color(0xFF818CF8)},
    {'name': 'Metal', 'color': Color(0xFF374151)},
  ];

  // ── SongDataSource impl ──────────────────────────────────────────────────────

  @override
  Future<HomeDataModel> fetchHomeData({int limit = 25}) async {
    final artists = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final s in _songs) {
      if (seen.add(s.artist)) {
        artists.add({
          'name': s.artist,
          'thumbnailUrl': null,
          'colorPrimary': s.colorPrimary.value,
          'colorSecondary': s.colorSecondary.value,
        });
      }
    }

    final rawShelves = [
      {
        'title': 'Quick Picks',
        'section': 'quickPicks',
        'items': _songs
            .take(limit)
            .map((s) => {'type': 'song', 'data': s.toJson()})
            .toList(),
      },
      {
        'title': 'Listen Again',
        'section': 'listeningAgain',
        'items': _songs
            .reversed
            .take(limit)
            .map((s) => {'type': 'song', 'data': s.toJson()})
            .toList(),
      },
      {
        'title': 'Fresh Finds',
        'section': 'newArrivals',
        'items': _songs
            .skip(10)
            .take(15)
            .map((s) => {'type': 'song', 'data': s.toJson()})
            .toList(),
      },
      {
        'title': 'Top Artists',
        'items': artists
            .take(8)
            .map((a) => {'type': 'artist', 'data': a})
            .toList(),
      },
      {
        'title': 'Chill Vibes',
        'items': _playlists
            .take(4)
            .map((p) => {'type': 'playlist', 'data': p.toJson()})
            .toList(),
      },
    ];

    return HomeDataModel(
      rawShelves: rawShelves,
      trending: _songs.sublist(0, 10),
    );
  }

  @override
  Future<List<SongModel>> searchSongs(String query, {int limit = 25}) async {
    if (query.trim().isEmpty) return const [];
    final q = query.toLowerCase();
    return _songs.where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q);
    }).take(limit).toList();
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
  Future<List<SongModel>> fetchAlbumTracks(String browseId, {int limit = 25}) async =>
      List.unmodifiable(_songs.take(limit).toList());

  @override
  Future<List<SongModel>> fetchArtistSongs(String channelId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _songs.where((s) => s.artist.contains('Artist')).toList();
  }

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
  Future<void> prefetchAudio(String videoId) async {
    // No-op for mock data
  }

  @override
  Future<void> recordPlay(SongModel song) async {
    // No-op for mock data
  }

  @override
  Future<Map<String, dynamic>> fetchPersistentHistory() async {
    return {
      'today': [],
      'thisWeek': [],
      'thisMonth': [],
      'older': [],
    };
  }

  @override
  List<Map<String, dynamic>> fetchCategories() =>
      List.unmodifiable(_categories);

  @override
  Future<String> createPlaylist({
    required String title,
    String? description,
    String? privacyStatus,
    List<String>? videoIds,
    String? sourcePlaylist,
  }) async => 'new_playlist_id';

  @override
  Future<void> editPlaylist({
    required String playlistId,
    String? title,
    String? description,
    String? privacyStatus,
  }) async {}

  @override
  Future<void> deletePlaylist(String playlistId) async {}

  @override
  Future<void> addPlaylistItems({
    required String playlistId,
    required List<String> videoIds,
    String? sourcePlaylist,
    bool duplicates = false,
  }) async {}

  @override
  Future<void> removePlaylistItems({
    required String playlistId,
    required List<Map<String, dynamic>> videos,
  }) async {}

  @override
  Future<void> likeArtist(String channelId) async {}

  @override
  Future<void> unlikeArtist(String channelId) async {}
}
