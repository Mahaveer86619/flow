import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../cubits/library_cubit.dart';
import '../../cubits/player_cubit.dart';
import '../../models/song.dart';
import '../playlist/playlist_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LibraryCubit>().state;
    final likedCount = context.watch<PlayerCubit>().state.likedSongsCount;
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Library',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () {},
                  tooltip: 'Create playlist',
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: List.generate(LibraryState.filterOptions.length, (i) {
                final selected = state.filterIndex == i;
                return Padding(
                  padding: EdgeInsets.only(
                    right: i < LibraryState.filterOptions.length - 1 ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => context.read<LibraryCubit>().setFilter(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        LibraryState.filterOptions[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: selected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _SpecialPlaylistTile(
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFEC4899),
            name: 'Liked Songs',
            subtitle: '$likedCount songs',
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _PlaylistTile(playlist: state.playlists[i]),
            childCount: state.playlists.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _SpecialPlaylistTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String subtitle;
  const _SpecialPlaylistTile({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: iconColor.withAlpha(35),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: playlist.color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.queue_music_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      title: Text(
        playlist.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(playlist.description),
      trailing: IconButton(
        icon: Icon(
          Icons.more_vert_rounded,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
        ),
        onPressed: () {},
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlaylistScreen(playlist: playlist)),
        );
      },
    );
  }
}
