import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../logger/app_logger.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  static SecureStorageService get instance => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  SecureStorageService._internal();

  static const String _ytCookiesKey = 'yt_cookies';
  static const String _spotifyCookiesKey = 'spotify_cookies';
  static const String _ytUserAgentKey = 'yt_user_agent';

  Future<void> saveYoutubeCookies(String cookies) async {
    try {
      await _storage.write(key: _ytCookiesKey, value: cookies);
    } catch (e) {
      AppLogger.e('SecureStorageService', 'Error saving YouTube cookies', e);
    }
  }

  Future<String?> getYoutubeCookies() async {
    try {
      // In unit tests, the binding might not be initialized.
      // This is expected and we should return null gracefully.
      return await _storage.read(key: _ytCookiesKey);
    } catch (e) {
      if (e.toString().contains('Binding has not yet been initialized')) {
        return null;
      }
      AppLogger.e('SecureStorageService', 'Error reading YouTube cookies', e);
      return null;
    }
  }

  Future<void> saveSpotifyCookies(String cookies) async {
    try {
      await _storage.write(key: _spotifyCookiesKey, value: cookies);
    } catch (e) {
      AppLogger.e('SecureStorageService', 'Error saving Spotify cookies', e);
    }
  }

  Future<String?> getSpotifyCookies() async {
    try {
      return await _storage.read(key: _spotifyCookiesKey);
    } catch (e) {
      AppLogger.e('SecureStorageService', 'Error reading Spotify cookies', e);
      return null;
    }
  }

  Future<void> saveYoutubeUserAgent(String ua) async {
    try {
      await _storage.write(key: _ytUserAgentKey, value: ua);
    } catch (e) {
      AppLogger.e('SecureStorageService', 'Error saving YouTube User-Agent', e);
    }
  }

  Future<String?> getYoutubeUserAgent() async {
    try {
      // In unit tests, the binding might not be initialized.
      return await _storage.read(key: _ytUserAgentKey);
    } catch (e) {
      if (e.toString().contains('Binding has not yet been initialized')) {
        return null;
      }
      AppLogger.e('SecureStorageService', 'Error reading YouTube User-Agent', e);
      return null;
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      AppLogger.e('SecureStorageService', 'Error clearing all secure storage', e);
    }
  }
}
