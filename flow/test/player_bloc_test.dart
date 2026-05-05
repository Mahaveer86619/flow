import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart'
    as ja
    show PlayerState, ProcessingState;
import 'package:flow/presentation/blocs/player/player_bloc.dart';
import 'package:flow/presentation/cubits/settings/settings_state.dart';
import 'mocks.dart';

void main() {
  late MockAudioPlayer mockAudioPlayer;
  late MockLocalStorage mockLocalStorage;
  late MockWindowsMediaSession mockMediaSession;
  late MockMusicRepository mockMusicRepository;
  late MockSettingsCubit mockSettingsCubit;

  setUp(() {
    setupMocks();
    mockAudioPlayer = MockAudioPlayer();
    mockLocalStorage = MockLocalStorage();
    mockMediaSession = MockWindowsMediaSession();
    mockMusicRepository = MockMusicRepository();
    mockSettingsCubit = MockSettingsCubit();

    // Stub AudioPlayer streams
    when(
      () => mockAudioPlayer.positionStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockAudioPlayer.bufferedPositionStream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.playerStateStream).thenAnswer(
      (_) => Stream.value(ja.PlayerState(false, ja.ProcessingState.idle)),
    );
    when(
      () => mockAudioPlayer.durationStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockAudioPlayer.currentIndexStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockAudioPlayer.playbackEventStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockAudioPlayer.sequenceStateStream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.volume).thenReturn(1.0);
    when(() => mockAudioPlayer.setVolume(any())).thenAnswer((_) async => {});
    when(
      () => mockAudioPlayer.setAudioSource(
        any(),
        initialIndex: any(named: 'initialIndex'),
        initialPosition: any(named: 'initialPosition'),
      ),
    ).thenAnswer((_) async => null);

    when(() => mockSettingsCubit.state).thenReturn(const SettingsState());
  });

  group('PlayerBloc', () {
    test('initial state is PlayerState()', () {
      expect(
        PlayerBloc(
          musicRepository: mockMusicRepository,
          settingsCubit: mockSettingsCubit,
          storage: mockLocalStorage,
          audioPlayer: mockAudioPlayer,
          mediaSession: mockMediaSession,
        ).state,
        const PlayerState(),
      );
    });

    blocTest<PlayerBloc, PlayerState>(
      'emits correct state when PlaySingleEvent is added',
      build: () {
        return PlayerBloc(
          musicRepository: mockMusicRepository,
          settingsCubit: mockSettingsCubit,
          storage: mockLocalStorage,
          audioPlayer: mockAudioPlayer,
          mediaSession: mockMediaSession,
        );
      },
      act: (bloc) => bloc.add(PlaySingleEvent(testSong)),
      expect: () => [
        isA<PlayerState>().having((s) => s.currentSong, 'currentSong', testSong),
      ],
      verify: (_) {
        verify(() => mockMusicRepository.recordPlay(testSong)).called(1);
        verify(() => mockAudioPlayer.stop()).called(1);
      },
    );
  group('Queue Management', () {
      blocTest<PlayerBloc, PlayerState>(
        'InsertNextEvent adds song after current index',
        build: () {
          final bloc = PlayerBloc(
            musicRepository: mockMusicRepository,
            settingsCubit: mockSettingsCubit,
            storage: mockLocalStorage,
            audioPlayer: mockAudioPlayer,
            mediaSession: mockMediaSession,
          );
          // Pre-populate with a song
          return bloc;
        },
        seed: () => PlayerState(
          queue: [testSong],
          queueIndex: 0,
          currentSong: testSong,
        ),
        act: (bloc) => bloc.add(InsertNextEvent(testSong2)),
        expect: () => [
          isA<PlayerState>().having((s) => s.queue, 'queue', [testSong, testSong2]),
        ],
      );

      blocTest<PlayerBloc, PlayerState>(
        'RemoveFromQueueEvent removes song at index',
        build: () {
          return PlayerBloc(
            musicRepository: mockMusicRepository,
            settingsCubit: mockSettingsCubit,
            storage: mockLocalStorage,
            audioPlayer: mockAudioPlayer,
            mediaSession: mockMediaSession,
          );
        },
        seed: () => PlayerState(
          queue: [testSong, testSong2],
          queueIndex: 0,
          currentSong: testSong,
        ),
        act: (bloc) => bloc.add(const RemoveFromQueueEvent(1)),
        expect: () => [
          isA<PlayerState>().having((s) => s.queue, 'queue', [testSong]),
        ],
      );
    });
  });
}
