import '../models/playlist_model.dart';
import '../models/song_model.dart';

// ── Data Source Interface ─────────────────────────────────────────────────────
//
// Abstracts WHERE the raw data comes from — mock, REST API, local DB, etc.
// SongRepositoryImpl depends only on this interface, so swapping the source
// (e.g. mock → Retrofit client) requires zero changes to the repository or
// anything above it.
// ─────────────────────────────────────────────────────────────────────────────

abstract class SongDataSource {
  /// Fetches the raw song catalogue.
  List<SongModel> fetchSongs();

  /// Fetches the raw playlist catalogue.
  List<PlaylistModel> fetchPlaylists();

  /// Fetches browse category metadata.
  List<Map<String, dynamic>> fetchCategories();
}
