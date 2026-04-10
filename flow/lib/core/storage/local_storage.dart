import 'package:hive_flutter/hive_flutter.dart';
import '../logger/app_logger.dart';
import 'hive_keys.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LocalStorage — thin singleton wrapper over Hive.
//
// Stores player preferences (liked IDs, volume, shuffle, repeat) and search
// history persistently across app restarts.
//
// Initialise once with [init()] before runApp().
// ─────────────────────────────────────────────────────────────────────────────

class LocalStorage {
  LocalStorage._();
  static final LocalStorage instance = LocalStorage._();

  late final Box _player;
  late final Box _search;
  late final Box _settings;
  late final Box _auth;

  Future<void> init() async {
    await Hive.initFlutter();
    _player = await Hive.openBox(HiveKeys.playerBox);
    _search = await Hive.openBox(HiveKeys.searchBox);
    _settings = await Hive.openBox(HiveKeys.settingsBox);
    _auth = await Hive.openBox(HiveKeys.authBox);
    AppLogger.i('LocalStorage', 'Hive initialised. '
        'Liked=${likedSongIds.length}  '
        'Volume=$volume  '
        'Shuffle=$isShuffle  '
        'Repeat=$isRepeat  '
        'Searches=${recentSearches.length}  '
        'Auth=${jwtToken != null ? "token present" : "no token"}');
  }

  // ── Player ───────────────────────────────────────────────────────────────────

  List<String> get likedSongIds =>
      (_player.get(HiveKeys.likedSongIds) as List?)?.cast<String>() ?? [];

  void saveLikedSongIds(List<String> ids) {
    _player.put(HiveKeys.likedSongIds, ids);
    AppLogger.d('LocalStorage', 'Persisted ${ids.length} liked IDs');
  }

  List<String> get recentlyPlayedIds =>
      (_player.get(HiveKeys.recentlyPlayedIds) as List?)?.cast<String>() ?? [];

  void saveRecentlyPlayedIds(List<String> ids) {
    _player.put(HiveKeys.recentlyPlayedIds, ids);
    AppLogger.d('LocalStorage', 'Persisted ${ids.length} recently-played IDs');
  }

  double get volume =>
      (_player.get(HiveKeys.volume) as num?)?.toDouble() ?? 0.7;

  void saveVolume(double v) => _player.put(HiveKeys.volume, v);

  bool get isShuffle => (_player.get(HiveKeys.isShuffle) as bool?) ?? false;

  void saveShuffle(bool v) => _player.put(HiveKeys.isShuffle, v);

  bool get isRepeat => (_player.get(HiveKeys.isRepeat) as bool?) ?? false;

  void saveRepeat(bool v) => _player.put(HiveKeys.isRepeat, v);

  // ── Search ───────────────────────────────────────────────────────────────────

  List<String> get recentSearches =>
      (_search.get(HiveKeys.recentSearches) as List?)?.cast<String>() ?? [];

  void saveRecentSearches(List<String> searches) {
    _search.put(HiveKeys.recentSearches, searches);
    AppLogger.d('LocalStorage', 'Persisted ${searches.length} recent searches');
  }

  // ── Settings ─────────────────────────────────────────────────────────────────

  String? get serverUrl => _settings.get(HiveKeys.serverUrl) as String?;
  void saveServerUrl(String url) => _settings.put(HiveKeys.serverUrl, url);
  void clearServerUrl() => _settings.delete(HiveKeys.serverUrl);

  String get themeModePref =>
      (_settings.get(HiveKeys.themeMode) as String?) ?? 'dark';
  void saveThemeMode(String mode) => _settings.put(HiveKeys.themeMode, mode);

  String get eqPreset =>
      (_settings.get(HiveKeys.eqPreset) as String?) ?? 'Normal';
  void saveEqPreset(String preset) => _settings.put(HiveKeys.eqPreset, preset);

  String get downloadQuality =>
      (_settings.get(HiveKeys.downloadQuality) as String?) ?? 'High';
  void saveDownloadQuality(String q) =>
      _settings.put(HiveKeys.downloadQuality, q);

  // ── Auth ─────────────────────────────────────────────────────────────────────

  String? get jwtToken => _auth.get(HiveKeys.jwtToken) as String?;
  String? get cachedUsername => _auth.get(HiveKeys.cachedUsername) as String?;
  String? get cachedEmail => _auth.get(HiveKeys.cachedEmail) as String?;
  bool get cachedHasYtAuth =>
      (_auth.get(HiveKeys.cachedHasYtAuth) as bool?) ?? false;

  void saveAuth({
    required String token,
    required String username,
    required String email,
    required bool hasYtAuth,
  }) {
    _auth.put(HiveKeys.jwtToken, token);
    _auth.put(HiveKeys.cachedUsername, username);
    _auth.put(HiveKeys.cachedEmail, email);
    _auth.put(HiveKeys.cachedHasYtAuth, hasYtAuth);
    AppLogger.d('LocalStorage', 'Auth saved for $username');
  }

  void saveHasYtAuth(bool value) =>
      _auth.put(HiveKeys.cachedHasYtAuth, value);

  void clearAuth() {
    _auth.delete(HiveKeys.jwtToken);
    _auth.delete(HiveKeys.cachedUsername);
    _auth.delete(HiveKeys.cachedEmail);
    _auth.delete(HiveKeys.cachedHasYtAuth);
    AppLogger.d('LocalStorage', 'Auth cleared');
  }
}
