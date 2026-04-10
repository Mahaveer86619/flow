import '../entities/song.dart';
import '../repositories/song_repository.dart';

/// Returns the track list for [playlistId].
class GetPlaylistTracksUseCase {
  final SongRepository _repository;
  const GetPlaylistTracksUseCase(this._repository);
  Future<List<Song>> call(String playlistId) =>
      _repository.getPlaylistTracks(playlistId);
}
