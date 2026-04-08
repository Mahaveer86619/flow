import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/repositories/song_repository_impl.dart';
import 'data/sources/mock_song_data_source.dart';
import 'domain/usecases/get_categories_usecase.dart';
import 'domain/usecases/get_playlists_usecase.dart';
import 'domain/usecases/get_songs_usecase.dart';
import 'domain/usecases/search_songs_usecase.dart';
import 'presentation/blocs/player/player_bloc.dart';
import 'presentation/cubits/home/home_cubit.dart';
import 'presentation/cubits/library/library_cubit.dart';
import 'presentation/cubits/search/search_cubit.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Build the dependency graph:
  //   MockSongDataSource → SongRepositoryImpl → use cases → BLoC/Cubits
  final dataSource = MockSongDataSource();
  final repository = SongRepositoryImpl(dataSource);

  final getSongs = GetSongsUseCase(repository);
  final getPlaylists = GetPlaylistsUseCase(repository);
  final getCategories = GetCategoriesUseCase(repository);
  final searchSongs = SearchSongsUseCase(repository);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => PlayerBloc()),
        BlocProvider(create: (_) => HomeCubit(getSongs: getSongs)),
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
