import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/server_config.dart';
import '../logger/app_logger.dart';
import '../storage/local_storage.dart';
import '../../data/models/song_model.dart';
import '../../domain/entities/song.dart';

class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  final http.Client _client = http.Client();
  static const _tag = 'DownloadService';

  final _progressController = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get progressStream => _progressController.stream;

  // Cache of current downloads to prevent duplicates
  final Map<String, double> _activeDownloads = {};

  // In-memory set of downloaded IDs for fast sync checks
  final Set<String> _downloadedIds = {};

  Future<void> init() async {
    _downloadedIds.clear();
    _downloadedIds.addAll(LocalStorage.instance.downloadedPaths.keys);
    AppLogger.i(
      _tag,
      'Initialised with ${_downloadedIds.length} downloaded songs',
    );
  }

  List<String> getDownloadedIds() => _downloadedIds.toList();

  Future<String> get _localPath async {
    final customPath = LocalStorage.instance.downloadPath;
    if (customPath != null && await Directory(customPath).exists()) {
      return customPath;
    }
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File?> getLocalFile(String songId) async {
    final path = LocalStorage.instance.getDownloadedPath(songId);
    if (path != null) {
      return File(path);
    }
    return null;
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  Future<void> downloadSong(Song song) async {
    if (_activeDownloads.containsKey(song.id)) return;

    try {
      final existingFile = await getLocalFile(song.id);
      if (existingFile != null && await existingFile.exists()) {
        AppLogger.i(_tag, 'Song ${song.id} already downloaded');
        return;
      }

      final dirPath = await _localPath;
      final safeTitle = _sanitizeFileName(song.title);
      final fileName = '${safeTitle}_${song.id}.mp3';
      final file = File('$dirPath/downloads/$fileName');

      await file.parent.create(recursive: true);

      final streamUrl = '${ServerConfig.instance.baseUrl}/v1/stream/${song.id}';
      final token = LocalStorage.instance.jwtToken;

      AppLogger.i(_tag, 'Starting download: ${song.title}');

      final request = http.Request('GET', Uri.parse(streamUrl));
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['User-Agent'] = 'FlowMusicApp/1.0';

      final response = await _client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      int downloaded = 0;
      final bytes = <int>[];

      _activeDownloads[song.id] = 0.0;
      _progressController.add(Map.from(_activeDownloads));

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        downloaded += chunk.length;

        if (contentLength > 0) {
          final progress = downloaded / contentLength;
          _activeDownloads[song.id] = progress;
          _progressController.add(Map.from(_activeDownloads));
        }
      }

      await file.writeAsBytes(bytes);

      // Download thumbnail
      String? localThumbPath;
      if (song.thumbnailUrl != null) {
        try {
          localThumbPath = await _downloadThumbnail(
            song.id,
            song.thumbnailUrl!,
          );
        } catch (e) {
          AppLogger.w(_tag, 'Thumbnail download failed: $e');
        }
      }

      // Save mapping in Hive and update memory set
      LocalStorage.instance.saveDownloadMapping(song.id, file.path);

      // Save metadata
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
    if (file != null && await file.exists()) {
      await file.delete();
    }

    // Delete thumbnail if it exists
    final dirPath = await _localPath;
    final thumbFile = File('$dirPath/downloads/thumbs/$songId.jpg');
    if (await thumbFile.exists()) {
      await thumbFile.delete();
    }

    LocalStorage.instance.removeDownloadMapping(songId);
    _downloadedIds.remove(songId);
    AppLogger.i(_tag, 'Deleted download: $songId');
  }
}
