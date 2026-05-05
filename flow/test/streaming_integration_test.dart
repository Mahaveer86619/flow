import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow/core/storage/local_storage.dart';
import 'package:flow/core/storage/secure_storage_service.dart';
import 'package:flow/core/logger/app_logger.dart';
import 'package:flow/data/repositories/youtube_music_repository.dart';
import 'package:flow/data/sources/remote/youtube_music_data_source.dart';
import 'package:flow/data/sources/remote/stream_resolver.dart';
import 'package:flow/domain/usecases/search_songs_usecase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

void main() {
  late YoutubeMusicDataSource dataSource;
  late YoutubeMusicRepository repository;
  late SearchSongsUseCase searchSongsUseCase;
  late StreamResolver resolver;
  late Directory tempDir;

  setUpAll(() async {
    try {
      dotenv.testLoad(fileInput: 'DEBUG=true');
    } catch (_) {}
    AppLogger.init();

    tempDir = Directory(p.join(p.current, 'test_hive_streaming'));
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    tempDir.createSync();
    await LocalStorage.instance.init(tempDir.path);

    dataSource = YoutubeMusicDataSource();
    repository = YoutubeMusicRepository(dataSource);
    searchSongsUseCase = SearchSongsUseCase(repository);
    resolver = StreamResolver.instance;

    final cookieFile = File('bin/test-cookie.txt');
    if (cookieFile.existsSync()) {
      final cookies = cookieFile.readAsStringSync().trim();
      await SecureStorageService.instance.saveYoutubeCookies(cookies);
      AppLogger.i('Test', 'Injected cookies from bin/test-cookie.txt');
    }
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('Streaming Integration Flow', () {
    test('Search -> Resolve -> Validate YT Music Track', () async {
      const query = 'Nanda Devi Express';
      print('\n[TEST 1] Searching for: $query');
      final songs = await searchSongsUseCase(query);
      
      expect(songs, isNotEmpty);
      final targetSong = songs.first;
      print('Target Song: ${targetSong.title} by ${targetSong.artist} (ID: ${targetSong.id})');

      print('Resolving stream URL...');
      final streamUrl = await resolver.resolveYoutubeStream(targetSong.id);
      
      expect(streamUrl, isNotNull);
      print('Resolved URL: ${streamUrl!.substring(0, 100)}...');

      final response = await http.head(
        Uri.parse(streamUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Origin': 'https://music.youtube.com',
          'Referer': 'https://music.youtube.com/',
        },
      );

      print('Response Status: ${response.statusCode}');
      expect(response.statusCode, 200, reason: 'Stream URL should return 200 OK');
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('Standard YouTube Video -> Resolve -> Validate', () async {
      const videoId = 'dQw4w9WgXcQ'; 
      print('\n[TEST 2] Resolving mainstream video: $videoId');
      
      final streamUrl = await resolver.resolveYoutubeStream(videoId);
      expect(streamUrl, isNotNull);
      print('Resolved URL: ${streamUrl!.substring(0, 100)}...');

      final response = await http.head(
        Uri.parse(streamUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Origin': 'https://www.youtube.com',
          'Referer': 'https://www.youtube.com/',
        },
      );

      print('Response Status: ${response.statusCode}');
      expect(response.statusCode, 200, reason: 'Stream URL should return 200 OK');
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('YT Music Track -> Forced Standard Replacement -> Validate', () async {
      // This test specifically verifies the user's new strategy:
      // Search YTM for metadata, but force standard YT for audio.
      const videoId = 'E2SqPDE6vJc'; // A restricted track
      const title = 'Wan Mundoli';
      const artist = 'Various';
      
      print('\n[TEST 3] Resolving track with FORCED replacement: $title');
      
      final streamUrl = await resolver.resolveYoutubeStream(
        videoId, 
        title: title, 
        artist: artist,
        forceStandardYouTube: true,
      );
      
      expect(streamUrl, isNotNull);
      print('Resolved URL: ${streamUrl!.substring(0, 100)}...');

      final response = await http.head(
        Uri.parse(streamUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Origin': 'https://www.youtube.com',
          'Referer': 'https://www.youtube.com/',
        },
      );

      print('Response Status: ${response.statusCode}');
      expect(response.statusCode, 200, reason: 'Replacement stream should be accessible');
    }, timeout: const Timeout(Duration(minutes: 1)));
  });
}
