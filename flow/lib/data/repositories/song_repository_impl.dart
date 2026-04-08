import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../sources/song_data_source.dart';

// ── Repository Implementation ─────────────────────────────────────────────────
//
// Bridges the data layer and domain layer:
//   - Receives raw SongModels / PlaylistModels from [SongDataSource].
//   - Converts them to domain entities via toEntity().
//   - Implements the [SongRepository] interface defined in domain.
//
// The domain and presentation layers never know this class exists — they only
// depend on the abstract [SongRepository].
// ─────────────────────────────────────────────────────────────────────────────

class SongRepositoryImpl implements SongRepository {
  final SongDataSource _dataSource;

  const SongRepositoryImpl(this._dataSource);

  @override
  List<Song> getSongs() =>
      _dataSource.fetchSongs().map((m) => m.toEntity()).toList();

  @override
  List<Playlist> getPlaylists() =>
      _dataSource.fetchPlaylists().map((m) => m.toEntity()).toList();

  @override
  List<Map<String, dynamic>> getCategories() => _dataSource.fetchCategories();
}
