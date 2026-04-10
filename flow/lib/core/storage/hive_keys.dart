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

  // ── settings box ─────────────────────────────────────────────────────────────
  static const String settingsBox = 'flow_settings';
  static const String serverUrl = 'server_url';
  static const String themeMode = 'theme_mode';
  static const String eqPreset = 'eq_preset';
  static const String downloadQuality = 'download_quality';

  // ── auth box ─────────────────────────────────────────────────────────────────
  static const String authBox = 'flow_auth';
  static const String jwtToken = 'jwt_token';
  static const String cachedUsername = 'cached_username';
  static const String cachedEmail = 'cached_email';
  static const String cachedHasYtAuth = 'cached_has_yt_auth';
}
