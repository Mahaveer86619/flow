import '../entities/song.dart';

// ── Repository Interface ──────────────────────────────────────────────────────
//
// Defined in domain so that use cases depend only on this abstraction.
// The concrete implementation lives in the data layer and is injected at
// the composition root (main.dart) — dependency inversion in action.
// ─────────────────────────────────────────────────────────────────────────────

abstract class SongRepository {
  /// Returns the full catalogue of available songs.
  List<Song> getSongs();

  /// Returns all user playlists.
  List<Playlist> getPlaylists();

  /// Returns browse categories (name + color).
  List<Map<String, dynamic>> getCategories();
}
