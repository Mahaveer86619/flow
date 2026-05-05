import '../../../domain/entities/home_data.dart';
import '../../../domain/entities/song.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  final List<HomeShelf> shelves;
  final List<Song> allSongs;
  final HomeStatus status;
  final String? error;
  final String? errorCode;

  const HomeState({
    this.shelves = const [],
    this.allSongs = const [],
    this.status = HomeStatus.initial,
    this.error,
    this.errorCode,
  });

  HomeState copyWith({
    List<HomeShelf>? shelves,
    List<Song>? allSongs,
    HomeStatus? status,
    String? error,
    String? errorCode,
  }) {
    return HomeState(
      shelves: shelves ?? this.shelves,
      allSongs: allSongs ?? this.allSongs,
      status: status ?? this.status,
      error: error ?? this.error,
      errorCode: errorCode ?? this.errorCode,
    );
  }
}
