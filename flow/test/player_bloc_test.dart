import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState, ProcessingState;
import 'package:just_audio/just_audio.dart' as ja show PlayerState, ProcessingState;
import 'package:flow/presentation/blocs/player/player_bloc.dart';
import 'package:flow/domain/entities/song.dart';
import 'mocks.dart';

void main() {
  late MockAudioPlayer mockAudioPlayer;
  late MockLocalStorage mockLocalStorage;
  late MockWindowsMediaSession mockMediaSession;
  late MockSongRepository mockSongRepository;

  setUp(() {
    setupMocks();
    mockAudioPlayer = MockAudioPlayer();
    mockLocalStorage = MockLocalStorage();
    mockMediaSession = MockWindowsMediaSession();
    mockSongRepository = MockSongRepository();

    // Stub AudioPlayer streams
    when(() => mockAudioPlayer.positionStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.bufferedPositionStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.playerStateStream).thenAnswer((_) => Stream.value(ja.PlayerState(false, ja.ProcessingState.idle)));
    when(() => mockAudioPlayer.durationStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.currentIndexStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.sequenceStateStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.volume).thenReturn(1.0);
    when(() => mockAudioPlayer.setVolume(any())).thenAnswer((_) async => {});
    when(() => mockAudioPlayer.setAudioSource(any(), initialIndex: any(named: 'initialIndex'), initialPosition: any(named: 'initialPosition')))
        .thenAnswer((_) async => null);
    when(() => mockAudioPlayer.play()).thenAnswer((_) async => {});

    // Stub LocalStorage
    when(() => mockLocalStorage.likedSongIds).thenReturn([]);
    when(() => mockLocalStorage.recentlyPlayedIds).thenReturn([]);
    when(() => mockLocalStorage.volume).thenReturn(0.7);
    when(() => mockLocalStorage.isShuffle).thenReturn(false);
    when(() => mockLocalStorage.isRepeat).thenReturn(false);
    when(() => mockLocalStorage.recentSearches).thenReturn([]);

    // Stub MediaSession
    when(() => mockMediaSession.init(
      onPlay: any(named: 'onPlay'),
      onPause: any(named: 'onPause'),
      onNext: any(named: 'onNext'),
      onPrevious: any(named: 'onPrevious'),
      onFastForward: any(named: 'onFastForward'),
      onRewind: any(named: 'onRewind'),
    )).thenAnswer((_) async => {});
    when(() => mockMediaSession.updateSong(any())).thenAnswer((_) async => {});
    when(() => mockMediaSession.setPlaybackStatus(any())).thenAnswer((_) async => {});
    when(() => mockMediaSession.updateTimeline(any(), any())).thenAnswer((_) async => {});
  });

  group('PlayerBloc - PlayRadioEvent', () {
    blocTest<PlayerBloc, PlayerState>(
      'starts radio and fetches tracks',
      build: () {
        when(() => mockSongRepository.getRadioTracks(any())).thenAnswer((_) async => [testSong2]);
        return PlayerBloc(
          songRepository: mockSongRepository,
          audioPlayer: mockAudioPlayer,
          storage: mockLocalStorage,
          mediaSession: mockMediaSession,
        );
      },
      act: (bloc) => bloc.add(PlayRadioEvent(testSong)),
      verify: (bloc) {
        verify(() => mockSongRepository.getRadioTracks(testSong.id)).called(1);
        expect(bloc.state.queue, contains(testSong));
      },
    );
  });
}
