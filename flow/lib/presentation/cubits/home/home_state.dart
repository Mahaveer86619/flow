import '../../../domain/entities/home_data.dart';
import '../../../domain/entities/song.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  final List<HomeShelf> shelves;
  final HomeStatus status;
  final String? error;

  const HomeState({
    this.shelves = const [],
    this.status = HomeStatus.initial,
    this.error,
  });

  HomeState copyWith({
    List<HomeShelf>? shelves,
    HomeStatus? status,
    String? error,
  }) {
    return HomeState(
      shelves: shelves ?? this.shelves,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}
