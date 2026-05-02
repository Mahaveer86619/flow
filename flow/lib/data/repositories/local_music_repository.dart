import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show Color;
import '../../domain/entities/song.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/entities/history_data.dart';
import '../../domain/entities/scoring_graph.dart';
import '../../domain/repositories/music_repository.dart';
import '../sources/local/local_database.dart';
import '../../core/intelligence/app_intelligence.dart';

class LocalMusicRepository implements MusicRepository {
  final LocalDatabase _db;

  LocalMusicRepository(this._db);


  @override
  Future<List<Song>> searchSongs(String query, {int limit = 25}) async {
    final results = await (_db.select(_db.tracks)
          ..where((t) =>
              t.title.contains(query) |
              t.artist.contains(query) |
              t.album.contains(query))
          ..limit(limit))
        .get();

    return results.map((e) => _mapEntityToSong(e)).toList();
  }

  @override
  Future<List<Playlist>> getPlaylists() async {
    final results = await _db.select(_db.playlists).get();
    return results.map((e) => _mapEntityToPlaylist(e)).toList();
  }

  @override
  Future<List<Song>> getPlaylistTracks(String playlistId,
      {int limit = 100}) async {
    final query = _db.select(_db.playlistTracks).join([
      innerJoin(_db.tracks, _db.tracks.id.equalsExp(_db.playlistTracks.trackId)),
    ])
      ..where(_db.playlistTracks.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm.asc(_db.playlistTracks.position)])
      ..limit(limit);

    final results = await query.get();
    return results.map((row) {
      final track = row.readTable(_db.tracks);
      return _mapEntityToSong(track);
    }).toList();
  }

  @override
  Future<void> recordPlay(Song song) async {
    await AppIntelligence.instance.recordEvent(
      Track.fromSong(song),
      ListenEvent.fullListen,
    );
  }

  @override
  Future<HistoryData> getPersistentHistory() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    
    final query = _db.select(_db.listenEvents).join([
      innerJoin(_db.tracks, _db.tracks.id.equalsExp(_db.listenEvents.trackId)),
    ])
      ..orderBy([OrderingTerm.desc(_db.listenEvents.timestamp)]);

    final results = await query.get();
    final List<Song> today = [];
    final List<Song> week = [];
    
    for (final row in results) {
      final event = row.readTable(_db.listenEvents);
      final track = row.readTable(_db.tracks);
      final song = _mapEntityToSong(track);
      
      if (event.timestamp >= todayStart) {
        today.add(song);
      } else if (now.millisecondsSinceEpoch - event.timestamp < 7 * 24 * 3600 * 1000) {
        week.add(song);
      }
    }

    return HistoryData(
      today: today,
      thisWeek: week,
      thisMonth: [], // Simplified
      byMonth: {},
    );
  }

  @override
  Future<Playlist> createFlowPlaylist({required String title, String description = '', bool isPublic = false}) async {
    final id = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final entry = PlaylistsCompanion.insert(
      id: id,
      name: title,
      description: Value(description),
      createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      type: const Value('local'),
    );
    await _db.into(_db.playlists).insert(entry);
    final entity = await (_db.select(_db.playlists)..where((t) => t.id.equals(id))).getSingle();
    return _mapEntityToPlaylist(entity);
  }

  @override
  Future<void> addTrackToFlowPlaylist(String playlistId, Song song) async {
    // 1. Ensure track exists in database
    await _db.into(_db.tracks).insertOnConflictUpdate(
      _mapSongToCompanion(song),
    );

    // 2. Get current max position
    final countQuery = _db.select(_db.playlistTracks)
      ..where((t) => t.playlistId.equals(playlistId));
    final existing = await countQuery.get();
    final nextPos = existing.length;

    // 3. Add to junction table
    await _db.into(_db.playlistTracks).insert(
      PlaylistTracksCompanion.insert(
        playlistId: playlistId,
        trackId: song.id,
        position: nextPos,
        addedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<List<Song>> getBlendedRecommendations(String friendId, {int limit = 20}) async => [];

  Song _mapEntityToSong(TrackEntity e) {

    final extras = <String, dynamic>{
      'artistId': e.artistId,
      'albumId': e.albumId,
      'year': e.year,
      'genres': e.genres != null ? jsonDecode(e.genres!) : [],
      'tags': e.tags != null ? jsonDecode(e.tags!) : [],
      'youtubeId': e.youtubeId,
      'graphScore': e.graphScore,
      'playCount': e.playCount,
    };

    return Song(
      id: e.id,
      title: e.title,
      artist: e.artist,
      album: e.album ?? '',
      duration: const Duration(minutes: 3, seconds: 30),
      thumbnailUrl: e.artworkUrl,
      isDownloaded: e.downloaded,
      colorPrimary: const Color(0xFF7C3AED),
      colorSecondary: const Color(0xFFBC9AFF),
      extras: extras,
    );
  }

  TracksCompanion _mapSongToCompanion(Song song) {
    final extras = song.extras ?? {};
    return TracksCompanion.insert(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artistId: extras['artistId'] as String? ?? song.artist,
      album: Value(song.album),
      albumId: Value(extras['albumId'] as String?),
      year: Value(extras['year'] as String?),
      genres: Value(extras['genres'] != null ? jsonEncode(extras['genres']) : null),
      tags: Value(extras['tags'] != null ? jsonEncode(extras['tags']) : null),
      youtubeId: Value(extras['youtubeId'] as String? ?? song.id),
      artworkUrl: Value(song.thumbnailUrl),
      downloaded: Value(song.isDownloaded),
    );
  }

  Playlist _mapEntityToPlaylist(PlaylistEntity e) {
    return Playlist(
      id: e.id,
      name: e.name,
      description: e.description ?? '',
      songs: [], // Hydrated on demand
      color: const Color(0xFF7C3AED),
      thumbnailUrl: null,
      type: e.type ?? 'local',
    );
  }

  @override Future<HomeData> getHomeData({int limit = 25}) async => throw UnimplementedError();
  @override Future<List<Song>> getAlbumTracks(String browseId, {int limit = 25}) async => [];
  @override Future<List<Song>> getArtistSongs(String channelId) async => [];
  @override Future<List<Song>> getRadioTracks(String videoId, {int limit = 25}) async => [];
  @override Future<void> likeArtist(String channelId) async {}
  @override Future<void> unlikeArtist(String channelId) async {}
  @override Future<List<Song>> getSongsByIds(List<String> ids) async => [];
  @override Future<void> prefetchAudio(String videoId) async {}
  @override Future<void> recordSearch(String query) async {}
  @override
  Future<List<String>> getTopArtists() async {
    final artists = await AppIntelligence.instance.getTopArtists(limit: 10);
    return artists.map((a) => a['id'] as String).toList();
  }

  @override void recordPodcastInterest(String artistName) {}
  @override void recordLofiInterest(String artistName) {}
  @override Future<Map<String, dynamic>> getSongDetails(String videoId) async => {};
  @override Future<Map<String, dynamic>> getArtistDetails(String browseId) async => {};
  @override List<Map<String, dynamic>> getCategories() => [];
  @override Future<List<Song>> getRecommendations({int limit = 20}) async => [];
  @override Future<Playlist> updateFlowPlaylist(String playlistId, {String? title, String? description, bool? isPublic}) async => throw UnimplementedError();
  @override Future<void> deleteFlowPlaylist(String playlistId) async {}
  @override Future<void> removeTrackFromFlowPlaylist(String playlistId, int trackId) async {}
  @override Future<void> addCollaborator(String playlistId, String userCode) async {}
  @override Future<void> removeCollaborator(String playlistId, String userCode) async {}
}
