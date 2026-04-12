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
  final String? profileUrl;

  const HomeState({
    this.isLoading = false,
    this.error = false,
    this.errorType = AppErrorType.unknown,
    this.noSource = false,
    this.greeting = '',
    this.shelves = const [],
    this.trending = const [],
    this.allSongs = const [],
    this.profileUrl,
  });

  HomeState copyWith({
    bool? isLoading,
    bool? error,
    AppErrorType? errorType,
    bool? noSource,
    String? greeting,
    List<HomeShelf>? shelves,
    List<Song>? trending,
    List<Song>? allSongs,
    String? profileUrl,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      errorType: errorType ?? this.errorType,
      noSource: noSource ?? this.noSource,
      greeting: greeting ?? this.greeting,
      shelves: shelves ?? this.shelves,
      trending: trending ?? this.trending,
      allSongs: allSongs ?? this.allSongs,
      profileUrl: profileUrl ?? this.profileUrl,
    );
  }
}
