import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/auth/auth_event_bus.dart';
import '../../core/config/server_config.dart';
import '../../core/error/app_exception.dart';
import '../../core/logger/app_logger.dart';

class AuthDataSource {
  static const _tag = 'AuthDataSource';
  static const _timeout = Duration(seconds: 12);

  String get _base => ServerConfig.instance.baseUrl;

  Map<String, String> _headers([String? token]) => {
    'User-Agent': 'FlowMusicApp/1.0',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<String> login(String username, String password) async {
    AppLogger.i(_tag, 'Attempting login for user: $username');
    try {
      final resp = await http
          .post(
            Uri.parse('$_base/v1/auth/login'),
            headers: _headers(),
            body: {'username': username, 'password': password},
          )
          .timeout(_timeout);
      _assertOk(resp, notify: false);
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = json['access_token'] as String;
      AppLogger.i(_tag, 'Login successful for user: $username');
      return token;
    } catch (e, st) {
      AppLogger.e(_tag, 'Login failed for user: $username', e, st);
      rethrow;
    }
  }

  Future<void> signup(String username, String email, String password) async {
    AppLogger.i(_tag, 'Attempting signup for user: $username ($email)');
    try {
      final resp = await http
          .post(
            Uri.parse('$_base/v1/auth/signup'),
            headers: _headers()..addAll({'Content-Type': 'application/json'}),
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(_timeout);
      _assertOk(resp);
      AppLogger.i(_tag, 'Signup successful for user: $username');
    } catch (e, st) {
      AppLogger.e(_tag, 'Signup failed for user: $username', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMe(String token) async {
    if (AppLogger.isDebug) {
      AppLogger.d(_tag, 'Fetching current user profile');
    }
    final resp = await http
        .get(Uri.parse('$_base/v1/auth/me'), headers: _headers(token))
        .timeout(_timeout);
    _assertOk(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSettings(
    String token,
    Map<String, dynamic> settings,
  ) async {
    AppLogger.i(_tag, 'Updating user settings');
    final resp = await http
        .patch(
          Uri.parse('$_base/v1/auth/settings'),
          headers: _headers(token)
            ..addAll({'Content-Type': 'application/json'}),
          body: jsonEncode({'settings': settings}),
        )
        .timeout(_timeout);
    _assertOk(resp);
    AppLogger.i(_tag, 'User settings updated successfully');
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<void> connectYTCookies(
    String token,
    Map<String, String> cookies,
  ) async {
    AppLogger.i(_tag, 'Connecting YouTube Music cookies');
    try {
      final resp = await http
          .post(
            Uri.parse('$_base/v1/yt-auth/cookies'),
            headers: _headers(token)
              ..addAll({'Content-Type': 'application/json'}),
            body: jsonEncode({'cookies': cookies}),
          )
          .timeout(_timeout);
      _assertOk(resp);
      AppLogger.i(_tag, 'YouTube Music cookies connected successfully');
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to connect YouTube Music cookies', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> refreshProfile(String token) async {
    AppLogger.i(_tag, 'Refreshing user profile');
    final resp = await http
        .post(
          Uri.parse('$_base/v1/auth/refresh-profile'),
          headers: _headers(token),
        )
        .timeout(_timeout);
    _assertOk(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<void> disconnectYT(String token) async {
    AppLogger.i(_tag, 'Disconnecting YouTube Music');
    final resp = await http
        .delete(Uri.parse('$_base/v1/yt-auth'), headers: _headers(token))
        .timeout(_timeout);
    _assertOk(resp);
    AppLogger.i(_tag, 'YouTube Music disconnected successfully');
  }

  Future<Map<String, dynamic>> initYTOAuth(String token) async {
    AppLogger.i(_tag, 'Initializing YouTube Music OAuth');
    final resp = await http
        .post(
          Uri.parse('$_base/v1/yt-auth/oauth/init'),
          headers: _headers(token),
        )
        .timeout(_timeout);
    _assertOk(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkYTOAuth(
    String token,
    String deviceCode,
  ) async {
    final resp = await http
        .get(
          Uri.parse('$_base/v1/yt-auth/oauth/check/$deviceCode'),
          headers: _headers(token),
        )
        .timeout(_timeout);
    _assertOk(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  void _assertOk(http.Response resp, {bool notify = true}) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) return;

    final isUnauthorized = resp.statusCode == 401;
    final isForbidden = resp.statusCode == 403;

    if (isUnauthorized && notify) {
      AppLogger.w(_tag, 'Unauthorized (401) body: ${resp.body}');
      AuthEventBus.notifyUnauthorized();
    }

    String detail = isUnauthorized
        ? 'Incorrect username or password'
        : (isForbidden
              ? 'YouTube Music session expired'
              : 'Request failed (${resp.statusCode})');

    try {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      detail = json['detail'] as String? ?? detail;
    } catch (_) {}

    AppLogger.w(_tag, 'HTTP ${resp.statusCode}: $detail');

    if (isUnauthorized) {
      throw ServerException(message: detail, statusCode: 401);
    }

    if (isForbidden) {
      throw YTSessionExpiredException(detail);
    }

    throw ServerException(message: detail, statusCode: resp.statusCode);
  }
}
