import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/auth/auth_cubit.dart';
import 'core/config/app_constants.dart';
import 'core/logger/app_logger.dart';
import 'core/network/connectivity_service.dart';
import 'core/network/download_service.dart';
import 'core/network/cache_service.dart';
import 'core/network/network_cubit.dart';
import 'core/platform/permission_service.dart';
import 'core/storage/local_storage.dart';
import 'presentation/cubits/settings/settings_cubit.dart';
import 'domain/repositories/music_repository.dart';
import 'data/repositories/youtube_music_repository.dart';
import 'data/sources/mock_song_data_source.dart';
import 'data/sources/youtube_music_data_source.dart';
import 'domain/usecases/get_categories_usecase.dart';
import 'domain/usecases/get_home_data_usecase.dart';
import 'domain/usecases/get_playlists_usecase.dart';
import 'domain/usecases/search_songs_usecase.dart';
import 'presentation/blocs/player/player_bloc.dart';
import 'presentation/cubits/home/home_cubit.dart';
import 'presentation/cubits/library/library_cubit.dart';
import 'presentation/cubits/search/search_cubit.dart';
import 'presentation/cubits/song_details/song_details_cubit.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/widgets/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  await dotenv.load(fileName: '.env');
  AppLogger.init();
  await LocalStorage.instance.init();
  await DownloadService.instance.init();
  await CacheService.instance.init();

  final currentVersion = dotenv.env['APP_VERSION'] ?? '1.0.0';
  final storedVersion = LocalStorage.instance.appVersion;

  if (storedVersion != currentVersion) {
    await LocalStorage.instance.clearCacheOnVersionChange();
    try {
      await CacheService.instance.clearCache();
    } catch (_) {}
    LocalStorage.instance.saveAppVersion(currentVersion);
  }

  await ConnectivityService.instance.init();
  await PermissionService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final useMock = dotenv.env['USE_MOCK'] == 'true';
  final dataSource = useMock ? MockSongDataSource() : YoutubeMusicDataSource();
  final repository = YoutubeMusicRepository(dataSource);

  final getHomeData = GetHomeDataUseCase(repository);
  final getPlaylists = GetPlaylistsUseCase(repository);
  final getCategories = GetCategoriesUseCase(repository);
  final searchSongs = SearchSongsUseCase(repository);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MusicRepository>(create: (_) => repository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit()),
          BlocProvider(
            create: (_) => NetworkCubit(ConnectivityService.instance),
          ),
          BlocProvider(create: (_) => PlayerBloc(musicRepository: repository)),
          BlocProvider(
            create: (context) =>
                SettingsCubit(authCubit: context.read<AuthCubit>()),
          ),
          BlocProvider(
            create: (_) => HomeCubit(
              getHomeData: getHomeData,
              musicRepository: repository,
            ),
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
              musicRepository: repository,
            ),
          ),
          BlocProvider(
            create: (_) => SongDetailsCubit(musicRepository: repository),
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
          listener: (context, state) {
            if (!state.isAuthenticated && !state.isLoading) {
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
      surface: isDark ? const Color(0xFF000000) : const Color(0xFFFBFBFF),
      onSurface: isDark ? Colors.white : const Color(0xFF07070F),
    );

    final base = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
