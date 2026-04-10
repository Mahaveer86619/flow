import '../entities/song.dart';
import '../repositories/song_repository.dart';

/// Returns songs matching [query] via the repository's search method.
///
/// For the mock, this filters in-memory. For the API data source, it calls
/// the backend search endpoint. Either way the cubit stays unchanged.
class SearchSongsUseCase {
  final SongRepository _repository;
  const SearchSongsUseCase(this._repository);
  Future<List<Song>> call(String query) => _repository.searchSongs(query);
}
