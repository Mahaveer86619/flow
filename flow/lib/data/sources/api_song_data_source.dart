import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/auth/auth_event_bus.dart';
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
  Future<HomeDataModel> fetchHomeData({int limit = 25}) async {
    AppLogger.i(_tag, 'fetchHomeData(limit: $limit)');
    final json =
        await _getJson('/v1/home', params: {'limit': limit.toString()}) as Map<String, dynamic>;
    AppLogger.d(
      _tag,
      'fetchHomeData: '
      'quickPicks=${_len(json, "quickPicks")} '
      'listeningAgain=${_len(json, "listeningAgain")} '
      'freshFinds=${_len(json, "freshFinds")} '
      'musicForYou=${_len(json, "musicForYou")} '
      'trendingArtists=${_len(json, "trendingArtists")}',
    );
    try {
      return HomeDataModel.fromJson(json);
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchHomeData parse failure', e, st);
      throw ParseException('Failed to parse home data: $e');
    }
  }

  @override
  Future<List<SongModel>> searchSongs(String query, {int limit = 25}) async {
    if (query.trim().isEmpty) return const [];
    AppLogger.i(_tag, 'searchSongs("$query", limit: $limit)');
    final list =
        await _getJson('/v1/search/songs', params: {
          'q': query,
          'limit': limit.toString(),
        })
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
  Future<List<SongModel>> fetchAlbumTracks(String browseId, {int limit = 25}) async {
    AppLogger.i(_tag, 'fetchAlbumTracks($browseId, limit: $limit)');
    final list = await _getJson(
      '/v1/albums/$browseId',
      params: {'limit': limit.toString()},
    ) as List<dynamic>;
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
  Future<List<SongModel>> fetchArtistSongs(String channelId) async {
    AppLogger.i(_tag, 'fetchArtistSongs($channelId)');
    final list = await _getJson('/v1/artists/$channelId/songs') as List<dynamic>;
    try {
      return list
          .map((e) => SongModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchArtistSongs parse failure', e, st);
      throw ParseException('Failed to parse artist songs: $e');
    }
  }

  @override
  Future<List<SongModel>> fetchRadioTracks(
    String videoId, {
    int limit = 25,
  }) async {
    AppLogger.i(_tag, 'fetchRadioTracks($videoId, limit=$limit)');
    final list =
        await _getJson(
              '/v1/radio/$videoId',
              params: {'limit': limit.toString()},
            )
            as List<dynamic>;
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
  Future<void> recordPlay(SongModel song) async {
    try {
      final uri = Uri.parse('${ServerConfig.instance.baseUrl}/v1/history');
      final headers = <String, String>{
        'User-Agent': 'FlowMusicApp/1.0',
        'Content-Type': 'application/json',
      };
      final token = LocalStorage.instance.jwtToken;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      await _client
          .post(uri, headers: headers, body: jsonEncode(song.toJson()))
          .timeout(_timeout);
    } catch (e) {
      AppLogger.w(_tag, 'Failed to record play history: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> fetchPersistentHistory() async {
    AppLogger.i(_tag, 'fetchPersistentHistory()');
    final json = await _getJson('/v1/history') as Map<String, dynamic>;
    return json;
  }

  @override
  List<Map<String, dynamic>> fetchCategories() => _staticCategories;

  // --- Playlist Management ---

  @override
  Future<String> createPlaylist({
    required String title,
    String? description,
    String? privacyStatus,
    List<String>? videoIds,
    String? sourcePlaylist,
  }) async {
    final resp = await _postJson('/v1/playlists', body: {
      'title': title,
      if (description != null) 'description': description,
      if (privacyStatus != null) 'privacy_status': privacyStatus,
      if (videoIds != null) 'video_ids': videoIds,
      if (sourcePlaylist != null) 'source_playlist': sourcePlaylist,
    });
    return resp['id'] as String;
  }

  @override
  Future<void> editPlaylist({
    required String playlistId,
    String? title,
    String? description,
    String? privacyStatus,
  }) async {
    await _patchJson('/v1/playlists/$playlistId', body: {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (privacyStatus != null) 'privacyStatus': privacyStatus,
    });
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    await _deleteJson('/v1/playlists/$playlistId');
  }

  @override
  Future<void> addPlaylistItems({
    required String playlistId,
    required List<String> videoIds,
    String? sourcePlaylist,
    bool duplicates = false,
  }) async {
    await _postJson('/v1/playlists/$playlistId/items', body: {
      'videoIds': videoIds,
      if (sourcePlaylist != null) 'source_playlist': sourcePlaylist,
      'duplicates': duplicates,
    });
  }

  @override
  Future<void> removePlaylistItems({
    required String playlistId,
    required List<Map<String, dynamic>> videos,
  }) async {
    await _deleteJson('/v1/playlists/$playlistId/items', body: {'videos': videos});
  }

  // --- Artist Management ---

  @override
  Future<void> likeArtist(String channelId) async {
    await _postJson('/v1/artists/$channelId/like');
  }

  @override
  Future<void> unlikeArtist(String channelId) async {
    await _postJson('/v1/artists/$channelId/unlike');
  }

  // --- Flow Playlist CRUD ---

  @override
  Future<PlaylistModel> createFlowPlaylist({
    required String title,
    String description = '',
    bool isPublic = false,
  }) async {
    final resp = await _postJson('/v1/flow/playlists', body: {
      'title': title,
      'description': description,
      'is_public': isPublic,
    }) as Map<String, dynamic>;
    return PlaylistModel.fromJson(resp);
  }

  @override
  Future<PlaylistModel> updateFlowPlaylist(
    String playlistId, {
    String? title,
    String? description,
    bool? isPublic,
  }) async {
    final resp = await _patchJson('/v1/flow/playlists/$playlistId', body: {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (isPublic != null) 'is_public': isPublic,
    }) as Map<String, dynamic>;
    return PlaylistModel.fromJson(resp);
  }

  @override
  Future<void> deleteFlowPlaylist(String playlistId) async {
    await _deleteJson('/v1/flow/playlists/$playlistId');
  }

  @override
  Future<void> addTrackToFlowPlaylist(
    String playlistId,
    Map<String, dynamic> songData,
  ) async {
    await _postJson(
      '/v1/flow/playlists/$playlistId/tracks',
      body: {'song_data': songData},
    );
  }

  @override
  Future<void> removeTrackFromFlowPlaylist(
    String playlistId,
    int trackId,
  ) async {
    await _deleteJson('/v1/flow/playlists/$playlistId/tracks/$trackId');
  }

  @override
  Future<void> addCollaborator(String playlistId, String userCode) async {
    await _postJson(
      '/v1/flow/playlists/$playlistId/collaborators',
      body: {'user_code': userCode},
    );
  }

  @override
  Future<void> removeCollaborator(String playlistId, String userCode) async {
    await _deleteJson(
      '/v1/flow/playlists/$playlistId/collaborators/$userCode',
    );
  }

  // ── HTTP helpers ──────────────────────────────────────────────────────────────

  /// Wraps the original thumbnail URL into a local proxy URL using the current
  /// API base URL. This ensures images work across Cloudflare tunnels etc.
  String? _proxyUrl(String? original) {
    if (original == null || original.isEmpty) return null;
    if (original.startsWith('http://localhost') ||
        original.contains('/v1/proxy-image')) {
      return original;
    }
    final encoded = Uri.encodeComponent(original);
    return '${ServerConfig.instance.baseUrl}/v1/proxy-image?url=$encoded';
  }

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
        final decoded = jsonDecode(response.body);
        return _applyProxyToThumbnails(decoded);
      }

      if (response.statusCode == 401) {
        AuthEventBus.notifyUnauthorized();
        throw const UnauthorizedException();
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

  Future<dynamic> _postJson(String path, {dynamic body}) async {
    if (!_connectivity.isOnline) throw const NetworkException();
    final uri = Uri.parse('${ServerConfig.instance.baseUrl}$path');
    try {
      final headers = <String, String>{
        'User-Agent': 'FlowMusicApp/1.0',
        'Content-Type': 'application/json',
      };
      final token = LocalStorage.instance.jwtToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await _client
          .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isNotEmpty ? jsonDecode(response.body) : null;
      }
      if (response.statusCode == 401) {
        AuthEventBus.notifyUnauthorized();
        throw const UnauthorizedException();
      }
      throw ServerException(message: response.body, statusCode: response.statusCode);
    } catch (e) {
      throw toAppException(e);
    }
  }

  Future<dynamic> _patchJson(String path, {dynamic body}) async {
    if (!_connectivity.isOnline) throw const NetworkException();
    final uri = Uri.parse('${ServerConfig.instance.baseUrl}$path');
    try {
      final headers = <String, String>{
        'User-Agent': 'FlowMusicApp/1.0',
        'Content-Type': 'application/json',
      };
      final token = LocalStorage.instance.jwtToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await _client
          .patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isNotEmpty ? jsonDecode(response.body) : null;
      }
      if (response.statusCode == 401) {
        AuthEventBus.notifyUnauthorized();
        throw const UnauthorizedException();
      }
      throw ServerException(message: response.body, statusCode: response.statusCode);
    } catch (e) {
      throw toAppException(e);
    }
  }

  Future<dynamic> _deleteJson(String path, {dynamic body}) async {
    if (!_connectivity.isOnline) throw const NetworkException();
    final uri = Uri.parse('${ServerConfig.instance.baseUrl}$path');
    try {
      final headers = <String, String>{
        'User-Agent': 'FlowMusicApp/1.0',
        if (body != null) 'Content-Type': 'application/json',
      };
      final token = LocalStorage.instance.jwtToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await _client
          .delete(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isNotEmpty ? jsonDecode(response.body) : null;
      }
      if (response.statusCode == 401) {
        AuthEventBus.notifyUnauthorized();
        throw const UnauthorizedException();
      }
      throw ServerException(message: response.body, statusCode: response.statusCode);
    } catch (e) {
      throw toAppException(e);
    }
  }

  /// Recursively traverses the JSON response and wraps any 'thumbnailUrl' field.
  dynamic _applyProxyToThumbnails(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map.containsKey('thumbnailUrl')) {
        map['thumbnailUrl'] = _proxyUrl(map['thumbnailUrl'] as String?);
      }
      // Recursively apply to all values
      for (final key in map.keys) {
        map[key] = _applyProxyToThumbnails(map[key]);
      }
      return map;
    } else if (data is List) {
      return data.map((e) => _applyProxyToThumbnails(e)).toList();
    }
    return data;
  }

  int _len(Map<String, dynamic> json, String key) =>
      (json[key] as List?)?.length ?? 0;

  // ── Static browse categories ──────────────────────────────────────────────────

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
