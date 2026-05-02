import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow/data/sources/remote/youtube_music_data_source.dart';
import 'package:flow/core/storage/local_storage.dart';
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

  setUpAll(() async {
    AppLogger.init();
    await LocalStorage.instance.init('.');
    dataSource = YoutubeMusicDataSource();
  });

  group('YTM Raw Response Dumper', () {
    test('Dump Home Feed Response', () async {
      // Note: We are using a private method _parseHomeDataInternal indirectly or we can modify the source to expose it for testing.
      // But we can just use the public fetchHomeData and add logging inside or use a proxy.
      // Alternatively, let's just use Dio interceptor if we want to capture raw.
      
      // For now, I will modify youtube_music_data_source.dart to optionally log raw responses if a flag is set.
    });
  });
}
