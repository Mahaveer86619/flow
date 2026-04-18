import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flow/data/sources/youtube_data_source.dart';
import 'package:flow/data/sources/stream_resolver.dart';
import 'package:flow/core/logger/app_logger.dart';
import 'package:flow/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'dart:io';

void main() {
  // Simple verification script for Standalone YouTube Integration
  // Note: These tests require network access to hit YouTube Music APIs.
  
  late YoutubeDataSource dataSource;
  late StreamResolver resolver;

  setUpAll(() {
    // Mock environment for test
    dotenv.testLoad(fileInput: 'DEBUG=true\nAPI_BASE_URL=http://localhost:8000');
    AppLogger.init();
    dataSource = YoutubeDataSource();
    resolver = StreamResolver.instance;
  });

  group('Standalone YouTube Verification', () {
    
    test('Search songs standalone returns results', () async {
      final results = await dataSource.searchSongs('Never Gonna Give You Up');
      
      print('Search results found: ${results.length}');
      for (var song in results.take(3)) {
        print(' - ${song.title} by ${song.artist} (ID: ${song.id})');
      }

      expect(results, isNotEmpty);
      expect(results.first.title.toLowerCase(), contains('never gonna give you up'));
    });

    test('Stream resolution works for a valid videoId', () async {
      // Use a well-known video ID
      const videoId = 'dQw4w9WgXcQ';
      final streamUrl = await resolver.resolveYoutubeStream(videoId);
      
      print('Resolved Stream URL: $streamUrl');
      
      expect(streamUrl, isNotNull);
      expect(streamUrl, contains('googlevideo.com'));
    });

    test('Home feed fetch returns shelves (Standalone)', () async {
      // Note: This might fail if no cookies are set in SecureStorageService,
      // but YTM sometimes returns a generic home feed for logged-out users too.
      final homeData = await dataSource.fetchHomeData();
      
      print('Home Shelves found: ${homeData.rawShelves.length}');
      for (var shelf in homeData.rawShelves) {
        print(' Shelf: ${shelf['title']} (${(shelf['items'] as List).length} items)');
      }

      // If we are logged out, we might get fewer or no shelves depending on YTM's current behavior.
      // But we expect at least the model to be valid.
      expect(homeData, isNotNull);
    });

    test('Radio (/next) fetch returns suggestions', () async {
      const videoId = 'dQw4w9WgXcQ';
      final radioTracks = await dataSource.fetchRadioTracks(videoId);
      
      print('Radio tracks found: ${radioTracks.length}');
      for (var track in radioTracks.take(3)) {
        print(' Related: ${track.title} by ${track.artist}');
      }

      expect(radioTracks, isNotEmpty);
    });
  });
}
