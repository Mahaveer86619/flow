import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flow/presentation/screens/search/search_screen.dart';
import 'package:flow/presentation/blocs/player/player_bloc.dart';
import 'package:flow/presentation/cubits/search/search_cubit.dart';
import 'mocks.dart';
import 'widget_test_utils.dart';

void main() {
  late MockPlayerBloc mockPlayerBloc;
  late MockSearchCubit mockSearchCubit;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    setupMocks();
    mockPlayerBloc = MockPlayerBloc();
    mockSearchCubit = MockSearchCubit();

    when(() => mockPlayerBloc.state).thenReturn(const PlayerState());
    when(() => mockSearchCubit.state).thenReturn(SearchState(
      query: 'test',
      results: [testSong],
      isLoading: false,
      categories: const [],
      recentSearches: const [],
    ));
    when(() => mockSearchCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('SearchScreen triggers PlayRadioEvent on song tap', (tester) async {
    // We need to pump the screen. SearchScreen is a bit complex with slivers.
    await tester.pumpWidget(wrapWithProviders(
      child: const SearchScreen(),
      playerBloc: mockPlayerBloc,
      searchCubit: mockSearchCubit,
    ));

    // Result should be visible
    expect(find.text(testSong.title), findsOneWidget);

    await tester.tap(find.text(testSong.title));
    
    // Verify PlayRadioEvent was triggered instead of PlayQueueEvent
    verify(() => mockPlayerBloc.add(any(that: isA<PlayRadioEvent>()))).called(1);
    verifyNever(() => mockPlayerBloc.add(any(that: isA<PlayQueueEvent>())));
  });
}
