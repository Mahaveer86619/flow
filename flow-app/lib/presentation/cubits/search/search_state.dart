import '../../../core/error/app_exception.dart';
import '../../../domain/entities/song.dart';

class SearchState {
  final String query;
  final bool isLoading;
  final bool error;
  final AppErrorType errorType;
  final List<Song> results;
  final List<Map<String, dynamic>> categories;
  final List<String> recentSearches;

  const SearchState({
    this.query = '',
    this.isLoading = false,
    this.error = false,
    this.errorType = AppErrorType.unknown,
    this.results = const [],
    required this.categories,
    this.recentSearches = const [],
  });

  bool get hasQuery => query.isNotEmpty;

  SearchState copyWith({
    String? query,
    bool? isLoading,
    bool? error,
    AppErrorType? errorType,
    List<Song>? results,
    List<String>? recentSearches,
  }) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      errorType: errorType ?? this.errorType,
      results: results ?? this.results,
      categories: categories,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}
