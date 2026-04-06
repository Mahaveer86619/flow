import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../repositories/song_repository.dart';

/// Manages library state: active filter tab and playlist data.
class LibraryViewModel extends ChangeNotifier {
  final SongRepository _repository;

  LibraryViewModel(this._repository);

  static const filterOptions = ['Playlists', 'Albums', 'Artists', 'Downloads'];

  int _filterIndex = 0;
  int get filterIndex => _filterIndex;

  List<Playlist> get playlists => _repository.getPlaylists();

  void setFilter(int index) {
    if (_filterIndex == index) return;
    _filterIndex = index;
    notifyListeners();
  }
}
