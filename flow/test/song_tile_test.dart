import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flow/presentation/widgets/song_tile.dart';
import 'package:flow/presentation/blocs/player/player_bloc.dart';
import 'mocks.dart';
import 'widget_test_utils.dart';

void main() {
  late MockPlayerBloc mockPlayerBloc;

  setUp(() {
    setupMocks();
    mockPlayerBloc = MockPlayerBloc();
    
    // Stub initial state
    when(() => mockPlayerBloc.state).thenReturn(const PlayerState());
  });

  testWidgets('SongTile displays song info', (tester) async {
    await tester.pumpWidget(wrapWithProviders(
      child: SongTile(song: testSong, queue: [testSong], index: 0),
      playerBloc: mockPlayerBloc,
    ));

    expect(find.text(testSong.title), findsOneWidget);
    expect(find.text(testSong.artist), findsOneWidget);
  });

  testWidgets('SongTile triggers PlayQueueEvent on tap by default', (tester) async {
    await tester.pumpWidget(wrapWithProviders(
      child: SongTile(song: testSong, queue: [testSong], index: 0),
      playerBloc: mockPlayerBloc,
    ));

    await tester.tap(find.byType(SongTile));
    
    verify(() => mockPlayerBloc.add(any(that: isA<PlayQueueEvent>()))).called(1);
  });

  testWidgets('SongTile uses custom onTap if provided', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(wrapWithProviders(
      child: SongTile(
        song: testSong,
        queue: [testSong],
        index: 0,
        onTap: () => tapped = true,
      ),
      playerBloc: mockPlayerBloc,
    ));

    await tester.tap(find.byType(SongTile));
    
    expect(tapped, isTrue);
    verifyNever(() => mockPlayerBloc.add(any(that: isA<PlayQueueEvent>())));
  });
}
