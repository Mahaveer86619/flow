import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cubits/home_cubit.dart';
import 'cubits/library_cubit.dart';
import 'cubits/player_cubit.dart';
import 'cubits/search_cubit.dart';
import 'repositories/mock_song_repository.dart';
import 'repositories/song_repository.dart';
import 'screens/splash/splash_screen.dart';

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

  // Repository is provided via RepositoryProvider — BLoC's built-in DI
  // mechanism for non-Bloc objects. Swap MockSongRepository here to connect
  // a real data source without touching any Cubit or View.
  runApp(
    RepositoryProvider<SongRepository>(
      create: (_) => MockSongRepository(),
      child: Builder(
        builder: (ctx) {
          final repo = ctx.read<SongRepository>();
          return MultiBlocProvider(
            providers: [
              // Shared across all screens
              BlocProvider(create: (_) => PlayerCubit()),
              // Per-screen cubits injected with the repository
              BlocProvider(create: (_) => HomeCubit(repo)),
              BlocProvider(create: (_) => SearchCubit(repo)),
              BlocProvider(create: (_) => LibraryCubit(repo)),
            ],
            child: const FlowApp(),
          );
        },
      ),
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
