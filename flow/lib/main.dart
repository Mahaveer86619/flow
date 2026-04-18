import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/auth/auth_cubit.dart';
import 'core/config/app_constants.dart';
import 'core/config/server_config.dart';
import 'core/logger/app_logger.dart';
import 'core/network/connectivity_service.dart';
import 'core/network/download_service.dart';
import 'core/network/network_cubit.dart';
import 'core/platform/permission_service.dart';
import 'core/storage/local_storage.dart';
import 'presentation/cubits/settings/settings_cubit.dart';
import 'domain/repositories/song_repository.dart';
import 'data/repositories/song_repository_impl.dart';
import 'data/sources/api_song_data_source.dart';
import 'data/sources/mock_song_data_source.dart';
import 'data/sources/youtube_data_source.dart';
import 'domain/usecases/get_categories_usecase.dart';
import 'domain/usecases/get_home_data_usecase.dart';
import 'domain/usecases/get_playlists_usecase.dart';
import 'domain/usecases/get_playlist_tracks_usecase.dart';
import 'domain/usecases/search_songs_usecase.dart';
import 'presentation/blocs/player/player_bloc.dart';
import 'presentation/cubits/home/home_cubit.dart';
import 'presentation/cubits/library/library_cubit.dart';
import 'presentation/cubits/search/search_cubit.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Background audio (Android / iOS / macOS only) ─────────────────────────
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.flow.app.audio',
      androidNotificationChannelName: 'Flow Audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidShowNotificationBadge: true,
      notificationColor: const Color(0xFF7C3AED),
      androidNotificationClickStartsActivity: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    );
  }

  // ── 3. Load .env ─────────────────────────────────────────────────────────────
  await dotenv.load(fileName: '.env');

  // ── 4. Logger (needs DEBUG flag from .env) ────────────────────────────────────
  AppLogger.init();
  AppLogger.i('main', 'Flow starting up');

  // ── 3. Local storage ──────────────────────────────────────────────────────────
  await LocalStorage.instance.init();

  // ── 3b. Version Check ────────────────────────────────────────────────────────
  final currentVersion = dotenv.env['APP_VERSION'] ?? '1.0.0';
  final storedVersion = LocalStorage.instance.appVersion;

  if (storedVersion != currentVersion) {
    AppLogger.w(
      'main',
      'Version changed ($storedVersion -> $currentVersion). Cleaning cache...',
    );
    await LocalStorage.instance.clearCache();
    LocalStorage.instance.saveAppVersion(currentVersion);
  } else {
    AppLogger.i('main', 'Version match: $currentVersion');
  }

  // ── 3c. Download service ────────────────────────────────────────────────────
  await DownloadService.instance.init();

  // ── 3b. Server config (reads stored custom URL from Hive) ────────────────────
  final baseUrlFromEnv = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  ServerConfig.instance.init(baseUrlFromEnv);

  // ── 4. Connectivity ───────────────────────────────────────────────────────────
  await ConnectivityService.instance.init();

  // ── 4b. Permissions ───────────────────────────────────────────────────────────
  await PermissionService.instance.init();

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
  final useMock = dotenv.env['USE_MOCK'] == 'true';

  AppLogger.i(
    'main',
    'Source: ${useMock ? "mock" : "Standalone (YouTubeDataSource)"}',
  );

  final dataSource = useMock ? MockSongDataSource() : YoutubeDataSource();

  final repository = SongRepositoryImpl(dataSource);

  final getHomeData = GetHomeDataUseCase(repository);
  final getPlaylists = GetPlaylistsUseCase(repository);
  final getCategories = GetCategoriesUseCase(repository);
  final searchSongs = SearchSongsUseCase(repository);
  final getPlaylistTracks = GetPlaylistTracksUseCase(repository);

  AppLogger.i('main', 'DI graph built — launching app');

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SongRepository>(create: (_) => repository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit()),
          BlocProvider(
            create: (_) => NetworkCubit(ConnectivityService.instance),
          ),
          BlocProvider(create: (_) => PlayerBloc(songRepository: repository)),
          BlocProvider(
            create: (context) =>
                SettingsCubit(authCubit: context.read<AuthCubit>()),
          ),
          BlocProvider(
            create: (_) =>
                HomeCubit(getHomeData: getHomeData, songRepository: repository),
          ),
          BlocProvider(
            create: (_) => SearchCubit(
              searchSongs: searchSongs,
              getCategories: getCategories,
            ),
          ),
          BlocProvider(
            create: (_) => LibraryCubit(
              getPlaylists: getPlaylists,
              songRepository: repository,
            ),
          ),
        ],
        child: const FlowApp(),
      ),
    ),
  );
}

final navigatorKey = GlobalKey<NavigatorState>();

class FlowApp extends StatelessWidget {
  const FlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsCubit, ThemeMode>(
      (c) => c.state.themeMode,
    );
    return MaterialApp(
      title: 'flow',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const SplashScreen(),
      builder: (context, child) {
        return BlocListener<AuthCubit, AuthState>(
          listenWhen: (prev, curr) =>
              prev.isAuthenticated != curr.isAuthenticated ||
              prev.isLoading != curr.isLoading,
          listener: (context, state) {
            if (!state.isAuthenticated && !state.isLoading) {
              AppLogger.i(
                'FlowApp',
                'User unauthenticated, redirecting to Login',
              );
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          },
          child: child!,
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    const seedColor = Color(0xFF7C3AED);
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      surface: isDark ? const Color(0xFF07070F) : const Color(0xFFFBFBFF),
      onSurface: isDark ? Colors.white : const Color(0xFF07070F),
    );

    final base = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        shape: AppRadius.mediumShape,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        shape: AppRadius.smallShape,
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(shape: AppRadius.mediumShape),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: AppRadius.mediumShape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: AppRadius.mediumShape),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: AppRadius.mediumShape),
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withAlpha(isDark ? 40 : 25),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
