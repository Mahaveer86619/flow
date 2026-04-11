import '../../../core/error/app_exception.dart';
import '../../../domain/entities/home_data.dart';
import '../../../domain/entities/song.dart';

class HomeState {
  final bool isLoading;
  final bool error;
  final AppErrorType errorType;
  final bool noSource;
  final String greeting;
  final List<HomeShelf> shelves;
  final List<Song> trending;
  final List<Song> allSongs;

  const HomeState({
    this.isLoading = false,
    this.error = false,
    this.errorType = AppErrorType.unknown,
    this.noSource = false,
    this.greeting = '',
    this.shelves = const [],
    this.trending = const [],
    this.allSongs = const [],
  });
}
