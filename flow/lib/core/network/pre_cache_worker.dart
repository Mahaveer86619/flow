import 'package:workmanager/workmanager.dart';
import 'cache_service.dart';
import '../intelligence/app_intelligence.dart';
import '../../domain/entities/scoring_graph.dart';
import '../../domain/entities/song.dart';
import '../../core/logger/app_logger.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    AppLogger.i('PreCacheWorker', 'Executing task: $task');
    
    try {
      await AppIntelligence.instance.init();
      final graph = AppIntelligence.instance.graph;
      
      // Get top scored tracks from graph
      final topNodes = graph.nodes.values
          .where((n) => n.type == NodeType.track)
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      
      final topTrackIds = topNodes.take(10).map((n) => n.id).toList();
      
      if (topTrackIds.isNotEmpty) {
        AppLogger.i('PreCacheWorker', 'Pre-caching ${topTrackIds.length} top tracks');
        
        for (final id in topTrackIds) {
          // We need a way to get the Song object from the ID.
          // For now, this is a placeholder as we need a repository that can fetch songs by IDs.
          // CacheService.instance.cacheSong(song);
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
      isInDebugMode: false,
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
