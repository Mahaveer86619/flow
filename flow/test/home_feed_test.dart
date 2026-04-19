import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow/data/sources/youtube_music_data_source.dart';
import 'package:flow/core/logger/app_logger.dart';
import 'package:flow/core/storage/local_storage.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;

void main() {
  late YoutubeMusicDataSource dataSource;
  late Directory tempDir;

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'DEBUG=true');
    AppLogger.init();
    
    // Create a temporary directory for Hive
    tempDir = Directory(p.join(Directory.current.path, 'test_hive'));
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    tempDir.createSync();
    
    await LocalStorage.instance.init(tempDir.path);
    
    dataSource = YoutubeMusicDataSource();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Home Feed Response Analysis', () {
    test('Fetch and print home feed structure', () async {
      print('--- FETCHING HOME FEED ---');
      final homeData = await dataSource.fetchHomeData();
      
      print('Total Shelves Found: ${homeData.rawShelves.length}');
      
      for (var i = 0; i < homeData.rawShelves.length; i++) {
        final shelf = homeData.rawShelves[i];
        final items = shelf['items'] as List;
        print('\nShelf [$i]: "${shelf['title']}"');
        print('  Type: ${shelf['section']}');
        print('  Items Count: ${items.length}');
        
        if (items.isNotEmpty) {
          final firstItem = items.first;
          print('  First Item: ${firstItem['type']} - ${firstItem['data']?['title'] ?? firstItem['data']?['name']}');
        }
      }
      
      expect(homeData.rawShelves, isNotEmpty);
    });
  });
}
