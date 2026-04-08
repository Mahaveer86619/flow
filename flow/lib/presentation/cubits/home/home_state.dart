import '../../../domain/entities/song.dart';

class HomeState {
  final bool isLoading;
  final String greeting;
  final List<Song> allSongs;
  final List<Song> quickAccess;
  final List<Song> listeningAgain;
  final List<Song> forgottenFavorites;
  final List<Song> musicForYou;
  final List<Map<String, dynamic>> trendingArtists;

  const HomeState({
    this.isLoading = false,
    this.greeting = '',
    this.allSongs = const [],
    this.quickAccess = const [],
    this.listeningAgain = const [],
    this.forgottenFavorites = const [],
    this.musicForYou = const [],
    this.trendingArtists = const [],
  });
}
