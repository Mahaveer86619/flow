import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../../cubits/library/library_cubit.dart';
import '../../widgets/song_tile.dart';
import '../player/player_screen.dart';

enum ListCategory { none, downloaded, favourites, youtubeLikes }

class ListScreen extends StatelessWidget {
  final String title;
  final List<Song> initialSongs;
  final ListCategory category;

  const ListScreen({
    super.key,
    required this.title,
    required this.initialSongs,
    this.category = ListCategory.none,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = Breakpoints.isDesktop(MediaQuery.sizeOf(context).width);

    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final List<Song> songsToShow;
        switch (category) {
          case ListCategory.downloaded:
            songsToShow = state.downloadedSongs;
            break;
          case ListCategory.favourites:
            songsToShow = state.likedSongs;
            break;
          case ListCategory.youtubeLikes:
            songsToShow = state.remoteLikedSongs;
            break;
          case ListCategory.none:
            songsToShow = initialSongs;
            break;
        }

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              title,
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
            actions: [
              if (category == ListCategory.downloaded && songsToShow.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.shuffle_rounded),
                  onPressed: () {
                    context.read<PlayerBloc>().add(
                      const PlayDownloadedRadioEvent(),
                    );
                    Navigator.pop(context);
                  },
                  tooltip: 'Shuffle all downloaded',
                ),
            ],
          ),
          body: songsToShow.isEmpty
              ? const Center(child: Text('No songs found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: songsToShow.length,
                  itemBuilder: (context, i) {
                    final song = songsToShow[i];
                    return SongTile(song: song, queue: songsToShow, index: i);
                  },
                ),
        );
      },
    );
  }
}
