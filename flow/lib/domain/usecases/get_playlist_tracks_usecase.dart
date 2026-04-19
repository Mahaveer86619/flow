import '../entities/song.dart';
import '../repositories/music_repository.dart';

/// Returns the track list for [playlistId].
class GetPlaylistTracksUseCase {
  final MusicRepository _repository;
  const GetPlaylistTracksUseCase(this._repository);
  Future<List<Song>> call(String playlistId) =>
      _repository.getPlaylistTracks(playlistId);
}
