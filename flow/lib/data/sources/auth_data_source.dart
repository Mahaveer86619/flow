import '../../core/logger/app_logger.dart';

/// Standalone AuthDataSource.
/// In the new architecture, we don't have a central backend for user accounts.
/// This class now acts as a local stub.
class AuthDataSource {
  static const _tag = 'AuthDataSource';

  Future<String> login(String username, String password) async {
    AppLogger.i(_tag, 'Standalone login: Treating all logins as successful local sessions');
    return 'local_session_token';
  }

  Future<void> signup(String username, String email, String password) async {
    AppLogger.i(_tag, 'Standalone signup: No-op');
  }

  Future<Map<String, dynamic>> getMe(String token) async {
    return {
      'username': 'Guest User',
      'email': 'guest@flow.local',
      'has_yt_auth': false,
    };
  }

  Future<Map<String, dynamic>> updateSettings(
    String token,
    Map<String, dynamic> settings,
  ) async {
    return {'settings': settings};
  }

  // Other methods become no-ops or return empty data
  Future<void> connectYTCookies(String token, Map<String, String> cookies) async {}
  Future<Map<String, dynamic>> refreshProfile(String token) async => {};
  Future<void> disconnectYT(String token) async {}
  Future<Map<String, dynamic>> initYTOAuth(String token) async => {};
  Future<Map<String, dynamic>> checkYTOAuth(String token, String deviceCode) async => {};
}
