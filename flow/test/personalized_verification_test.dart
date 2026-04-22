import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow/data/sources/youtube_music_data_source.dart';
import 'package:flow/core/storage/local_storage.dart';
import 'package:flow/core/storage/secure_storage_service.dart';
import 'package:flow/core/logger/app_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;

void main() {
  late YoutubeMusicDataSource dataSource;
  late Directory tempDir;

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'DEBUG=true');
    AppLogger.init();

    tempDir = Directory(
      p.join(Directory.current.path, 'test_hive_personalized'),
    );
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
    if (!tempDir.existsSync()) tempDir.createSync();

    await LocalStorage.instance.init(tempDir.path);

    final cookieFile = File('bin/test-cookie.txt');
    if (!cookieFile.existsSync()) {
      print(
        '\n[VERIFICATION] COOKIE_NOT_FOUND: Please paste your YouTube Music cookie string into "bin/test-cookie.txt"',
      );
      print('Format: "VISITOR_INFO1_LIVE=...; LOGIN_INFO=...; SID=...; ..."');
    } else {
      print(
        '\n[VERIFICATION] Cookie found in bin/test-cookie.txt. Proceeding with personalized fetch...',
      );
    }

    dataSource = YoutubeMusicDataSource();
  });

  group('Personalized YTM Verification', () {
    test('Generate Personalized Dumps and Analyze', () async {
      final cookieFile = File('bin/test-cookie.txt');
      if (!cookieFile.existsSync()) {
        print(
          'Skipping personalized verification as bin/test-cookie.txt is missing.',
        );
        return;
      }

      print('\n--- [DEBUG] FETCHING PERSONALIZED HOME FEED ---');
      final homeData = await dataSource.fetchHomeData();

      final homeDump = File('bin/home_personalized_dump.json');
      await homeDump.writeAsString(jsonEncode(homeData.rawShelves));
      print('Personalized home feed dumped to ${homeDump.path}');

      bool allShelvesFilled = true;
      for (var i = 0; i < homeData.rawShelves.length; i++) {
        final shelf = homeData.rawShelves[i];
        final items = shelf['items'] as List;
        print('Shelf [$i]: "${shelf['title']}" | Items: ${items.length}');
        if (items.isEmpty) {
          print('  >> WARNING: Shelf "${shelf['title']}" is EMPTY!');
          allShelvesFilled = false;
        }
      }

      expect(
        allShelvesFilled,
        isTrue,
        reason: 'Some personalized shelves are empty. Check parsing logic.',
      );

      print('\n--- [DEBUG] FETCHING PERSONALIZED SEARCH RESULTS ---');
      const queries = ['Espresso', 'Sabrina Carpenter', 'Short n Sweet'];
      for (final query in queries) {
        final results = await dataSource.searchSongs(query);
        final searchDumpPath =
            'bin/search_${query.replaceAll(' ', '_')}_dump.json';
        final searchDump = File(searchDumpPath);
        await searchDump.writeAsString(
          jsonEncode(results.map((e) => e.toJson()).toList()),
        );
        print(
          'Search results for "$query" dumped to $searchDumpPath (${results.length} items)',
        );

        expect(
          results,
          isNotEmpty,
          reason: 'Search for "$query" returned no results.',
        );

        // Check sorting (views should be in extras)
        print('  Top results (sorted by views):');
        for (int i = 0; i < results.take(5).length; i++) {
          final s = results[i];
          final views = s.extras?['views'] ?? 0;
          print('    #$i: ${s.title} | Views: $views');

          if (i > 0) {
            final prevViews = results[i - 1].extras?['views'] ?? 0;
            if (prevViews < views && prevViews != 0) {
              print(
                '    >> WARNING: Sorting mismatch: #$i has more views than #${i - 1}',
              );
            }
          }
        }
      }
    });
    group('Search Resiliency Verification', () {
      test('Fuzzy search / Typos', () async {
        print('\n--- [DEBUG] FETCHING SEARCH RESULTS WITH TYPOS ---');
        const queries = ['Espreso', 'Sabrina Carpenetr', 'Short n Swet'];
        for (final query in queries) {
          final results = await dataSource.searchSongs(query);
          print('Search results for "$query" (typo): ${results.length} items');
          if (results.isNotEmpty) {
            print(
              '  First result: ${results.first.title} by ${results.first.artist}',
            );
          }
          expect(
            results,
            isNotEmpty,
            reason: 'Fuzzy search failed for "$query"',
          );
        }
      });
    });
  });
}
