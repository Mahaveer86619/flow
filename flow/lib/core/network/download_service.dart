import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/server_config.dart';
import '../logger/app_logger.dart';
import '../storage/local_storage.dart';
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

  Future<String> get _localPath async {
    final customPath = LocalStorage.instance.downloadPath;
    if (customPath != null && await Directory(customPath).exists()) {
      return customPath;
    }
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getLocalFile(String songId) async {
    final path = await _localPath;
    return File('$path/downloads/$songId.mp3');
  }

  Future<void> downloadSong(Song song) async {
    if (_activeDownloads.containsKey(song.id)) return;

    try {
      final file = await _getLocalFile(song.id);
      if (await file.exists()) {
        AppLogger.i(_tag, 'Song ${song.id} already downloaded');
        return;
      }

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

  Future<bool> isDownloaded(String songId) async {
    final file = await _getLocalFile(songId);
    return file.exists();
  }

  Future<void> deleteDownload(String songId) async {
    final file = await _getLocalFile(songId);
    if (await file.exists()) {
      await file.delete();
      AppLogger.i(_tag, 'Deleted download: $songId');
    }
  }
}
