import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';
import '../logger/app_logger.dart';

class YoutubeInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only apply to YouTube domains
    if (options.path.contains('youtube.com') ||
        options.path.contains('youtubei.googleapis.com')) {
      String? cookies;
      String? userAgent;

      try {
        cookies = await SecureStorageService.instance.getYoutubeCookies();
        userAgent = await SecureStorageService.instance.getYoutubeUserAgent();
      } catch (e) {
        // ServicesBinding not initialized (usually in pure unit tests)
        AppLogger.w('YoutubeInterceptor', 'Could not read secure storage: $e');
      }

      if (cookies != null && cookies.isNotEmpty) {
        options.headers['Cookie'] = cookies;
        AppLogger.d(
          'YoutubeInterceptor',
          'Injected cookies for ${options.path}',
        );

        // Generate SAPISIDHASH for Authorization header if SAPISID exists
        final sapisid = _extractCookie(cookies, 'SAPISID');
        if (sapisid != null) {
          final origin =
              options.headers['Origin'] ?? 'https://music.youtube.com';
          final authHeader = _generateSapisidHash(sapisid, origin);
          options.headers['Authorization'] = 'SAPISIDHASH $authHeader';
        }
      }

      if (userAgent != null && userAgent.isNotEmpty) {
        options.headers['User-Agent'] = userAgent;
      } else {
        // Default modern user agent if not set
        options.headers['User-Agent'] =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';
      }

      // Mandatory headers for YouTube Music API
      options.headers['Origin'] = 'https://music.youtube.com';
      options.headers['Referer'] = 'https://music.youtube.com/';
      options.headers['X-Goog-AuthUser'] = '0';
      options.headers['X-YouTube-Client-Name'] = '67'; // ANDROID_MUSIC
      options.headers['X-YouTube-Client-Version'] = '7.03.52';

    }

    return handler.next(options);
  }

  String? _extractCookie(String cookies, String name) {
    try {
      final cookieList = cookies.split(';');
      for (final cookie in cookieList) {
        final parts = cookie.trim().split('=');
        if (parts.length >= 2 && parts[0] == name) {
          return parts.sublist(1).join('=');
        }
      }
    } catch (_) {}
    return null;
  }

  String _generateSapisidHash(String sapisid, String origin) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payload = '$timestamp $sapisid $origin';
    final hash = sha1.convert(utf8.encode(payload)).toString();
    return '${timestamp}_$hash';
  }
}
