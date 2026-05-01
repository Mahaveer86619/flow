import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../logger/app_logger.dart';
import '../storage/local_storage.dart';
import '../../domain/entities/song.dart';
import '../../data/sources/stream_resolver.dart';

class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  final http.Client _client = http.Client();
  static const _tag = 'CacheService';
  
  // Cache management
  final Map<String, double> _cacheScores = {};
  static const String _ext = '.opus';

  Future<void> init() async {
    await scanCache();
    AppLogger.i(_tag, 'Initialised cache manager');
  }

  Future<void> scanCache() async {
    try {
      final dirPath = await _localPath;
      final cacheDir = Directory('$dirPath/cache');
      if (!await cacheDir.exists()) return;

      final files = await cacheDir.list().toList();
      _cacheScores.clear();
      
      for (final entity in files) {
        if (entity is File && entity.path.endsWith(_ext)) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          final id = fileName.replaceAll(_ext, '');
          // We don't have the full song object here, so we'll use a neutral score
          // or try to recover it from metadata. For now, 0.0.
          _cacheScores[id] = 0.0;
        }
      }
      
      await _enforceBudget();
    } catch (e) {
      AppLogger.e(_tag, 'Failed to scan cache', e);
    }
  }

  Future<void> _enforceBudget() async {
    final budgetMB = LocalStorage.instance.cacheBudgetMB;
    if (budgetMB == null) return; // Unlimited
    if (budgetMB == 0) {
      await clearCache();
      return;
    }

    try {
      final dirPath = await _localPath;
      final cacheDir = Directory('$dirPath/cache');
      if (!await cacheDir.exists()) return;

      final files = await cacheDir.list().where((e) => e is File).cast<File>().toList();
      
      int currentSize = 0;
      for (var f in files) {
        currentSize += await f.length();
      }

      final budgetBytes = budgetMB * 1024 * 1024;
      
      if (currentSize > budgetBytes) {
        AppLogger.i(_tag, 'Cache budget exceeded (${(currentSize / 1024 / 1024).toStringAsFixed(1)}MB > ${budgetMB}MB). Evicting...');
        
        // Sort by score (lowest first)
        final sortedIds = _cacheScores.keys.toList()
          ..sort((a, b) => _cacheScores[a]!.compareTo(_cacheScores[b]!));

        for (final id in sortedIds) {
          final file = File('$dirPath/cache/$id$_ext');
          if (await file.exists()) {
            final size = await file.length();
            await file.delete();
            currentSize -= size;
            _cacheScores.remove(id);
            AppLogger.d(_tag, 'Evicted from cache: $id');
          }
          if (currentSize <= budgetBytes) break;
        }
      }
    } catch (e) {
      AppLogger.e(_tag, 'Failed to enforce budget', e);
    }
  }

  double _calculateEvictionScore(Song s) {
    // Eviction Score as per idea.md
    // double cacheScore(Track t) =>
    //   (t.playCount    *  1.0)
    // + (t.liked        ?  5.0 : 0.0)
    // + (t.replayCount  *  2.0)
    // + (t.downloaded   ?  0.0 : 3.0)  // never evict downloads
    // + (t.skipCount    * -0.8)
    // + _recencyBoost(t.lastPlayed)     // log decay, max +2.0 at today
    // + (graph.nodes[t.id]?.score ?? 0) * 0.5;

    double score = 0.0;
    
    // Using fields from current Song entity (will be Track later)
    final extras = s.extras ?? {};
    final playCount = extras['playCount'] as int? ?? 0;
    final replayCount = extras['replayCount'] as int? ?? 0;
    final skipCount = extras['skipCount'] as int? ?? 0;
    final liked = LocalStorage.instance.likedSongIds.contains(s.id);
    final graphScore = extras['graphScore'] as double? ?? 0.0;

    score += playCount * 1.0;
    if (liked) score += 5.0;
    score += replayCount * 2.0;
    if (s.isDownloaded) score += 1000.0; // Very high score to prevent eviction
    score -= skipCount * 0.8;
    
    if (s.playedAt != null) {
      final diff = DateTime.now().difference(s.playedAt!).inDays;
      score += max(0, 2.0 * pow(0.9, diff)); // recency boost with decay
    }
    
    score += graphScore * 0.5;
    
    return score;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final flowPath = '${directory.path}${Platform.pathSeparator}flow';
    final dir = Directory(flowPath);
    if (!await dir.exists()) await dir.create(recursive: true);
    return flowPath;
  }

  Future<File?> getCachedFile(String songId) async {
    final dirPath = await _localPath;
    final file = File('$dirPath/cache/$songId$_ext');
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  Future<void> cacheSong(Song song) async {
    final budgetMB = LocalStorage.instance.cacheBudgetMB;
    if (budgetMB == 0) return;

    try {
      final dirPath = await _localPath;
      final file = File('$dirPath/cache/${song.id}$_ext');
      if (await file.exists()) {
        _cacheScores[song.id] = _calculateEvictionScore(song);
        return;
      }

      await file.parent.create(recursive: true);

      // Resolve stream
      final streamUrl = await StreamResolver.instance.resolveYoutubeStream(song.id);
      if (streamUrl == null) return;

      AppLogger.d(_tag, 'Caching song: ${song.title}');
      
      final response = await _client.get(Uri.parse(streamUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        _cacheScores[song.id] = _calculateEvictionScore(song);
        await _enforceBudget();
      }
    } catch (e) {
      AppLogger.w(_tag, 'Failed to cache song ${song.id}: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final dirPath = await _localPath;
      final cacheDir = Directory('$dirPath/cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      _cacheScores.clear();
    } catch (e) {
      AppLogger.e(_tag, 'Failed to clear cache', e);
    }
  }
}

