import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/server_config.dart';
import '../../core/error/app_exception.dart';
import '../../core/logger/app_logger.dart';

class BrowserFrame {
  final String screenshot; // base64 PNG
  final bool isActive;
  const BrowserFrame({required this.screenshot, required this.isActive});
}

class AdminDataSource {
  static const _tag = 'AdminDataSource';
  static const _timeout = Duration(seconds: 30);

  String get _base => ServerConfig.instance.baseUrl;

  Map<String, String> _headers(String token) => {
    'User-Agent': 'FlowMusicApp/1.0',
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Future<BrowserFrame> browserStart(String token) async {
    AppLogger.i(_tag, 'Starting server browser session');
    final resp = await http
        .post(Uri.parse('$_base/v1/admin/browser/start'), headers: _headers(token))
        .timeout(_timeout);
    _assertOk(resp, 'browserStart');
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return BrowserFrame(
      screenshot: body['screenshot'] as String,
      isActive: body['is_active'] as bool,
    );
  }

  Future<BrowserFrame> browserFrame(String token) async {
    final resp = await http
        .get(Uri.parse('$_base/v1/admin/browser/frame'), headers: _headers(token))
        .timeout(_timeout);
    _assertOk(resp, 'browserFrame');
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return BrowserFrame(
      screenshot: body['screenshot'] as String,
      isActive: body['is_active'] as bool,
    );
  }

  Future<BrowserFrame> browserTap(String token, double x, double y) async {
    final resp = await http
        .post(
          Uri.parse('$_base/v1/admin/browser/tap'),
          headers: _headers(token),
          body: jsonEncode({'x': x, 'y': y}),
        )
        .timeout(_timeout);
    _assertOk(resp, 'browserTap');
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return BrowserFrame(screenshot: body['screenshot'] as String, isActive: true);
  }

  Future<BrowserFrame> browserType(String token, String text) async {
    final resp = await http
        .post(
          Uri.parse('$_base/v1/admin/browser/type'),
          headers: _headers(token),
          body: jsonEncode({'text': text}),
        )
        .timeout(_timeout);
    _assertOk(resp, 'browserType');
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return BrowserFrame(screenshot: body['screenshot'] as String, isActive: true);
  }

  Future<BrowserFrame> browserKey(String token, String key) async {
    final resp = await http
        .post(
          Uri.parse('$_base/v1/admin/browser/key'),
          headers: _headers(token),
          body: jsonEncode({'key': key}),
        )
        .timeout(_timeout);
    _assertOk(resp, 'browserKey');
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return BrowserFrame(screenshot: body['screenshot'] as String, isActive: true);
  }

  Future<int> browserSave(String token) async {
    AppLogger.i(_tag, 'Saving server browser cookies');
    final resp = await http
        .post(Uri.parse('$_base/v1/admin/browser/save'), headers: _headers(token))
        .timeout(_timeout);
    _assertOk(resp, 'browserSave');
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return body['count'] as int;
  }

  Future<void> browserStop(String token) async {
    await http
        .delete(Uri.parse('$_base/v1/admin/browser/stop'), headers: _headers(token))
        .timeout(_timeout);
  }

  void _assertOk(http.Response resp, String op) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) return;
    AppLogger.e(_tag, '$op failed: ${resp.statusCode} — ${resp.body}');
    throw ServerException(message: resp.body, statusCode: resp.statusCode);
  }
}
