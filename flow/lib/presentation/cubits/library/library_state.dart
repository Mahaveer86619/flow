import '../../../domain/entities/song.dart';

class LibraryState {
  final int filterIndex;
  final List<Playlist> playlists;

  static const filterOptions = ['Playlists', 'Albums', 'Artists', 'Downloads'];

  const LibraryState({this.filterIndex = 0, required this.playlists});

  LibraryState copyWith({int? filterIndex}) => LibraryState(
        filterIndex: filterIndex ?? this.filterIndex,
        playlists: playlists,
      );
}
