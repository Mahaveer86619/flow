import 'package:flutter/material.dart';
import '../../domain/entities/song.dart';
import '../models/home_data_model.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import 'music_data_source.dart';

/// Legacy API Data Source (Stubbed for Standalone mode).
class ApiSongDataSource implements MusicDataSource {
  @override
  Future<HomeDataModel> fetchHomeData({int limit = 25}) async => 
      const HomeDataModel(rawShelves: [], trending: [], musicVideos: [], favArtistsSongs: []);

  @override
  Future<List<SongModel>> searchSongs(String query, {int limit = 25}) async => [];

  @override
  Future<List<PlaylistModel>> fetchPlaylists() async => [];

  @override
  Future<List<SongModel>> fetchPlaylistTracks(String playlistId, {int limit = 100}) async => [];

  @override
  Future<List<SongModel>> fetchAlbumTracks(String browseId, {int limit = 25}) async => [];

  @override
  Future<List<SongModel>> fetchArtistSongs(String channelId) async => [];

  @override
  Future<List<SongModel>> fetchRadioTracks(String videoId, {int limit = 25}) async => [];

  @override
  Future<List<SongModel>> fetchSongsByIds(List<String> ids) async => [];

  @override
  Future<void> prefetchAudio(String videoId) async {}

  @override
  Future<void> recordPlay(SongModel song) async {}

  @override
  Future<Map<String, dynamic>> fetchPersistentHistory() async => {};

  @override
  List<Map<String, dynamic>> fetchCategories() => _staticCategories;

  // Playlist management stubs
  @override
  Future<String> createPlaylist({required String title, String? description, String? privacyStatus, List<String>? videoIds, String? sourcePlaylist}) async => '';
  @override
  Future<void> editPlaylist({required String playlistId, String? title, String? description, String? privacyStatus}) async {}
  @override
  Future<void> deletePlaylist(String playlistId) async {}
  @override
  Future<void> addPlaylistItems({required String playlistId, required List<String> videoIds, String? sourcePlaylist, bool duplicates = false}) async {}
  @override
  Future<void> removePlaylistItems({required String playlistId, required List<Map<String, dynamic>> videos}) async {}
  @override
  Future<void> likeArtist(String channelId) async {}
  @override
  Future<void> unlikeArtist(String channelId) async {}
  @override
  Future<PlaylistModel> createFlowPlaylist({required String title, String description = '', bool isPublic = false}) async => throw UnimplementedError();
  @override
  Future<PlaylistModel> updateFlowPlaylist(String playlistId, {String? title, String? description, bool? isPublic}) async => throw UnimplementedError();
  @override
  Future<void> deleteFlowPlaylist(String playlistId) async {}
  @override
  Future<void> addTrackToFlowPlaylist(String playlistId, Map<String, dynamic> songData) async {}
  @override
  Future<void> removeTrackFromFlowPlaylist(String playlistId, int trackId) async {}
  @override
  Future<void> addCollaborator(String playlistId, String userCode) async {}
  @override
  Future<void> removeCollaborator(String playlistId, String userCode) async {}

  static const List<Map<String, dynamic>> _staticCategories = [
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
}
