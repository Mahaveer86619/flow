import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../../cubits/library/library_cubit.dart';
import '../../widgets/error_view.dart';
import '../../widgets/song_card.dart';
import '../playlist/playlist_screen.dart';
import '../settings/settings_screen.dart';

class _LibraryFilterDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Theme.of(
        context,
      ).scaffoldBackgroundColor.withAlpha(overlapsContent ? 255 : 0),
      height: 60,
      child: BlocBuilder<LibraryCubit, LibraryState>(
        buildWhen: (prev, curr) => prev.filterIndex != curr.filterIndex,
        builder: (context, state) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: LibraryState.filterOptions.length,
          itemBuilder: (context, i) {
            final selected = state.filterIndex == i;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(LibraryState.filterOptions[i]),
                selected: selected,
                onSelected: (_) => context.read<LibraryCubit>().setFilter(i),
                backgroundColor: colorScheme.surfaceContainerHigh,
                selectedColor: colorScheme.onSurface,
                labelStyle: TextStyle(
                  color: selected ? colorScheme.surface : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide.none,
                ),
                showCheckmark: false,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  double get maxExtent => 60;
  @override
  double get minExtent => 60;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns = screenWidth > 1200 ? 5 : (screenWidth > 800 ? 3 : 2);

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

        // Filter Chips
        SliverPersistentHeader(
          pinned: true,
          delegate: _LibraryFilterDelegate(),
        ),

        BlocBuilder<LibraryCubit, LibraryState>(
          builder: (context, state) {
            final isDownloads = state.filterIndex == 3;
            final items = isDownloads ? state.downloadedSongs : state.playlists;

            if (state.isLoading && items.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (state.error && items.isEmpty) {
              return SliverFillRemaining(
                child: ErrorView(
                  errorType: state.errorType,
                  onRetry: () => context.read<LibraryCubit>().reload(),
                ),
              );
            }

            if (items.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: Text('Nothing here yet')),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isDownloads ? 0.7 : 0.8,
                ),
                delegate: SliverChildBuilderDelegate((context, i) {
                  if (isDownloads) {
                    final song = state.downloadedSongs[i];
                    return SongCard(
                      song: song,
                      queue: state.downloadedSongs,
                      index: i,
                    );
                  }

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
                }, childCount: items.length),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
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
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(140)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
