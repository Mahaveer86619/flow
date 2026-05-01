import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import '../logger/app_logger.dart';
import '../storage/local_storage.dart';
import '../../data/models/song_model.dart';
import '../../data/sources/stream_resolver.dart';
import '../../domain/entities/song.dart';

enum DownloadFormat { mp3, flac, opus }

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
        if (entity is File) {
          final ext = entity.path.split('.').last;
          if (['mp3', 'flac', 'opus'].contains(ext)) {
            final fileName = entity.path.split(Platform.pathSeparator).last;
            final parts = fileName.replaceAll('.$ext', '').split('_');
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

  Future<void> downloadSong(Song song, {DownloadFormat format = DownloadFormat.mp3, int bitrate = 192}) async {
    if (_activeDownloads.containsKey(song.id)) return;

    try {
      final dirPath = await _localPath;
      final safeTitle = _sanitizeFileName(song.title);
      final ext = format.name;
      final fileName = '${safeTitle}_${song.id}.$ext';
      final finalFile = File('$dirPath/downloads/$fileName');
      final tempFile = File('$dirPath/downloads/${song.id}.tmp');

      await finalFile.parent.create(recursive: true);

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

      // 1. Download temp file
      final response = await _client.get(Uri.parse(streamUrl));
      if (response.statusCode != 200) throw Exception('Failed to download stream: ${response.statusCode}');
      await tempFile.writeAsBytes(response.bodyBytes);

      _activeDownloads[song.id] = 0.5; // Downloading done, transcoding starts
      _progressController.add(Map.from(_activeDownloads));

      // 2. Transcode and tag with FFmpeg
      final artworkPath = localThumbPath ?? '';
      final metadataArgs = [
        '-metadata', 'title=${song.title}',
        '-metadata', 'artist=${song.artist}',
        '-metadata', 'album=${song.album}',
        if (song.extras?['year'] != null) ...['-metadata', 'date=${song.extras!['year']}'],
      ];

      String codecArgs = '';
      if (format == DownloadFormat.mp3) {
        codecArgs = '-codec:a libmp3lame -b:a ${bitrate}k';
      } else if (format == DownloadFormat.flac) {
        codecArgs = '-codec:a flac';
      } else if (format == DownloadFormat.opus) {
        codecArgs = '-codec:a libopus -b:a ${bitrate}k';
      }

      String artworkArgs = '';
      if (artworkPath.isNotEmpty && await File(artworkPath).exists()) {
        artworkArgs = '-i "$artworkPath" -map 0 -map 1 -disposition:v attached_pic';
      }

      final command = '-i "${tempFile.path}" $artworkArgs ${metadataArgs.join(' ')} $codecArgs "${finalFile.path}" -y';
      
      AppLogger.d(_tag, 'Running FFmpeg: $command');
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        AppLogger.i(_tag, 'Transcoding complete: ${song.title}');
      } else {
        final logs = await session.getLogs();
        AppLogger.e(_tag, 'FFmpeg failed: ${logs.last.getMessage()}');
        throw Exception('Transcoding failed');
      }

      // 3. Cleanup
      if (await tempFile.exists()) await tempFile.delete();

      LocalStorage.instance.saveDownloadMapping(song.id, finalFile.path);

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

      AppLogger.i(_tag, 'Download & Transcoding complete: ${song.title}');
    } catch (e, st) {
      _activeDownloads.remove(song.id);
      _progressController.add(Map.from(_activeDownloads));
      AppLogger.e(_tag, 'Download process failed: ${song.title}', e, st);
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
