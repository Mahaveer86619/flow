import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flow/presentation/screens/player/player_screen.dart';
import 'package:flow/presentation/blocs/player/player_bloc.dart';
import 'mocks.dart';
import 'widget_test_utils.dart';

void main() {
  late MockPlayerBloc mockPlayerBloc;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    setupMocks();
    mockPlayerBloc = MockPlayerBloc();
    
    when(() => mockPlayerBloc.state).thenReturn(PlayerState(
      currentSong: testSong,
      isPlaying: true,
    ));
    when(() => mockPlayerBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('PlayerScreen has "Start radio" option in bottom sheet', (tester) async {
    await tester.pumpWidget(wrapWithProviders(
      child: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => PlayerScreen.show(context),
          child: const Text('Show Player'),
        ),
      ),
      playerBloc: mockPlayerBloc,
    ));

    await tester.tap(find.text('Show Player'));
    // Use multiple pumps instead of pumpAndSettle to avoid timeouts from infinite animations
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Find and tap the "more" button
    final moreButton = find.byIcon(Icons.more_vert_rounded);
    expect(moreButton, findsOneWidget);
    await tester.tap(moreButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify "Start radio" is present
    expect(find.text('Start radio'), findsOneWidget);

    // Tap "Start radio"
    await tester.tap(find.text('Start radio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify event added
    verify(() => mockPlayerBloc.add(any(that: isA<PlayRadioEvent>()))).called(1);
  });
}
