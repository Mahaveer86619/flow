import '../../../core/error/app_exception.dart';
import '../../../domain/entities/song.dart';

class HomeState {
  final bool isLoading;
  final bool error;
  final AppErrorType errorType;
  final String greeting;
  final List<Song> quickAccess;
  final List<Song> listeningAgain;
  final List<Song> forgottenFavorites;
  final List<Song> musicForYou;
  final List<Map<String, dynamic>> trendingArtists;
  final List<Song> trending;

  /// Deduplicated union of all sections — used as the global player queue.
  final List<Song> allSongs;

  const HomeState({
    this.isLoading = false,
    this.error = false,
    this.errorType = AppErrorType.unknown,
    this.greeting = '',
    this.quickAccess = const [],
    this.listeningAgain = const [],
    this.forgottenFavorites = const [],
    this.musicForYou = const [],
    this.trendingArtists = const [],
    this.trending = const [],
    this.allSongs = const [],
  });
}
