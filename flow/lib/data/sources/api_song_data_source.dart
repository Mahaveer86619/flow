import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/server_config.dart';
import '../../core/error/app_exception.dart';
import '../../core/logger/app_logger.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/storage/local_storage.dart';
import '../models/home_data_model.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import 'song_data_source.dart';

// ── API Data Source ───────────────────────────────────────────────────────────
//
// One GET call per screen — aligned with the backend's /v1/ endpoints:
//
//   Screen        Method              Endpoint
//   ────────────  ──────────────────  ──────────────────────────────────────
//   Home          fetchHomeData()     GET /v1/home
//   Search        searchSongs(q)      GET /v1/search/songs?q=
//   Library       fetchPlaylists()    GET /v1/library   (playlists key)
//   Playlist      fetchPlaylistTracks GET /v1/playlists/{id}/tracks
//
// [baseUrl] — scheme + host + port, no trailing slash.
//   Example: "http://192.168.1.10:8000"
// ─────────────────────────────────────────────────────────────────────────────

class ApiSongDataSource implements SongDataSource {
  final http.Client _client;
  final ConnectivityService _connectivity;

  static const _tag = 'ApiSongDataSource';
  static const _timeout = Duration(seconds: 12);

  ApiSongDataSource({http.Client? client, ConnectivityService? connectivity})
    : _client = client ?? http.Client(),
      _connectivity = connectivity ?? ConnectivityService.instance;

  // ── SongDataSource impl ──────────────────────────────────────────────────────

  @override
  Future<HomeDataModel> fetchHomeData() async {
    AppLogger.i(_tag, 'fetchHomeData()');
    final json = await _getJson('/v1/home') as Map<String, dynamic>;
    AppLogger.d(
      _tag,
      'fetchHomeData: '
      'quickAccess=${_len(json, "quickAccess")} '
      'listeningAgain=${_len(json, "listeningAgain")} '
      'forgottenFavorites=${_len(json, "forgottenFavorites")} '
      'musicForYou=${_len(json, "musicForYou")} '
      'artists=${_len(json, "trendingArtists")}',
    );
    try {
      return HomeDataModel.fromJson(json);
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchHomeData parse failure', e, st);
      throw ParseException('Failed to parse home data: $e');
    }
  }

  @override
  Future<List<SongModel>> searchSongs(String query) async {
    if (query.trim().isEmpty) return const [];
    AppLogger.i(_tag, 'searchSongs("$query")');
    final list =
        await _getJson('/v1/search/songs', params: {'q': query})
            as List<dynamic>;
    AppLogger.d(_tag, 'searchSongs("$query"): ${list.length} results');
    try {
      return list
          .map((e) => SongModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.e(_tag, 'searchSongs parse failure', e, st);
      throw ParseException('Failed to parse search results: $e');
    }
  }

  @override
  Future<List<PlaylistModel>> fetchPlaylists() async {
    AppLogger.i(_tag, 'fetchPlaylists()');
    final json = await _getJson('/v1/library') as Map<String, dynamic>;
    final list = (json['playlists'] as List<dynamic>?) ?? [];
    AppLogger.d(_tag, 'fetchPlaylists: ${list.length} playlists');
    try {
      return list
          .map((e) => PlaylistModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchPlaylists parse failure', e, st);
      throw ParseException('Failed to parse playlists: $e');
    }
  }

  @override
  Future<List<SongModel>> fetchPlaylistTracks(
    String playlistId, {
    int limit = 100,
  }) async {
    AppLogger.i(_tag, 'fetchPlaylistTracks($playlistId, limit=$limit)');
    final list =
        await _getJson(
              '/v1/playlists/$playlistId/tracks',
              params: {'limit': limit.toString()},
            )
            as List<dynamic>;
    AppLogger.d(
      _tag,
      'fetchPlaylistTracks($playlistId): ${list.length} tracks',
    );
    try {
      return list
          .map((e) => SongModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchPlaylistTracks parse failure', e, st);
      throw ParseException('Failed to parse playlist tracks: $e');
    }
  }

  @override
  Future<List<SongModel>> fetchAlbumTracks(String browseId) async {
    AppLogger.i(_tag, 'fetchAlbumTracks($browseId)');
    final json = await _getJson('/v1/albums/$browseId') as Map<String, dynamic>;
    final list = (json['tracks'] as List<dynamic>?) ?? [];
    try {
      return list
          .map((e) => SongModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchAlbumTracks parse failure', e, st);
      throw ParseException('Failed to parse album tracks: $e');
    }
  }

  @override
  Future<List<SongModel>> fetchRadioTracks(
    String videoId, {
    int limit = 25,
  }) async {
    AppLogger.i(_tag, 'fetchRadioTracks($videoId, limit=$limit)');
    final json =
        await _getJson(
              '/v1/radio/$videoId',
              params: {'limit': limit.toString()},
            )
            as Map<String, dynamic>;
    final list = (json['tracks'] as List<dynamic>?) ?? [];
    try {
      return list
          .map((e) => SongModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchRadioTracks parse failure', e, st);
      throw ParseException('Failed to parse radio tracks: $e');
    }
  }

  @override
  Future<List<SongModel>> fetchSongsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    AppLogger.i(_tag, 'fetchSongsByIds(${ids.length} ids)');
    final list =
        await _getJson('/v1/songs/batch', params: {'ids': ids.join(',')})
            as List<dynamic>;
    try {
      return list
          .map((e) => SongModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchSongsByIds parse failure', e, st);
      throw ParseException('Failed to parse batch song results: $e');
    }
  }

  @override
  Future<void> prefetchAudio(String videoId) async {
    try {
      // Fire and forget GET request to the prefetch endpoint
      _getJson('/v1/prefetch/$videoId');
    } catch (e) {
      AppLogger.w(_tag, 'Prefetch fire failed: $e');
    }
  }

  @override
  List<Map<String, dynamic>> fetchCategories() => _staticCategories;

  // ── HTTP helpers ──────────────────────────────────────────────────────────────

  Future<dynamic> _getJson(String path, {Map<String, String>? params}) async {
    // ── Connectivity gate ──────────────────────────────────────────────────────
    if (!_connectivity.isOnline) {
      AppLogger.w(_tag, 'GET $path blocked — device offline');
      throw const NetworkException();
    }

    final uri = Uri.parse(
      '${ServerConfig.instance.baseUrl}$path',
    ).replace(queryParameters: params);
    AppLogger.d(_tag, 'GET $uri');

    try {
      final headers = <String, String>{'User-Agent': 'FlowMusicApp/1.0'};
      final token = LocalStorage.instance.jwtToken;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await _client
          .get(uri, headers: headers)
          .timeout(_timeout);

      AppLogger.d(_tag, '${response.statusCode} ← $uri');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }

      AppLogger.w(_tag, 'HTTP ${response.statusCode} ← $uri\n${response.body}');
      throw ServerException(
        message: 'Server returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on AppException {
      rethrow;
    } catch (e, st) {
      final wrapped = toAppException(e);
      AppLogger.e(_tag, 'Request failed: $uri', e, st);
      throw wrapped;
    }
  }

  int _len(Map<String, dynamic> json, String key) =>
      (json[key] as List?)?.length ?? 0;

  // ── Static browse categories ──────────────────────────────────────────────────

  static const List<Map<String, dynamic>> _staticCategories = [
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
}
