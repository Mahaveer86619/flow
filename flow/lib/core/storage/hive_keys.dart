// ─────────────────────────────────────────────────────────────────────────────
// HiveKeys — single source of truth for all Hive box names and entry keys.
// ─────────────────────────────────────────────────────────────────────────────

class HiveKeys {
  HiveKeys._();

  // ── Box names ────────────────────────────────────────────────────────────────
  static const String playerBox = 'flow_player';
  static const String searchBox = 'flow_search';

  // ── player box keys ──────────────────────────────────────────────────────────
  static const String likedSongIds = 'liked_song_ids';
  static const String recentlyPlayedIds = 'recently_played_ids';
  static const String volume = 'volume';
  static const String isShuffle = 'is_shuffle';
  static const String isRepeat = 'is_repeat';

  // ── search box keys ──────────────────────────────────────────────────────────
  static const String recentSearches = 'recent_searches';
}
