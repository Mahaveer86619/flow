import 'song.dart';

class HomeShelf {
  final String title;
  final String? section;
  final List<HomeItem> items;

  const HomeShelf({
    required this.title,
    required this.items,
    this.section,
  });
}

enum HomeItemType { song, artist, album, playlist }

class HomeItem {
  final HomeItemType type;
  final dynamic data; // Can be Song, Artist (Map), or Playlist

  const HomeItem({required this.type, required this.data});
}

class HomeData {
  final List<HomeShelf> shelves;
  final List<Song> trending;
  final String? profileUrl;

  const HomeData({
    this.shelves = const [],
    this.trending = const [],
    this.profileUrl,
  });

  /// Deduplicated union of all songs in all shelves — used as the player queue.
  List<Song> get allSongs {
    final seen = <String>{};
    final songs = <Song>[];

    for (final shelf in shelves) {
      for (final item in shelf.items) {
        if (item.type == HomeItemType.song && item.data is Song) {
          final s = item.data as Song;
          if (seen.add(s.id)) {
            songs.add(s);
          }
        }
      }
    }

    for (final s in trending) {
      if (seen.add(s.id)) {
        songs.add(s);
      }
    }

    return songs;
  }
}
