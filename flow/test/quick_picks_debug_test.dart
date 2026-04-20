import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow/data/sources/youtube_music_data_source.dart';
import 'package:flow/core/logger/app_logger.dart';
import 'package:flow/core/storage/local_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';

void main() {
  late YoutubeMusicDataSource dataSource;
  late Directory tempDir;

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'DEBUG=true');
    AppLogger.init();
    
    tempDir = Directory(p.join(Directory.current.path, 'test_hive_debug_qp'));
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

  group('Quick Picks Debugging', () {
    test('Trial and Error payloads for Quick Picks', () async {
      final dio = Dio();
      // We need to mimic the interceptor's headers if possible, 
      // but for now let's see what we get with default headers.
      
      final payloads = [
        {"browseId": "FEmusic_home"},
        {"browseId": "FEmusic_home", "params": "EgWKAQIIAWoQEAMQBBAJEAoQCxAEEAoQAA=="},
        {"browseId": "FEmusic_quick_picks"},
        {"browseId": "FEmusic_listen_again"},
        // Sometimes it's a specific browseId found in the home response
      ];

      for (var payload in payloads) {
        print('\n--- TRYING PAYLOAD: $payload ---');
        try {
          final response = await dio.post(
            'https://music.youtube.com/youtubei/v1/browse?prettyPrint=false',
            data: {
              ...payload,
              "context": {
                "client": {
                  "clientName": "WEB_REMIX",
                  "clientVersion": "1.20240409.01.01",
                  "osName": "Windows",
                  "osVersion": "10.0",
                  "platform": "DESKTOP",
                  "hl": "en",
                  "gl": "US",
                  "utcOffsetMinutes": 0,
                },
                "user": {
                  "lockedSafetyMode": false
                }
              }
            },
            options: Options(headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
              'Origin': 'https://music.youtube.com',
              'Referer': 'https://music.youtube.com/',
            }),
          );

          print('Status: ${response.statusCode}');
          if (response.statusCode == 200) {
            final data = response.data as Map<String, dynamic>;
            final contents = data['contents'];
            
            // Check for shelves
            List? sectionList = contents?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] ??
                                contents?['sectionListRenderer']?['contents'];

            if (sectionList != null) {
              print('Found ${sectionList.length} sections');
              for (var section in sectionList) {
                final shelf = section['musicCarouselShelfRenderer'] ?? 
                              section['musicShelfRenderer'] ?? 
                              section['musicTastebuilderShelfRenderer'] ??
                              section['itemSectionRenderer'];
                if (shelf == null) continue;

                final header = shelf['header']?['musicCarouselShelfBasicHeaderRenderer'] ?? 
                               shelf['header']?['musicHeaderRenderer'];
                
                final title = header?['title']?['runs']?[0]?['text'] ?? header?['title']?['simpleText'];
                print(' -> Section: "$title"');
                
                if (title != null && title.toLowerCase().contains('pick')) {
                  print('FOUND POTENTIAL QUICK PICKS!');
                  // Dump a bit of the structure
                  // print(jsonEncode(shelf).substring(0, 500));
                }
              }
            } else {
              print('No sectionList found in response.');
            }
          }
        } catch (e) {
          print('Error with payload $payload: $e');
        }
      }
    });
  });
}
