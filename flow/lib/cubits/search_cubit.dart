import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/song.dart';
import '../repositories/song_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class SearchState {
  final String query;
  final List<Song> results;
  final List<Map<String, dynamic>> categories;
  final List<String> recentSearches;

  const SearchState({
    this.query = '',
    this.results = const [],
    required this.categories,
    this.recentSearches = const [],
  });

  bool get hasQuery => query.isNotEmpty;

  SearchState copyWith({
    String? query,
    List<Song>? results,
    List<String>? recentSearches,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      categories: categories,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

// ── Cubit ──────────────────────────────────────────────────────────────────────

class SearchCubit extends Cubit<SearchState> {
  final SongRepository _repository;

  SearchCubit(this._repository)
      : super(SearchState(categories: _repository.getCategories()));

  void updateQuery(String query) {
    if (state.query == query) return;
    final results = query.isEmpty
        ? <Song>[]
        : _repository.getSongs().where((s) {
            final q = query.toLowerCase();
            return s.title.toLowerCase().contains(q) ||
                s.artist.toLowerCase().contains(q) ||
                s.album.toLowerCase().contains(q);
          }).toList();
    emit(state.copyWith(query: query, results: results));
  }

  void clearQuery() => updateQuery('');

  void addRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    final updated = [
      query,
      ...state.recentSearches.where((s) => s != query),
    ].take(8).toList();
    emit(state.copyWith(recentSearches: updated));
  }

  void removeRecentSearch(String query) {
    final updated = state.recentSearches.where((s) => s != query).toList();
    emit(state.copyWith(recentSearches: updated));
  }

  void clearRecentSearches() {
    emit(state.copyWith(recentSearches: []));
  }
}
