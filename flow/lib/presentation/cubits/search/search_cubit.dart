import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_categories_usecase.dart';
import '../../../domain/usecases/search_songs_usecase.dart';
import 'search_state.dart';

export 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchSongsUseCase _searchSongs;

  SearchCubit({
    required SearchSongsUseCase searchSongs,
    required GetCategoriesUseCase getCategories,
  })  : _searchSongs = searchSongs,
        super(SearchState(categories: getCategories()));

  void updateQuery(String query) {
    if (state.query == query) return;
    emit(state.copyWith(
      query: query,
      results: _searchSongs(query),
    ));
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
    emit(state.copyWith(
      recentSearches: state.recentSearches.where((s) => s != query).toList(),
    ));
  }

  void clearRecentSearches() => emit(state.copyWith(recentSearches: []));
}
