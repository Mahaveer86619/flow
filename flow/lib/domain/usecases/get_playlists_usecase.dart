import '../entities/song.dart';
import '../repositories/music_repository.dart';

/// Returns all user playlists from the repository.
class GetPlaylistsUseCase {
  final MusicRepository _repository;
  const GetPlaylistsUseCase(this._repository);
  Future<List<Playlist>> call() => _repository.getPlaylists();
}
