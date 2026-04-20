import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../logger/app_logger.dart';
import '../storage/local_storage.dart';
import '../../data/models/song_model.dart';
import '../../data/sources/stream_resolver.dart';
import '../../domain/entities/song.dart';

class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  final http.Client _client = http.Client();
  static const _tag = 'DownloadService';

  final _progressController = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get progressStream => _progressController.stream;

  final _downloadEventController = StreamController<String>.broadcast();
  Stream<String> get downloadEventStream => _downloadEventController.stream;

  final Map<String, double> _activeDownloads = {};
  final Set<String> _downloadedIds = {};

  Future<void> init() async {
    _downloadedIds.clear();
    _downloadedIds.addAll(LocalStorage.instance.downloadedPaths.keys);
    await scanDownloads();
    AppLogger.i(_tag, 'Initialised with ${_downloadedIds.length} downloaded songs');
  }

  Future<void> scanDownloads() async {
    try {
      final dirPath = await _localPath;
      final downloadsDir = Directory('$dirPath/downloads');
      if (!await downloadsDir.exists()) return;

      final files = await downloadsDir.list().toList();
      int restored = 0;

      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          final parts = fileName.replaceAll('.mp3', '').split('_');
          if (parts.length >= 2) {
            final id = parts.last;
            if (!_downloadedIds.contains(id)) {
              _downloadedIds.add(id);
              LocalStorage.instance.saveDownloadMapping(id, entity.path);
              restored++;
            }
          }
        }
      }
      if (restored > 0) {
        AppLogger.i(_tag, 'Restored $restored downloads from disk scan');
      }
    } catch (e) {
      AppLogger.e(_tag, 'Failed to scan downloads', e);
    }
  }

  List<String> getDownloadedIds() => _downloadedIds.toList();

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

  Future<File?> getLocalFile(String songId) async {
    final path = LocalStorage.instance.getDownloadedPath(songId);
    if (path != null) return File(path);
    return null;
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  Future<void> downloadSong(Song song) async {
    if (_activeDownloads.containsKey(song.id)) return;

    try {
      final dirPath = await _localPath;
      final safeTitle = _sanitizeFileName(song.title);
      final fileName = '${safeTitle}_${song.id}.mp3';
      final file = File('$dirPath/downloads/$fileName');

      await file.parent.create(recursive: true);

      String? localThumbPath;
      if (song.thumbnailUrl != null) {
        try {
          localThumbPath = await _downloadThumbnail(song.id, song.thumbnailUrl!);
        } catch (e) {
          AppLogger.w(_tag, 'Thumbnail download failed: $e');
        }
      }

      AppLogger.i(_tag, 'Starting download: ${song.title}');

      final streamUrl = await StreamResolver.instance.resolveYoutubeStream(song.id);
      if (streamUrl == null) throw Exception('Could not resolve stream URL for ${song.id}');

      int existingLength = 0;
      if (await file.exists()) {
        existingLength = await file.length();
        AppLogger.i(_tag, 'Found existing file of $existingLength bytes, attempting resume');
      }

      final request = http.Request('GET', Uri.parse(streamUrl));
      request.headers['User-Agent'] = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36';
      if (existingLength > 0) request.headers['Range'] = 'bytes=$existingLength-';

      final response = await _client.send(request);

      if (response.statusCode != 200 && response.statusCode != 206) {
        if (response.statusCode == 416) {
          AppLogger.i(_tag, 'Range not satisfiable, assuming file complete');
        } else {
          throw Exception('Server returned ${response.statusCode}');
        }
      }

      final contentLength = (response.contentLength ?? 0) + existingLength;
      int downloaded = existingLength;

      _activeDownloads[song.id] = existingLength > 0 ? (existingLength / contentLength) : 0.0;
      _progressController.add(Map.from(_activeDownloads));

      final sink = file.openWrite(mode: FileMode.append);

      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          downloaded += chunk.length;
          if (contentLength > 0) {
            final progress = downloaded / contentLength;
            _activeDownloads[song.id] = progress;
            _progressController.add(Map.from(_activeDownloads));
          }
        }
      } finally {
        await sink.close();
      }

      LocalStorage.instance.saveDownloadMapping(song.id, file.path);

      final model = SongModel(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: song.duration,
        thumbnailUrl: localThumbPath ?? song.thumbnailUrl,
        colorPrimary: song.colorPrimary,
        colorSecondary: song.colorSecondary,
        isDownloaded: true,
      );
      LocalStorage.instance.saveDownloadMetadata(song.id, model.toJson());

      _downloadedIds.add(song.id);
      _downloadEventController.add(song.id);
      _activeDownloads.remove(song.id);
      _progressController.add(Map.from(_activeDownloads));

      AppLogger.i(_tag, 'Download complete: ${song.title}');
    } catch (e, st) {
      _activeDownloads.remove(song.id);
      _progressController.add(Map.from(_activeDownloads));
      AppLogger.e(_tag, 'Download failed: ${song.title}', e, st);
      rethrow;
    }
  }

  Future<void> moveDownloads(String oldBasePath, String newBasePath) async {
    try {
      AppLogger.i(_tag, 'Moving app storage from $oldBasePath to $newBasePath');
      
      final oldFlowPath = '$oldBasePath${Platform.pathSeparator}flow';
      final newFlowPath = '$newBasePath${Platform.pathSeparator}flow';
      
      final oldDir = Directory(oldFlowPath);
      if (!await oldDir.exists()) {
        AppLogger.w(_tag, 'Old app storage directory does not exist: $oldFlowPath');
        return;
      }
      
      await Directory('$newFlowPath${Platform.pathSeparator}downloads').create(recursive: true);
      await Directory('$newFlowPath${Platform.pathSeparator}cache').create(recursive: true);
      await Directory('$newFlowPath${Platform.pathSeparator}downloads${Platform.pathSeparator}thumbs').create(recursive: true);
      
      final mappings = LocalStorage.instance.downloadedPaths;
      int movedCount = 0;
      
      for (final entry in mappings.entries) {
        final songId = entry.key;
        final oldFilePath = entry.value;
        final file = File(oldFilePath);
        
        if (await file.exists()) {
          final fileName = oldFilePath.split(Platform.pathSeparator).last;
          final newFilePath = '$newFlowPath${Platform.pathSeparator}downloads${Platform.pathSeparator}$fileName';
          
          try {
            await file.copy(newFilePath);
            await file.delete();
            LocalStorage.instance.saveDownloadMapping(songId, newFilePath);
            movedCount++;
            
            final metadata = LocalStorage.instance.getDownloadMetadata(songId);
            if (metadata != null && metadata['thumbnailUrl'] != null) {
               final thumbPath = metadata['thumbnailUrl'] as String;
               if (!thumbPath.startsWith('http')) {
                 final thumbFile = File(thumbPath);
                 if (await thumbFile.exists()) {
                   final thumbName = thumbPath.split(Platform.pathSeparator).last;
                   final newThumbPath = '$newFlowPath${Platform.pathSeparator}downloads${Platform.pathSeparator}thumbs${Platform.pathSeparator}$thumbName';
                   await thumbFile.copy(newThumbPath);
                   await thumbFile.delete();
                   metadata['thumbnailUrl'] = newThumbPath;
                   LocalStorage.instance.saveDownloadMetadata(songId, metadata);
                 }
               }
            }
          } catch (e) {
            AppLogger.e(_tag, 'Failed to move file for song $songId', e);
          }
        }
      }
      
      final oldCacheDir = Directory('$oldFlowPath${Platform.pathSeparator}cache');
      if (await oldCacheDir.exists()) {
        final cacheFiles = await oldCacheDir.list().toList();
        for (final f in cacheFiles) {
          if (f is File) {
            final name = f.path.split(Platform.pathSeparator).last;
            try {
              await f.copy('$newFlowPath${Platform.pathSeparator}cache${Platform.pathSeparator}$name');
              await f.delete();
            } catch (e) {}
          }
        }
      }

      AppLogger.i(_tag, 'Migration complete. Moved $movedCount downloads.');
    } catch (e, st) {
      AppLogger.e(_tag, 'Migration failed', e, st);
    }
  }

  Future<String?> _downloadThumbnail(String id, String url) async {
    try {
      final dirPath = await _localPath;
      final file = File('$dirPath/downloads/thumbs/$id.jpg');
      await file.parent.create(recursive: true);

      final response = await _client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {
      AppLogger.w(_tag, 'Failed to download thumb: $e');
    }
    return null;
  }

  Future<bool> isDownloaded(String songId) async {
    if (!_downloadedIds.contains(songId)) return false;
    final file = await getLocalFile(songId);
    return file != null && await file.exists();
  }

  bool isDownloadedSync(String songId) => _downloadedIds.contains(songId);

  Future<void> deleteDownload(String songId) async {
    final file = await getLocalFile(songId);
    if (file != null && await file.exists()) await file.delete();

    final dirPath = await _localPath;
    final thumbFile = File('$dirPath/downloads/thumbs/$songId.jpg');
    if (await thumbFile.exists()) await thumbFile.delete();

    LocalStorage.instance.removeDownloadMapping(songId);
    _downloadedIds.remove(songId);
    _downloadEventController.add(songId);
    AppLogger.i(_tag, 'Deleted download: $songId');
  }
}
