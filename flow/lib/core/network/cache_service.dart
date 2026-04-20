import 'dart:async';
import 'dart:io';
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
  
  // LRU cache management
  final List<String> _cacheQueue = [];
  static const int _maxCacheSize = 3;

  Future<void> init() async {
    // Scan cache directory and populate queue
    await scanCache();
    AppLogger.i(_tag, 'Initialised with ${_cacheQueue.length} cached songs');
  }

  Future<void> scanCache() async {
    try {
      final dirPath = await _localPath;
      final cacheDir = Directory('$dirPath/cache');
      if (!await cacheDir.exists()) return;

      final files = await cacheDir.list().toList();
      _cacheQueue.clear();
      
      // Sort by last modified to approximate LRU if not persisted
      files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          final id = fileName.replaceAll('.mp3', '');
          _cacheQueue.add(id);
        }
      }
      
      // Enforce max size immediately
      while (_cacheQueue.length > _maxCacheSize) {
        final oldId = _cacheQueue.removeAt(0);
        final oldFile = File('$dirPath/cache/$oldId.mp3');
        if (await oldFile.exists()) await oldFile.delete();
      }
    } catch (e) {
      AppLogger.e(_tag, 'Failed to scan cache', e);
    }
  }

  Future<String> get _localPath async {
    String basePath;
    final customPath = LocalStorage.instance.downloadPath;

    if (customPath != null && await Directory(customPath).exists()) {
      basePath = customPath;
    } else if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      basePath = directory?.path ?? (await getApplicationDocumentsDirectory()).path;
    } else {
      basePath = (await getApplicationDocumentsDirectory()).path;
    }

    final flowPath = '$basePath${Platform.pathSeparator}flow';
    final dir = Directory(flowPath);
    if (!await dir.exists()) await dir.create(recursive: true);
    return flowPath;
  }

  Future<File?> getCachedFile(String songId) async {
    final dirPath = await _localPath;
    final file = File('$dirPath/cache/$songId.mp3');
    if (await file.exists()) {
      // Update LRU position
      _cacheQueue.remove(songId);
      _cacheQueue.add(songId);
      return file;
    }
    return null;
  }

  Future<void> cacheSong(Song song) async {
    if (_cacheQueue.contains(song.id)) {
      // Already cached, just move to end of LRU
      _cacheQueue.remove(song.id);
      _cacheQueue.add(song.id);
      return;
    }

    try {
      final dirPath = await _localPath;
      final file = File('$dirPath/cache/${song.id}.mp3');
      await file.parent.create(recursive: true);

      // Resolve stream
      final streamUrl = await StreamResolver.instance.resolveYoutubeStream(song.id);
      if (streamUrl == null) return;

      AppLogger.d(_tag, 'Caching song: ${song.title}');
      
      final response = await _client.get(Uri.parse(streamUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        
        _cacheQueue.add(song.id);
        
        // Evict old entries if full
        if (_cacheQueue.length > _maxCacheSize) {
          final oldId = _cacheQueue.removeAt(0);
          final oldFile = File('$dirPath/cache/$oldId.mp3');
          if (await oldFile.exists()) await oldFile.delete();
          AppLogger.d(_tag, 'Evicted from cache: $oldId');
        }
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
      _cacheQueue.clear();
    } catch (e) {
      AppLogger.e(_tag, 'Failed to clear cache', e);
    }
  }
}
