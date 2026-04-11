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
      final response = await _client.get(
        Uri.parse(streamUrl),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'User-Agent': 'FlowMusicApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        AppLogger.i(_tag, 'Download complete: ${song.title}');
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e, st) {
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
