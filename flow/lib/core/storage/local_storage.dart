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

  Future<void> init() async {
    await Hive.initFlutter();
    _player = await Hive.openBox(HiveKeys.playerBox);
    _search = await Hive.openBox(HiveKeys.searchBox);
    AppLogger.i('LocalStorage', 'Hive initialised. '
        'Liked=${likedSongIds.length}  '
        'Volume=$volume  '
        'Shuffle=$isShuffle  '
        'Repeat=$isRepeat  '
        'Searches=${recentSearches.length}');
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
}
