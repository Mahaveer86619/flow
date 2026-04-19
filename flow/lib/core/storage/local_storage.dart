import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show visibleForTesting;
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
  static LocalStorage? _instance;
  static LocalStorage get instance => _instance ??= LocalStorage._();

  @visibleForTesting
  static set instance(LocalStorage mock) => _instance = mock;

  late final Box _player;
  late final Box _search;
  late final Box _settings;
  late final Box _auth;
  late final Box _downloads;
  late final Box _metadata;
  late final Box _songMetadataCache;

  final _likedSongsController = StreamController<List<String>>.broadcast();
  Stream<List<String>> get likedSongsStream => _likedSongsController.stream;

  Future<void> init([String? path]) async {
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }
    _player = await Hive.openBox(HiveKeys.playerBox);
    _search = await Hive.openBox(HiveKeys.searchBox);
    _settings = await Hive.openBox(HiveKeys.settingsBox);
    _auth = await Hive.openBox(HiveKeys.authBox);
    _downloads = await Hive.openBox(HiveKeys.downloadsBox);
    _metadata = await Hive.openBox(HiveKeys.metadataBox);
    _songMetadataCache = await Hive.openBox(HiveKeys.songMetadataBox);
    AppLogger.i(
      'LocalStorage',
      'Hive initialised. '
          'Liked=${likedSongIds.length}  '
          'Volume=$volume  '
          'Shuffle=$isShuffle  '
          'Repeat=$isRepeat  '
          'Searches=${recentSearches.length}  '
          'Downloads=${_downloads.length}  '
          'Metadata=${_metadata.length}  '
          'Cache=${_songMetadataCache.length}  '
          'Auth=${jwtToken != null ? "token present" : "no token"}',
    );
  }

  // ── Player ───────────────────────────────────────────────────────────────────

  List<String> get likedSongIds =>
      (_player.get(HiveKeys.likedSongIds) as List?)?.cast<String>() ?? [];

  void saveLikedSongIds(List<String> ids) {
    final listToSave = List<String>.from(ids);
    _player.put(HiveKeys.likedSongIds, listToSave);
    _likedSongsController.add(listToSave);
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

  String get _platformDownloadPathKey {
    if (Platform.isWindows) return '${HiveKeys.downloadPath}_windows';
    if (Platform.isAndroid) return '${HiveKeys.downloadPath}_android';
    if (Platform.isIOS) return '${HiveKeys.downloadPath}_ios';
    if (Platform.isMacOS) return '${HiveKeys.downloadPath}_macos';
    if (Platform.isLinux) return '${HiveKeys.downloadPath}_linux';
    return HiveKeys.downloadPath;
  }

  String? get downloadPath =>
      _settings.get(_platformDownloadPathKey) as String?;
  void saveDownloadPath(String path) =>
      _settings.put(_platformDownloadPathKey, path);
  void clearDownloadPath() => _settings.delete(_platformDownloadPathKey);

  Map<String, String> get allPlatformDownloadPaths {
    final Map<String, String> paths = {};
    final platforms = ['windows', 'android', 'ios', 'macos', 'linux'];
    for (final p in platforms) {
      final key = '${HiveKeys.downloadPath}_$p';
      final val = _settings.get(key) as String?;
      if (val != null) paths[p] = val;
    }
    return paths;
  }

  void saveAllDownloadPaths(Map<String, dynamic> paths) {
    paths.forEach((key, value) {
      if (value is String) {
        _settings.put('${HiveKeys.downloadPath}_$key', value);
      }
    });
  }

  String? get appVersion => _settings.get(HiveKeys.appVersion) as String?;
  void saveAppVersion(String version) =>
      _settings.put(HiveKeys.appVersion, version);

  /// Clears search history and player state, but preserves critical settings
  /// (Server URL, Theme, Downloads path) and Auth.
  Future<void> clearCache() async {
    AppLogger.w(
      'LocalStorage',
      'Clearing local cache (player, search, metadata cache)...',
    );
    await _player.clear();
    await _search.clear();
    await _songMetadataCache.clear();
  }

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

  void saveHasYtAuth(bool value) => _auth.put(HiveKeys.cachedHasYtAuth, value);

  void clearAuth() {
    _auth.delete(HiveKeys.jwtToken);
    _auth.delete(HiveKeys.cachedUsername);
    _auth.delete(HiveKeys.cachedEmail);
    _auth.delete(HiveKeys.cachedHasYtAuth);
    AppLogger.d('LocalStorage', 'Auth cleared');
  }

  // ── Downloads ────────────────────────────────────────────────────────────────

  Map<String, String> get downloadedPaths =>
      _downloads.toMap().cast<String, String>();

  String? getDownloadedPath(String songId) => _downloads.get(songId) as String?;

  void saveDownloadMapping(String songId, String path) =>
      _downloads.put(songId, path);

  void saveDownloadMetadata(String songId, Map<String, dynamic> metadata) =>
      _metadata.put(songId, metadata);

  Map<String, dynamic>? getDownloadMetadata(String songId) {
    final data = _metadata.get(songId);
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  void removeDownloadMapping(String songId) {
    _downloads.delete(songId);
    _metadata.delete(songId);
  }

  // ── General Cache ───────────────────────────────────────────────────────────

  void saveCachedMetadata(String key, dynamic data) {
    _songMetadataCache.put(key, data);
  }

  dynamic getCachedMetadata(String key) {
    return _songMetadataCache.get(key);
  }
}
