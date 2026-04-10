import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/logger/app_logger.dart';
import 'core/network/connectivity_service.dart';
import 'core/network/network_cubit.dart';
import 'core/storage/local_storage.dart';
import 'data/repositories/song_repository_impl.dart';
import 'data/sources/api_song_data_source.dart';
import 'data/sources/mock_song_data_source.dart';
import 'domain/usecases/get_categories_usecase.dart';
import 'domain/usecases/get_home_data_usecase.dart';
import 'domain/usecases/get_playlists_usecase.dart';
import 'domain/usecases/get_playlist_tracks_usecase.dart';
import 'domain/usecases/search_songs_usecase.dart';
import 'presentation/blocs/player/player_bloc.dart';
import 'presentation/cubits/home/home_cubit.dart';
import 'presentation/cubits/library/library_cubit.dart';
import 'presentation/cubits/search/search_cubit.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Background audio (Android / iOS / macOS only) ─────────────────────────
  // just_audio_background has no Windows/Linux plugin — skip on those platforms.
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.flow.app.audio',
      androidNotificationChannelName: 'Flow Audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    );
  }

  // ── 3. Load .env ─────────────────────────────────────────────────────────────
  await dotenv.load(fileName: '.env');

  // ── 4. Logger (needs DEBUG flag from .env) ────────────────────────────────────
  AppLogger.init();
  AppLogger.i('main', 'Flow starting up');

  // ── 3. Local storage ──────────────────────────────────────────────────────────
  await LocalStorage.instance.init();

  // ── 4. Connectivity ───────────────────────────────────────────────────────────
  await ConnectivityService.instance.init();

  // ── 5. System UI ──────────────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // ── 6. Dependency graph ───────────────────────────────────────────────────────
  //
  //   Data source (mock or API)
  //     → SongRepositoryImpl
  //       → Use cases (one per screen data need)
  //         → BLoC / Cubits
  //
  // Switch between sources with USE_MOCK in .env — no code change required.

  final useMock = dotenv.env['USE_MOCK'] == 'true';
  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  AppLogger.i('main', 'Source: ${useMock ? "mock" : baseUrl}');

  final dataSource = useMock
      ? MockSongDataSource()
      : ApiSongDataSource(baseUrl: baseUrl);

  final repository = SongRepositoryImpl(dataSource);

  final getHomeData = GetHomeDataUseCase(repository);
  final getPlaylists = GetPlaylistsUseCase(repository);
  final getCategories = GetCategoriesUseCase(repository);
  final searchSongs = SearchSongsUseCase(repository);
  // ignore: unused_local_variable — available for screens that need it
  final getPlaylistTracks = GetPlaylistTracksUseCase(repository);

  AppLogger.i('main', 'DI graph built — launching app');

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NetworkCubit(ConnectivityService.instance)),
        BlocProvider(
          create: (_) =>
              PlayerBloc(streamBaseUrl: baseUrl, songRepository: repository),
        ),
        BlocProvider(create: (_) => HomeCubit(getHomeData: getHomeData)),
        BlocProvider(
          create: (_) => SearchCubit(
            searchSongs: searchSongs,
            getCategories: getCategories,
          ),
        ),
        BlocProvider(create: (_) => LibraryCubit(getPlaylists: getPlaylists)),
      ],
      child: const FlowApp(),
    ),
  );
}

class FlowApp extends StatelessWidget {
  const FlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flow',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    const seedColor = Color(0xFF7C3AED);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
