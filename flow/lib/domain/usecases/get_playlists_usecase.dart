import '../entities/song.dart';
import '../repositories/song_repository.dart';

/// Returns all user playlists from the repository.
class GetPlaylistsUseCase {
  final SongRepository _repository;
  const GetPlaylistsUseCase(this._repository);
  Future<List<Playlist>> call() => _repository.getPlaylists();
}
