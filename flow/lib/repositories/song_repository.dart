import '../models/song.dart';

/// Abstract contract for all song/playlist data access.
/// Swap this implementation (mock → network) without touching ViewModels.
abstract class SongRepository {
  List<Song> getSongs();
  List<Playlist> getPlaylists();
  List<Map<String, dynamic>> getCategories();
}
