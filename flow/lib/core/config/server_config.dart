import '../logger/app_logger.dart';
import '../storage/local_storage.dart';

/// Holds the active base URL for the flow-source backend.
/// Initialised in main() after LocalStorage is ready.
/// Both ApiSongDataSource and PlayerBloc read from here dynamically.
class ServerConfig {
  static final ServerConfig _i = ServerConfig._();
  static ServerConfig get instance => _i;
  ServerConfig._();

  late String _fallback;
  late String _baseUrl;

  String get baseUrl => _baseUrl;
  String get fallbackUrl => _fallback;
  bool get isCustom => _baseUrl != _fallback;

  void init(String envUrl) {
    _fallback = envUrl;
    final stored = LocalStorage.instance.serverUrl;
    if (stored != null) {
      AppLogger.i(
        'ServerConfig',
        'Using custom server URL from storage: $stored',
      );
      _baseUrl = stored;
    } else {
      _baseUrl = envUrl;
    }
  }

  void setCustomUrl(String url) {
    _baseUrl = url;
    LocalStorage.instance.saveServerUrl(url);
  }

  void clearCustomUrl() {
    _baseUrl = _fallback;
    LocalStorage.instance.clearServerUrl();
  }
}
