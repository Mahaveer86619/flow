import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../repositories/song_repository.dart';

/// Provides data for the Home screen.
/// Fetches and exposes songs from the repository.
class HomeViewModel extends ChangeNotifier {
  final SongRepository _repository;

  HomeViewModel(this._repository);

  String get greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// All available songs (used for queue building).
  List<Song> get allSongs => _repository.getSongs();

  /// The 6 first songs shown as quick-access tiles.
  List<Song> get quickAccess {
    final songs = _repository.getSongs();
    return songs.take(6).toList();
  }

  /// The highlighted/featured song at the top.
  Song get featuredSong => _repository.getSongs()[4];

  /// Songs displayed in the "New Releases" row.
  List<Song> get newReleases => _repository.getSongs().take(5).toList();

  /// Songs displayed in the "Made For You" row.
  List<Song> get recommended => _repository.getSongs().skip(3).toList();
}
