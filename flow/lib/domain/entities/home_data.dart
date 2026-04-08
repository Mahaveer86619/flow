import 'song.dart';

// ── HomeData ──────────────────────────────────────────────────────────────────
//
// The structured home screen payload returned by GET /api/home.
// Each field maps 1-to-1 to a UI section; the backend owns the split logic.
// ─────────────────────────────────────────────────────────────────────────────

class HomeData {
  final List<Song> quickAccess;
  final List<Song> listeningAgain;
  final List<Song> forgottenFavorites;
  final List<Song> musicForYou;

  /// Raw artist maps — each has at minimum {name: String, thumbnailUrl: String?}.
  /// colorPrimary / colorSecondary are derived by the data layer so the
  /// presentation layer can render gradient fallbacks without API round-trips.
  final List<Map<String, dynamic>> trendingArtists;

  /// Worldwide chart songs (from /api/v1/home → trending field).
  final List<Song> trending;

  const HomeData({
    this.quickAccess = const [],
    this.listeningAgain = const [],
    this.forgottenFavorites = const [],
    this.musicForYou = const [],
    this.trendingArtists = const [],
    this.trending = const [],
  });

  /// Deduplicated union of all song sections — used as the player queue so
  /// "next" works across the entire home feed.
  List<Song> get allSongs {
    final seen = <String>{};
    return [
      ...quickAccess,
      ...listeningAgain,
      ...forgottenFavorites,
      ...musicForYou,
      ...trending,
    ].where((s) => seen.add(s.id)).toList();
  }
}
