import '../../../domain/entities/song.dart';

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
