import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/song.dart';
import '../repositories/song_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class LibraryState {
  final int filterIndex;
  final List<Playlist> playlists;

  static const filterOptions = ['Playlists', 'Albums', 'Artists', 'Downloads'];

  const LibraryState({
    this.filterIndex = 0,
    required this.playlists,
  });

  LibraryState copyWith({int? filterIndex}) {
    return LibraryState(
      filterIndex: filterIndex ?? this.filterIndex,
      playlists: playlists,
    );
  }
}

// ── Cubit ──────────────────────────────────────────────────────────────────────

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(SongRepository repository)
      : super(LibraryState(playlists: repository.getPlaylists()));

  void setFilter(int index) {
    if (state.filterIndex == index) return;
    emit(state.copyWith(filterIndex: index));
  }
}
