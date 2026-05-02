import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:metadata_god/metadata_god.dart';
import 'core/auth/auth_cubit.dart';
import 'core/logger/app_logger.dart';
import 'core/network/connectivity_service.dart';
import 'data/sources/local/download_service.dart';
import 'data/sources/local/cache_service.dart';
import 'core/network/network_cubit.dart';
import 'core/platform/permission_service.dart';
import 'core/storage/local_storage.dart';
import 'presentation/cubits/settings/settings_cubit.dart';
import 'domain/repositories/music_repository.dart';
import 'data/repositories/youtube_music_repository.dart';
import 'data/repositories/composite_music_repository.dart';
import 'data/repositories/local_music_repository.dart';
import 'data/sources/local/mock_song_data_source.dart';
import 'data/sources/remote/youtube_music_data_source.dart';
import 'data/sources/local/local_files_adapter.dart';
import 'data/sources/remote/youtube_music_adapter.dart';
import 'data/sources/remote/spotify_adapter.dart';
import 'data/sources/remote/stream_resolver.dart';
import 'data/sources/local/local_database.dart';
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
import 'core/intelligence/app_intelligence.dart';
import 'data/workers/pre_cache_worker.dart';
import 'core/platform/desktop_controller.dart';
import 'core/network/lan_stream_bridge.dart';
import 'data/sources/remote/spotify_service.dart';
import 'core/network/peer_manager.dart';

void main() async {
  const String tag = 'Main';
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  AppLogger.init();

  try {
    await DesktopController.instance.init();
  } catch (e) {
    AppLogger.e(tag, 'DesktopController init failed', e);
  }

  try {
    await SpotifyService.instance.init();
  } catch (e) {
    AppLogger.e(tag, 'SpotifyService init failed', e);
  }

  try {
    await PeerManager.instance.init();
  } catch (e) {
    AppLogger.e(tag, 'PeerManager init failed', e);
  }

  try {
    await MetadataGod.initialize();
  } catch (e) {
    AppLogger.e(tag, 'MetadataGod initialization failed. Local metadata parsing will be disabled.', e);
  }

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      LanStreamBridge.instance.startServer();
    } catch (e) {
      AppLogger.e(tag, 'LanStreamBridge failed to start', e);
    }
  }

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
    try {
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
    } catch (e) {
      AppLogger.e(tag, 'JustAudioBackground init failed', e);
    }
  }

  try {
    await LocalStorage.instance.init();
  } catch (e) {
    AppLogger.e(tag, 'LocalStorage init failed', e);
  }

  try {
    await AppIntelligence.instance.init();
  } catch (e) {
    AppLogger.e(tag, 'AppIntelligence init failed', e);
  }

  try {
    await DownloadService.instance.init();
  } catch (e) {
    AppLogger.e(tag, 'DownloadService init failed', e);
  }

  try {
    await CacheService.instance.init();
  } catch (e) {
    AppLogger.e(tag, 'CacheService init failed', e);
  }

  try {
    await PreCacheWorker.init();
    await PreCacheWorker.schedule();
  } catch (e) {
    AppLogger.e(tag, 'PreCacheWorker setup failed', e);
  }

  final currentVersion = dotenv.env['APP_VERSION'] ?? '1.0.0';
  final storedVersion = LocalStorage.instance.appVersion;

  if (storedVersion != currentVersion) {
    try {
      await LocalStorage.instance.clearCacheOnVersionChange();
      try {
        await CacheService.instance.clearCache();
      } catch (_) {}
      LocalStorage.instance.saveAppVersion(currentVersion);
    } catch (e) {
      AppLogger.e(tag, 'Version change cache cleanup failed', e);
    }
  }

  try {
    await ConnectivityService.instance.init();
  } catch (e) {
    AppLogger.e(tag, 'ConnectivityService init failed', e);
  }

  try {
    await PermissionService.instance.init();
  } catch (e) {
    AppLogger.e(tag, 'PermissionService init failed', e);
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final useMock = dotenv.env['USE_MOCK'] == 'true';
  final rawDataSource = useMock ? MockSongDataSource() : YoutubeMusicDataSource();
  final ytRemoteRepo = YoutubeMusicRepository(rawDataSource);
  
  final database = LocalDatabase();
  final localRepo = LocalMusicRepository(database);

  final repository = CompositeMusicRepository(
    adapters: [
      YoutubeMusicAdapter(dataSource: rawDataSource, resolver: StreamResolver.instance),
      LocalFilesAdapter(libraryPaths: [
        if (LocalStorage.instance.downloadPath != null) LocalStorage.instance.downloadPath!,
      ]),
      SpotifyAdapter(),
    ],
    primaryRemote: ytRemoteRepo,
    localRepo: localRepo,
  );

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
          BlocProvider(create: (_) => NetworkCubit(ConnectivityService.instance)),
          BlocProvider(create: (context) => SettingsCubit(authCubit: context.read<AuthCubit>())),
          BlocProvider(create: (context) => PlayerBloc(
            musicRepository: repository,
            settingsCubit: context.read<SettingsCubit>(),
          )),
          BlocProvider(create: (_) => HomeCubit(getHomeData: getHomeData, musicRepository: repository)),
          BlocProvider(create: (_) => SearchCubit(searchSongs: searchSongs, getCategories: getCategories)),
          BlocProvider(create: (_) => LibraryCubit(getPlaylists: getPlaylists, musicRepository: repository)),
          BlocProvider(create: (_) => SongDetailsCubit(musicRepository: repository)),
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
    final themeMode = context.select<SettingsCubit, ThemeMode>((c) => c.state.themeMode);

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
    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(bodyColor: colorScheme.onSurface, displayColor: colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
      ),
    );
  }
}
