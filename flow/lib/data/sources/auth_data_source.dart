import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/server_config.dart';
import '../../core/error/app_exception.dart';
import '../../core/logger/app_logger.dart';

class AuthDataSource {
  static const _tag = 'AuthDataSource';
  static const _timeout = Duration(seconds: 12);

  String get _base => ServerConfig.instance.baseUrl;

  Future<String> login(String username, String password) async {
    AppLogger.i(_tag, 'login($username)');
    final resp = await http
        .post(
          Uri.parse('$_base/v1/auth/login'),
          body: {'username': username, 'password': password},
        )
        .timeout(_timeout);
    _assertOk(resp);
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return json['access_token'] as String;
  }

  Future<void> signup(
      String username, String email, String password) async {
    AppLogger.i(_tag, 'signup($username)');
    AppLogger.d(_tag, 'base url: $_base full url: ${Uri.parse("$_base/v1/auth/signup")}');
    AppLogger.d(_tag, 'signup($username) - email: $email');
    final resp = await http
        .post(
          Uri.parse('$_base/v1/auth/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'username': username, 'email': email, 'password': password}),
        )
        .timeout(_timeout);
    _assertOk(resp);
  }

  Future<Map<String, dynamic>> getMe(String token) async {
    AppLogger.d(_tag, 'getMe()');
    final resp = await http
        .get(
          Uri.parse('$_base/v1/auth/me'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_timeout);
    _assertOk(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<void> connectYTCookies(
      String token, Map<String, String> cookies) async {
    AppLogger.i(_tag, 'connectYTCookies()');
    final resp = await http
        .post(
          Uri.parse('$_base/v1/yt-auth/cookies'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'cookies': cookies}),
        )
        .timeout(_timeout);
    _assertOk(resp);
  }

  Future<void> disconnectYT(String token) async {
    AppLogger.i(_tag, 'disconnectYT()');
    final resp = await http
        .delete(
          Uri.parse('$_base/v1/yt-auth'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_timeout);
    _assertOk(resp);
  }

  void _assertOk(http.Response resp) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) return;
    String detail = 'Request failed (${resp.statusCode})';
    try {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      detail = json['detail'] as String? ?? detail;
    } catch (_) {}
    AppLogger.w(_tag, 'HTTP ${resp.statusCode}: $detail');
    throw ServerException(message: detail, statusCode: resp.statusCode);
  }
}
