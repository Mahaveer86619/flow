import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import '../logger/app_logger.dart';

class YoutubeInterceptor extends Interceptor {
  static const _tag = 'YoutubeInterceptor';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains('youtube.com') ||
        options.path.contains('youtubei.googleapis.com')) {
      String? cookies;
      String? userAgent;

      try {
        cookies = await SecureStorageService.instance.getYoutubeCookies();
        userAgent = await SecureStorageService.instance.getYoutubeUserAgent();
      } catch (e) {
        AppLogger.w(_tag, 'Could not read secure storage: $e');
      }

      if (cookies != null && cookies.isNotEmpty) {
        options.headers['Cookie'] = cookies;

        // Use a regex so SAPISID= is matched regardless of surrounding whitespace
        // or ordering within the cookie string.
        final match = RegExp(r'SAPISID=([^;]+)').firstMatch(cookies);
        final sapisidValue = match?.group(1)?.trim();

        if (sapisidValue == null || sapisidValue.isEmpty) {
          AppLogger.w(
            _tag,
            'SAPISID not found in cookies; skipping Authorization header',
          );
        } else {
          final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final origin = 'https://music.youtube.com';
          final hashString = '$timestamp $sapisidValue $origin';
          final digest = sha1.convert(utf8.encode(hashString));
          options.headers['Authorization'] = 'SAPISIDHASH ${timestamp}_$digest';
        }
      } else {
        AppLogger.w(_tag, 'No cookies available; request will be unauthenticated');
      }

      // Always overwrite with the desktop Chrome UA regardless of what is stored.
      // A stored mobile UA from the WebView login flow would otherwise pass the
      // ternary check and send an Android UA with a WEB_REMIX payload — an
      // impossible combination that triggers bot detection.
      options.headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

      options.headers['Origin'] = 'https://music.youtube.com';
      options.headers['X-Origin'] = 'https://music.youtube.com';
      options.headers['Referer'] = 'https://music.youtube.com/';
      options.headers['X-Goog-AuthUser'] = '0';

      // Verification logs — placed here so Auth header is already set above.
      AppLogger.d(_tag, 'Auth Header: ${options.headers['Authorization']}');
      AppLogger.d(_tag, 'Cookie injected: ${options.headers['Cookie'] != null}');

      // Warn if the cookie string is missing account identity tokens.
      // A SAPISID alone only proves device tracking, not account login.
      if (cookies != null && cookies.isNotEmpty) {
        final hasIdentity = cookies.contains('LOGIN_INFO') ||
            cookies.contains('__Secure-1PSID') ||
            cookies.contains('__Secure-3PSID');
        if (!hasIdentity) {
          AppLogger.w(
            _tag,
            'Cookie string lacks identity tokens (LOGIN_INFO / __Secure-1PSID / __Secure-3PSID). '
            'The session may be a guest session regardless of SAPISIDHASH.',
          );
        }
      }
    }

    return handler.next(options);
  }
}
