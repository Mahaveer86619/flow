import 'song.dart';

class HomeShelf {
  final String title;
  final String? section;

  /// Raw InnerTube itemSize string (e.g. COLLECTION_STYLE_ITEM_SIZE_MEDIUM).
  /// The presentation layer can use this as a layout hint.
  final String? itemSize;
  final List<HomeItem> items;

  const HomeShelf({
    required this.title,
    required this.items,
    this.section,
    this.itemSize,
  });
}

enum HomeItemType {
  song,

  /// A music video / livestream / UGC video — has 16:9 thumbnail, same Song
  /// entity underneath but the UI should render it with a widescreen card.
  video,
  artist,
  album,
  playlist,
}

class HomeItem {
  final HomeItemType type;

  /// Concrete type depends on [type]:
  ///  - song / video → [Song]
  ///  - artist       → Map<String, dynamic> {name, thumbnailUrl, colorPrimary, colorSecondary}
  ///  - album        → [Playlist] (isAlbum == true)
  ///  - playlist     → [Playlist] (isAlbum == false)
  final dynamic data;

  const HomeItem({required this.type, required this.data});
}

class HomeData {
  final List<HomeShelf> shelves;
  final List<Song> trending;
  final String? profileUrl;
  final String? ytName;
  final List<Song> musicVideos;
  final List<Song> favArtistsSongs;

  const HomeData({
    this.shelves = const [],
    this.trending = const [],
    this.profileUrl,
    this.ytName,
    this.musicVideos = const [],
    this.favArtistsSongs = const [],
  });

  /// Deduplicated union of all playable songs across all shelves (songs +
  /// videos) plus the supplementary lists — used as the player queue.
  List<Song> get allSongs {
    final seen = <String>{};
    final songs = <Song>[];

    void add(Song s) {
      if (seen.add(s.id)) songs.add(s);
    }

    for (final shelf in shelves) {
      for (final item in shelf.items) {
        if ((item.type == HomeItemType.song ||
                item.type == HomeItemType.video) &&
            item.data is Song) {
          add(item.data as Song);
        }
      }
    }
    trending.forEach(add);
    musicVideos.forEach(add);
    favArtistsSongs.forEach(add);

    return songs;
  }
}
