import '../../core/config/app_constants.dart';
import '../../core/logger/app_logger.dart';
import '../entities/home_data.dart';
import '../repositories/music_repository.dart';

/// Returns structured home screen data from the repository.
///
/// If [AppConfig.intelligenceActive] is true, it applies heuristic parsing
/// to classify shelves into types (quickPicks, listeningAgain, etc.)
/// so the UI can apply specialized layouts.
class GetHomeDataUseCase {
  final MusicRepository _repository;
  const GetHomeDataUseCase(this._repository);

  Future<HomeData> call({int limit = 25}) async {
    final data = await _repository.getHomeData(limit: limit);

    if (!AppConfig.intelligenceActive) {
      AppLogger.i(
        'GetHomeDataUseCase',
        'Intelligence inactive, returning ${data.shelves.length} shelves',
      );
      return data;
    }

    // Apply "Internal App Logic" (Heuristics) to classify raw data
    final intelligentShelves = data.shelves.map((shelf) {
      String? sectionType;
      final titleLower = shelf.title.toLowerCase();

      if (titleLower.contains('quick picks')) {
        sectionType = 'quickPicks';
      } else if (titleLower.contains('listen again')) {
        sectionType = 'listeningAgain';
      } else if (titleLower.contains('video')) {
        sectionType = 'musicVideos';
      } else if (titleLower.contains('podcast')) {
        sectionType = 'podcasts';
      } else if (titleLower.contains('album')) {
        sectionType = 'albums';
      } else if (titleLower.contains('long listen')) {
        sectionType = 'longListening';
      } else if (titleLower.contains('flow')) {
        sectionType = 'flowIntelligence';
      }

      AppLogger.d(
        'GetHomeDataUseCase',
        'Classified shelf: "${shelf.title}" -> $sectionType',
      );

      return HomeShelf(
        title: shelf.title,
        items: shelf.items,
        section: sectionType,
      );
    }).toList();

    AppLogger.i(
      'GetHomeDataUseCase',
      'Returning ${intelligentShelves.length} intelligent shelves',
    );
    return HomeData(
      shelves: intelligentShelves,
      trending: data.trending,
      profileUrl: data.profileUrl,
      ytName: data.ytName,
      musicVideos: data.musicVideos,
      favArtistsSongs: data.favArtistsSongs,
    );
  }
}
