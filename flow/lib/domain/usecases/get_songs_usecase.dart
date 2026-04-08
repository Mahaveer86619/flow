import '../entities/song.dart';
import '../repositories/song_repository.dart';

/// Returns the full song catalogue from the repository.
///
/// Use cases encapsulate a single business operation and act as the boundary
/// between presentation (Cubits/BLoCs) and data (repositories).
/// Swap the repository implementation without touching a single Cubit.
class GetSongsUseCase {
  final SongRepository _repository;

  const GetSongsUseCase(this._repository);

  List<Song> call() => _repository.getSongs();
}
