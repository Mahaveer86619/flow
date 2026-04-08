import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_songs_usecase.dart';
import 'home_state.dart';

export 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required GetSongsUseCase getSongs})
      : super(const HomeState(isLoading: true)) {
    _load(getSongs);
  }

  Future<void> _load(GetSongsUseCase getSongs) async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (isClosed) return;

    final songs = getSongs();
    final hour = DateTime.now().hour;

    final artists = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final song in songs) {
      if (seen.add(song.artist)) {
        artists.add({
          'name': song.artist,
          'colorPrimary': song.colorPrimary,
          'colorSecondary': song.colorSecondary,
        });
      }
    }

    emit(HomeState(
      isLoading: false,
      greeting: hour < 12
          ? 'Good morning'
          : hour < 17
              ? 'Good afternoon'
              : 'Good evening',
      allSongs: songs,
      quickAccess: songs.take(6).toList(),
      listeningAgain: songs.take(6).toList(),
      forgottenFavorites: songs.reversed.take(6).toList(),
      musicForYou: songs,
      trendingArtists: artists,
    ));
  }
}
