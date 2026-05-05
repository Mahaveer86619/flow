import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flow/presentation/blocs/player/player_bloc.dart';
import 'package:flow/presentation/cubits/search/search_cubit.dart';
import 'package:flow/presentation/cubits/song_details/song_details_cubit.dart';
import 'mocks.dart';

Widget wrapWithProviders({
  required Widget child,
  MockPlayerBloc? playerBloc,
  MockSearchCubit? searchCubit,
  MockSongDetailsCubit? songDetailsCubit,
}) {
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        if (playerBloc != null)
          BlocProvider<PlayerBloc>.value(value: playerBloc),
        if (searchCubit != null)
          BlocProvider<SearchCubit>.value(value: searchCubit),
        if (songDetailsCubit != null)
          BlocProvider<SongDetailsCubit>.value(value: songDetailsCubit)
        else
          BlocProvider<SongDetailsCubit>.value(value: MockSongDetailsCubit()),
      ],
      child: Scaffold(body: child),
    ),
  );
}
