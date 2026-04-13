import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../../cubits/library/library_cubit.dart';
import '../../widgets/error_view.dart';
import '../../widgets/song_card.dart';
import '../../widgets/section_header.dart';
import '../playlist/playlist_screen.dart';
import '../settings/settings_screen.dart';
import '../list/list_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns = screenWidth > 1200 ? 5 : (screenWidth > 800 ? 3 : 2);
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverAppBar(
          expandedHeight: 100,
          floating: true,
          pinned: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + 12,
                16,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    'Library',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        BlocBuilder<LibraryCubit, LibraryState>(
          builder: (context, state) {
            if (state.isLoading && state.playlists.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (state.error && state.playlists.isEmpty) {
              return SliverFillRemaining(
                child: ErrorView(
                  errorType: state.errorType,
                  onRetry: () => context.read<LibraryCubit>().reload(),
                ),
              );
            }

            return SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LibraryShortcuts(state: state),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Remote Playlists'),
                ],
              ),
            );
          },
        ),

        BlocBuilder<LibraryCubit, LibraryState>(
          builder: (context, state) {
            if (state.playlists.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate((context, i) {
                  final pl = state.playlists[i];
                  return _LibraryPlaylistCard(
                    title: pl.name,
                    subtitle: pl.description,
                    imageUrl: pl.thumbnailUrl,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaylistScreen(playlist: pl),
                      ),
                    ),
                  );
                }, childCount: state.playlists.length),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _LibraryShortcuts extends StatelessWidget {
  final LibraryState state;
  const _LibraryShortcuts({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _ShortcutTile(
            title: 'Downloaded',
            subtitle: '${state.downloadedSongs.length} songs',
            icon: Icons.download_done_rounded,
            color: const Color(0xFF10B981),
            isWide: true,
            onTap: () => _openSongList(
              context,
              'Downloaded',
              state.downloadedSongs,
              ListCategory.downloaded,
            ),
          ),
          const SizedBox(height: 12),
          _ShortcutTile(
            title: 'Flow Favourites',
            subtitle: '${state.likedSongs.length} songs',
            icon: Icons.favorite_rounded,
            color: const Color(0xFFEC4899),
            isWide: true,
            onTap: () => _openSongList(
              context,
              'Flow Favourites',
              state.likedSongs,
              ListCategory.favourites,
            ),
          ),
          const SizedBox(height: 12),
          _ShortcutTile(
            title: 'YouTube Likes',
            subtitle: '${state.remoteLikedSongs.length} songs from YouTube',
            icon: Icons.subscriptions_rounded,
            color: const Color(0xFFFF0000),
            isWide: true,
            onTap: () => _openSongList(
              context,
              'YouTube Likes',
              state.remoteLikedSongs,
              ListCategory.youtubeLikes,
            ),
          ),
        ],
      ),
    );
  }

  void _openSongList(
    BuildContext context,
    String title,
    List<Song> songs,
    ListCategory category,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ListScreen(title: title, initialSongs: songs, category: category),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isWide;
  final Widget? trailing;

  const _ShortcutTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isWide = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withAlpha(180),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withAlpha(30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(120),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (isWide)
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withAlpha(40),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _LibraryPlaylistCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onTap;

  const _LibraryPlaylistCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: imageUrl == null
                  ? Center(
                      child: Icon(
                        Icons.playlist_play_rounded,
                        size: 40,
                        color: cs.onSurface.withAlpha(40),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withAlpha(120),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
