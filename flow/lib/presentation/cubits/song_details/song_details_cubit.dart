import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/music_repository.dart';
import 'song_details_state.dart';

class SongDetailsCubit extends Cubit<SongDetailsState> {
  final MusicRepository _musicRepository;

  SongDetailsCubit({required MusicRepository musicRepository})
      : _musicRepository = musicRepository,
        super(const SongDetailsState());

  Future<void> fetchDetails(String videoId, String? artistId) async {
    if (state.videoId == videoId && state.isSuccess) return;

    emit(state.copyWith(
      status: SongDetailsStatus.loading,
      videoId: videoId,
      error: null,
    ));

    try {
      // Fetch both in parallel for efficiency
      final results = await Future.wait([
        _musicRepository.getSongDetails(videoId),
        if (artistId != null && artistId.isNotEmpty)
          _musicRepository.getArtistDetails(artistId)
        else
          Future.value(<String, dynamic>{}),
      ]);

      emit(state.copyWith(
        status: SongDetailsStatus.success,
        songDetails: results[0],
        artistDetails: results[1],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SongDetailsStatus.error,
        error: e.toString(),
      ));
    }
  }

  void reset() => emit(const SongDetailsState());
}
