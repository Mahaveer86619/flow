import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/song.dart';
import '../repositories/song_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class HomeState {
  final String greeting;
  final List<Song> allSongs;
  final List<Song> quickAccess;
  final List<Song> listeningAgain;
  final List<Song> forgottenFavorites;
  final List<Song> musicForYou;
  final List<Map<String, dynamic>> trendingArtists;

  const HomeState({
    required this.greeting,
    required this.allSongs,
    required this.quickAccess,
    required this.listeningAgain,
    required this.forgottenFavorites,
    required this.musicForYou,
    required this.trendingArtists,
  });
}

// ── Cubit ──────────────────────────────────────────────────────────────────────

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(SongRepository repository) : super(_build(repository));

  static HomeState _build(SongRepository repository) {
    final songs = repository.getSongs();
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

    return HomeState(
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
    );
  }
}
