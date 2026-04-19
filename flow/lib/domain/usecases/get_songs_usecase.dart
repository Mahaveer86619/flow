import '../entities/song.dart';
import '../repositories/music_repository.dart';

/// Returns a flat song catalogue.
/// Not used directly by any screen cubit — kept for compatibility and testing.
/// Screens use [GetHomeDataUseCase] or [SearchSongsUseCase] instead.
class GetSongsUseCase {
  final MusicRepository _repository;
  const GetSongsUseCase(this._repository);

  /// Falls back to fetching and flattening home data.
  Future<List<Song>> call() async {
    final home = await _repository.getHomeData();
    return home.allSongs;
  }
}
