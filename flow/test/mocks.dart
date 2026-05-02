import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:flow/core/storage/local_storage.dart';
import 'package:flow/core/platform/windows_media_session.dart';
import 'package:flow/domain/repositories/music_repository.dart';
import 'package:flow/domain/entities/song.dart';
import 'package:flow/domain/entities/history_data.dart';
import 'package:flutter/material.dart';
import 'package:flow/presentation/blocs/player/player_bloc.dart';
import 'package:flow/presentation/cubits/search/search_cubit.dart';
import 'package:flow/presentation/cubits/settings/settings_cubit.dart';
import 'package:flow/presentation/cubits/settings/settings_state.dart';
import 'package:flow/data/sources/local/download_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flow/core/logger/app_logger.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {
  @override
  Future<void> dispose() async {}
}

class MockLocalStorage extends Mock implements LocalStorage {}

class MockWindowsMediaSession extends Mock implements WindowsMediaSession {
  @override
  Future<void> dispose() async {}
}

class MockMusicRepository extends Mock implements MusicRepository {
  @override
  Future<void> recordPlay(Song song) async {}

  @override
  Future<HistoryData> getPersistentHistory() async {
    return const HistoryData(
      today: [],
      thisWeek: [],
      thisMonth: [],
      byMonth: {},
    );
  }
}

class MockConcatenatingAudioSource extends Mock
    implements ConcatenatingAudioSource {}

class MockDownloadService extends Mock implements DownloadService {}

class MockPlayerBloc extends MockBloc<PlayerEvent, PlayerState>
    implements PlayerBloc {}

class MockSearchCubit extends MockCubit<SearchState> implements SearchCubit {}

class MockSettingsCubit extends MockCubit<SettingsState> implements SettingsCubit {}

class FakePlayerState extends Fake implements PlayerState {}

class FakePlayerEvent extends Fake implements PlayerEvent {}

class FakeSong extends Fake implements Song {}

class FakeAudioSource extends Fake implements AudioSource {}

void setupMocks() {
  try {
    dotenv.testLoad(fileInput: 'DEBUG=true');
    AppLogger.init();
  } catch (_) {}

  final mockStorage = MockLocalStorage();
  // Stub common methods used by widgets to avoid LateInitializationError
  when(() => mockStorage.likedSongIds).thenReturn([]);
  when(() => mockStorage.getDownloadMetadata(any())).thenReturn(null);
  when(() => mockStorage.jwtToken).thenReturn(null);
  when(() => mockStorage.volume).thenReturn(0.7);
  when(() => mockStorage.isShuffle).thenReturn(false);
  when(() => mockStorage.isRepeat).thenReturn(false);
  when(() => mockStorage.recentSearches).thenReturn([]);
  when(() => mockStorage.recentlyPlayedIds).thenReturn([]);

  LocalStorage.instance = mockStorage;

  registerFallbackValue(FakePlayerState());
  registerFallbackValue(FakePlayerEvent());
  registerFallbackValue(FakeSong());
  registerFallbackValue(FakeAudioSource());
  registerFallbackValue(Duration.zero);
}

final testSong = Song(
  id: 'test_id',
  title: 'Test Song',
  artist: 'Test Artist',
  album: 'Test Album',
  duration: const Duration(minutes: 3),
  colorPrimary: Colors.blue,
  colorSecondary: Colors.red,
);

final testSong2 = Song(
  id: 'test_id_2',
  title: 'Test Song 2',
  artist: 'Test Artist 2',
  album: 'Test Album 2',
  duration: const Duration(minutes: 4),
  colorPrimary: Colors.green,
  colorSecondary: Colors.yellow,
);
