import 'package:workmanager/workmanager.dart';
import '../sources/local/cache_service.dart';
import '../../../core/intelligence/app_intelligence.dart';
import '../../domain/entities/scoring_graph.dart';
import '../../domain/repositories/music_repository.dart';
import '../repositories/youtube_music_repository.dart';
import '../sources/remote/youtube_music_data_source.dart';
import '../../../core/logger/app_logger.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    AppLogger.i('PreCacheWorker', 'Executing task: $task');
    
    try {
      await AppIntelligence.instance.init();
      final graph = AppIntelligence.instance.graph;
      
      // We create a standalone repository for the background task
      final repository = YoutubeMusicRepository(YoutubeMusicDataSource());
      
      // Get top scored tracks from graph
      final topNodes = graph.nodes.values
          .where((n) => n.type == NodeType.track)
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      
      final topTrackIds = topNodes
          .take(10)
          .map((n) => n.id.replaceFirst('track:', ''))
          .toList();
      
      if (topTrackIds.isNotEmpty) {
        AppLogger.i('PreCacheWorker', 'Pre-caching ${topTrackIds.length} top tracks');
        
        final songs = await repository.getSongsByIds(topTrackIds);
        for (final song in songs) {
          await CacheService.instance.cacheSong(song);
        }
      }
      
      return true;
    } catch (e) {
      AppLogger.e('PreCacheWorker', 'Task failed', e);
      return false;
    }
  });
}

class PreCacheWorker {
  static const String taskName = 'com.flow.app.pre_cache';

  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }


  static Future<void> schedule() async {
    await Workmanager().registerPeriodicTask(
      '1',
      taskName,
      constraints: Constraints(
        networkType: NetworkType.unmetered, // WiFi only
        requiresCharging: true,
      ),
      frequency: const Duration(hours: 24),
    );
  }
}
