import 'package:flow/core/storage/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flow/data/sources/youtube_music_data_source.dart';
import 'package:flow/data/sources/stream_resolver.dart';
import 'package:flow/core/logger/app_logger.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '.';
  @override
  Future<String?> getTemporaryPath() async => '.';
  @override
  Future<String?> getLibraryPath() async => '.';
  @override
  Future<String?> getApplicationSupportPath() async => '.';
  @override
  Future<String?> getExternalStoragePath() async => '.';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = MockPathProvider();

  late YoutubeMusicDataSource dataSource;
  late StreamResolver resolver;

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'DEBUG=true');
    AppLogger.init();
    await LocalStorage.instance.init('.');
    dataSource = YoutubeMusicDataSource();
    resolver = StreamResolver.instance;
  });

  group('Standalone YouTube Verification', () {
    test('Search songs standalone returns results', () async {
      final results = await dataSource.searchSongs('Never Gonna Give You Up');
      print('Search results found: ${results.length}');
      expect(results, isNotEmpty);
    });

    test('Stream resolution works for a valid videoId', () async {
      const videoId = 'dQw4w9WgXcQ';
      final streamUrl = await resolver.resolveYoutubeStream(videoId);
      print('Resolved Stream URL: $streamUrl');
      expect(streamUrl, isNotNull);
    });
  });
}
