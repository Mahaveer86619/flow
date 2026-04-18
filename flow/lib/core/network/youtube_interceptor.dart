import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import '../logger/app_logger.dart';

class YoutubeInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Only apply to YouTube domains
    if (options.path.contains('youtube.com') || options.path.contains('youtubei.googleapis.com')) {
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
        AppLogger.d('YoutubeInterceptor', 'Injected cookies for ${options.path}');
      }

      if (userAgent != null && userAgent.isNotEmpty) {
        options.headers['User-Agent'] = userAgent;
      } else {
        // Default modern user agent if not set
        options.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';
      }
      
      // Mandatory headers for YouTube Music API
      options.headers['Origin'] = 'https://music.youtube.com';
      options.headers['Referer'] = 'https://music.youtube.com/';
    }
    
    return handler.next(options);
  }
}
