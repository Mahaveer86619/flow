import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow/data/sources/youtube_music_data_source.dart';
import 'package:flow/core/logger/app_logger.dart';
import 'package:flow/core/storage/local_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;

void main() {
  late YoutubeMusicDataSource dataSource;
  late Directory tempDir;

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'DEBUG=true');
    AppLogger.init();
    
    tempDir = Directory(p.join(Directory.current.path, 'test_hive_debug'));
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    tempDir.createSync();
    
    await LocalStorage.instance.init(tempDir.path);
    dataSource = YoutubeMusicDataSource();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('YTM InnerTube Structure Debugging', () {
    test('Fetch Home Feed and Print Raw Structure', () async {
      print('\n--- [DEBUG] FETCHING HOME FEED ---');
      final homeData = await dataSource.fetchHomeData();
      
      print('Parsed Shelves Count: ${homeData.rawShelves.length}');
      
      if (homeData.rawShelves.isEmpty) {
        print('CRITICAL: No shelves were parsed. This means either the network call failed or the path to sectionList is wrong.');
      } else {
        for (var i = 0; i < homeData.rawShelves.length; i++) {
          final shelf = homeData.rawShelves[i];
          print('Shelf [$i]: "${shelf['title']}" | Section: ${shelf['section']} | Items: ${(shelf['items'] as List).length}');
        }
      }
    });

    test('Fetch Search Results and Print Raw Structure', () async {
      print('\n--- [DEBUG] FETCHING SEARCH RESULTS ---');
      const query = 'new music';
      final results = await dataSource.searchSongs(query);
      
      print('Parsed Results Count: ${results.length}');
      if (results.isNotEmpty) {
        print('First Result: ${results[0].title} by ${results[0].artist}');
      }
    });
  });
}
