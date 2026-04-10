import '../../../core/error/app_exception.dart';
import '../../../domain/entities/song.dart';

class LibraryState {
  final bool isLoading;
  final bool error;
  final AppErrorType errorType;
  final int filterIndex;
  final List<Playlist> playlists;

  static const filterOptions = ['Playlists', 'Albums', 'Artists', 'Downloads'];

  const LibraryState({
    this.isLoading = false,
    this.error = false,
    this.errorType = AppErrorType.unknown,
    this.filterIndex = 0,
    required this.playlists,
  });

  LibraryState copyWith({
    bool? isLoading,
    bool? error,
    AppErrorType? errorType,
    int? filterIndex,
  }) =>
      LibraryState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        errorType: errorType ?? this.errorType,
        filterIndex: filterIndex ?? this.filterIndex,
        playlists: playlists,
      );
}
