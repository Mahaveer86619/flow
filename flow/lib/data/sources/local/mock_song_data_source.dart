import 'package:flutter/material.dart';
import '../../models/home_data_model.dart';
import '../../models/playlist_model.dart';
import '../../models/song_model.dart';
import '../remote/music_data_source.dart';

class MockSongDataSource implements MusicDataSource {
  final List<SongModel> _songs = [
    const SongModel(
      id: 's1',
      title: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      duration: Duration(minutes: 4, seconds: 3),
      thumbnailUrl: 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200&h=200&fit=crop',
      colorPrimary: Color(0xFF1E40AF),
      colorSecondary: Color(0xFF3B82F6),
    ),
    const SongModel(
      id: 's2',
      title: 'Starboy',
      artist: 'The Weeknd',
      album: 'Starboy',
      duration: Duration(minutes: 3, seconds: 50),
      thumbnailUrl: 'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?w=200&h=200&fit=crop',
      colorPrimary: Color(0xFF7C2D12),
      colorSecondary: Color(0xFFEA580C),
    ),
  ];

  final List<PlaylistModel> _playlists = [
    const PlaylistModel(
      id: 'p1',
      name: 'Today\'s Top Hits',
      description: 'The hottest tracks right now.',
      color: Color(0xFF1E40AF),
    ),
  ];

  @override
  Future<HomeDataModel> fetchHomeData({int limit = 25, String? continuationToken}) async {
    return HomeDataModel(
      rawShelves: [
        {
          'title': 'Recommended',
          'items': _songs.map((s) => {'type': 'song', 'data': s.toJson()}).toList(),
        }
      ],
      trending: _songs,
    );
  }

  @override
  Future<List<SongModel>> searchSongs(String query, {int limit = 25}) async {
    return _songs.where((s) => s.title.toLowerCase().contains(query.toLowerCase())).toList();
  }

  @override
  Future<List<PlaylistModel>> fetchPlaylists() async => _playlists;

  @override
  Future<List<SongModel>> fetchPlaylistTracks(String playlistId, {int limit = 100}) async => _songs;

  @override
  Future<List<SongModel>> fetchAlbumTracks(String browseId, {int limit = 25}) async => _songs;

  @override
  Future<List<SongModel>> fetchArtistSongs(String channelId) async => _songs;

  @override
  Future<List<SongModel>> fetchRadioTracks(String videoId, {int limit = 25}) async => _songs;

  @override
  Future<List<SongModel>> fetchSongsByIds(List<String> ids) async => _songs;

  @override
  Future<void> prefetchAudio(String videoId) async {}

  @override
  Future<void> recordPlay(SongModel song) async {}

  @override
  Future<Map<String, dynamic>> fetchPersistentHistory() async => {};

  @override
  Future<Map<String, dynamic>> fetchSongDetails(String videoId) async => {};

  @override
  Future<Map<String, dynamic>> fetchArtistDetails(String browseId) async => {};

  @override
  List<Map<String, dynamic>> fetchCategories() => [];

  @override
  Future<List<SongModel>> fetchRecommendations({int limit = 20}) async => _songs;

  @override
  Future<List<SongModel>> fetchBlendedRecommendations(String friendId, {int limit = 20}) async => _songs;

  @override
  Future<PlaylistModel> createFlowPlaylist({required String title, String description = '', bool isPublic = false}) async {
    return PlaylistModel(id: 'mock', name: title, description: description, color: Colors.blue);
  }

  @override
  Future<PlaylistModel> updateFlowPlaylist(String playlistId, {String? title, String? description, bool? isPublic}) async {
    return PlaylistModel(id: playlistId, name: title ?? '', description: description ?? '', color: Colors.blue);
  }

  @override
  Future<void> deleteFlowPlaylist(String playlistId) async {}

  @override
  Future<void> addTrackToFlowPlaylist(String playlistId, SongModel song) async {}

  @override
  Future<void> removeTrackFromFlowPlaylist(String playlistId, int trackId) async {}

  @override
  Future<void> addCollaborator(String playlistId, String userCode) async {}

  @override
  Future<void> removeCollaborator(String playlistId, String userCode) async {}

  @override
  Future<void> likeArtist(String channelId) async {}

  @override
  Future<void> unlikeArtist(String channelId) async {}
}
