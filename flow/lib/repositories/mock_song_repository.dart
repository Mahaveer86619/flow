import 'package:flutter/material.dart';
import '../models/song.dart';
import 'song_repository.dart';

/// In-memory mock implementation of [SongRepository].
/// Replace with a network/database implementation when ready.
class MockSongRepository implements SongRepository {
  static const List<Song> _songs = [
    Song(
      id: '1',
      title: 'Midnight Dreams',
      artist: 'Luna Echo',
      album: 'Neon Nights',
      duration: Duration(minutes: 3, seconds: 42),
      colorPrimary: Color(0xFF7C3AED),
      colorSecondary: Color(0xFF2563EB),
    ),
    Song(
      id: '2',
      title: 'Solar Drift',
      artist: 'Wavelength',
      album: 'Frequencies',
      duration: Duration(minutes: 4, seconds: 15),
      colorPrimary: Color(0xFFEC4899),
      colorSecondary: Color(0xFFEF4444),
    ),
    Song(
      id: '3',
      title: 'Quiet Storm',
      artist: 'The Ambient',
      album: 'Still Waters',
      duration: Duration(minutes: 5, seconds: 3),
      colorPrimary: Color(0xFF059669),
      colorSecondary: Color(0xFF0891B2),
    ),
    Song(
      id: '4',
      title: 'Electric Pulse',
      artist: 'Neon Drive',
      album: 'Synthwave',
      duration: Duration(minutes: 3, seconds: 58),
      colorPrimary: Color(0xFFF59E0B),
      colorSecondary: Color(0xFFEF4444),
    ),
    Song(
      id: '5',
      title: 'Falling Stars',
      artist: 'Celestial',
      album: 'Cosmos',
      duration: Duration(minutes: 4, seconds: 30),
      colorPrimary: Color(0xFF6366F1),
      colorSecondary: Color(0xFF8B5CF6),
    ),
    Song(
      id: '6',
      title: 'Ocean Floor',
      artist: 'Deep Blue',
      album: 'Depths',
      duration: Duration(minutes: 3, seconds: 22),
      colorPrimary: Color(0xFF0284C7),
      colorSecondary: Color(0xFF059669),
    ),
    Song(
      id: '7',
      title: 'City Lights',
      artist: 'Urban Canvas',
      album: 'Metropolis',
      duration: Duration(minutes: 4, seconds: 8),
      colorPrimary: Color(0xFFDB2777),
      colorSecondary: Color(0xFF9333EA),
    ),
    Song(
      id: '8',
      title: 'Horizon Line',
      artist: 'Luna Echo',
      album: 'Neon Nights',
      duration: Duration(minutes: 3, seconds: 55),
      colorPrimary: Color(0xFF0EA5E9),
      colorSecondary: Color(0xFF7C3AED),
    ),
  ];

  static final List<Playlist> _playlists = [
    const Playlist(
      id: 'p1',
      name: 'Late Night Drive',
      description: '18 songs • Made by you',
      songs: [],
      color: Color(0xFF1E40AF),
    ),
    const Playlist(
      id: 'p2',
      name: 'Morning Focus',
      description: '25 songs • Made by you',
      songs: [],
      color: Color(0xFF059669),
    ),
    const Playlist(
      id: 'p3',
      name: 'Workout Mix',
      description: '31 songs • Made by you',
      songs: [],
      color: Color(0xFFDC2626),
    ),
    const Playlist(
      id: 'p4',
      name: 'Chill Vibes',
      description: '22 songs • Made by you',
      songs: [],
      color: Color(0xFF7C3AED),
    ),
  ];

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

  @override
  List<Song> getSongs() => List.unmodifiable(_songs);

  @override
  List<Playlist> getPlaylists() => List.unmodifiable(_playlists);

  @override
  List<Map<String, dynamic>> getCategories() => List.unmodifiable(_categories);
}
