import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../repositories/song_repository.dart';

/// Manages search query state and computes filtered results.
class SearchViewModel extends ChangeNotifier {
  final SongRepository _repository;

  SearchViewModel(this._repository);

  String _query = '';

  String get query => _query;
  bool get hasQuery => _query.isNotEmpty;

  List<Map<String, dynamic>> get categories => _repository.getCategories();

  List<Song> get results {
    if (_query.isEmpty) return const [];
    final q = _query.toLowerCase();
    return _repository.getSongs().where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q);
    }).toList();
  }

  void updateQuery(String query) {
    if (_query == query) return;
    _query = query;
    notifyListeners();
  }

  void clearQuery() => updateQuery('');
}
