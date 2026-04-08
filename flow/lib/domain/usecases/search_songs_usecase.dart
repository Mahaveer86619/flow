import '../entities/song.dart';
import '../repositories/song_repository.dart';

/// Filters the song catalogue by [query] across title, artist, and album.
///
/// Returns an empty list when [query] is empty.
/// Business rule lives here — SearchCubit stays free of filtering logic.
class SearchSongsUseCase {
  final SongRepository _repository;

  const SearchSongsUseCase(this._repository);

  List<Song> call(String query) {
    if (query.trim().isEmpty) return const [];
    final q = query.toLowerCase();
    return _repository.getSongs().where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q);
    }).toList();
  }
}
