import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/storage/local_storage.dart';
import '../../../domain/usecases/get_categories_usecase.dart';
import '../../../domain/usecases/search_songs_usecase.dart';
import 'search_state.dart';

export 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchSongsUseCase _searchSongs;
  final LocalStorage _storage;
  Timer? _debounce;

  static const _tag = 'SearchCubit';

  SearchCubit({
    required SearchSongsUseCase searchSongs,
    required GetCategoriesUseCase getCategories,
    LocalStorage? storage,
  })  : _searchSongs = searchSongs,
        _storage = storage ?? LocalStorage.instance,
        super(SearchState(
          categories: getCategories(),
          recentSearches: (storage ?? LocalStorage.instance).recentSearches,
        )) {
    AppLogger.i(_tag, 'Created — recentSearches=${state.recentSearches.length}');
  }

  void updateQuery(String query) {
    if (state.query == query) return;
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      emit(state.copyWith(
          query: query, isLoading: false, error: false, results: []));
      return;
    }

    emit(state.copyWith(
        query: query, isLoading: true, error: false, results: []));
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    AppLogger.d(_tag, 'search("$query")');
    try {
      final results = await _searchSongs(query);
      if (!isClosed && state.query == query) {
        AppLogger.i(_tag, 'search("$query"): ${results.length} results');
        emit(state.copyWith(isLoading: false, error: false, results: results));
      }
    } on AppException catch (e) {
      if (!isClosed && state.query == query) {
        AppLogger.w(_tag, 'search("$query") failed: ${e.message}');
        emit(state.copyWith(
          isLoading: false,
          error: true,
          errorType: e.errorType,
          results: [],
        ));
      }
    } catch (e, st) {
      if (!isClosed && state.query == query) {
        AppLogger.e(_tag, 'search unexpected error', e, st);
        emit(state.copyWith(
          isLoading: false,
          error: true,
          errorType: AppErrorType.unknown,
          results: [],
        ));
      }
    }
  }

  void clearQuery() => updateQuery('');

  void addRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    final updated = [
      query,
      ...state.recentSearches.where((s) => s != query),
    ].take(8).toList();
    AppLogger.d(_tag, 'addRecentSearch: "$query"');
    _storage.saveRecentSearches(updated);
    emit(state.copyWith(recentSearches: updated));
  }

  void removeRecentSearch(String query) {
    final updated =
        state.recentSearches.where((s) => s != query).toList();
    _storage.saveRecentSearches(updated);
    emit(state.copyWith(recentSearches: updated));
  }

  void clearRecentSearches() {
    _storage.saveRecentSearches([]);
    emit(state.copyWith(recentSearches: []));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
