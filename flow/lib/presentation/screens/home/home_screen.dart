import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/home_data.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../../cubits/home/home_cubit.dart';
import '../../widgets/artist_card.dart';
import '../../widgets/error_view.dart';
import '../../widgets/no_source_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/song_card.dart';
import '../artist/artist_screen.dart';
import '../player/player_screen.dart';
import '../playlist/playlist_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, curr) =>
          prev.isLoading != curr.isLoading ||
          prev.error != curr.error ||
          prev.noSource != curr.noSource,
      builder: (context, state) {
        if (state.isLoading) return const _HomeScreenSkeleton();
        if (state.noSource) return const NoSourceView();
        if (state.error) {
          return ErrorView(
            errorType: state.errorType,
            onRetry: () => context.read<HomeCubit>().reload(),
          );
        }

        return const _HomeScreenContent();
      },
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    final isSmall = Breakpoints.isMobile(MediaQuery.sizeOf(context).width);

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return CustomScrollView(
          cacheExtent: 2000,
          slivers: [
            // ── Greeting ──────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Text(
                  state.greeting,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: isSmall ? 28.0 : 36.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    height: 1.1,
                  ),
                ),
              ),
            ),

            // ── Dynamic Shelves ──────────────────────────────────────────────────
            ...state.shelves.map((shelf) => _HomeShelfRenderer(
                  shelf: shelf,
                  allSongs: state.allSongs,
                )),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      },
    );
  }
}

class _HomeShelfRenderer extends StatelessWidget {
  final HomeShelf shelf;
  final List<Song> allSongs;

  const _HomeShelfRenderer({required this.shelf, required this.allSongs});

  @override
  Widget build(BuildContext context) {
    final title = shelf.title.toLowerCase();
    
    // Determine layout based on title or content
    if (title.contains('quick pick') || title.contains('top pick')) {
      return _buildQuickAccessGrid(context);
    }

    final itemTypes = shelf.items.map((e) => e.type).toSet();
    
    if (itemTypes.contains(HomeItemType.artist) && shelf.items.length > 2) {
      return _buildArtistRow(context);
    }

    if (itemTypes.contains(HomeItemType.album) || itemTypes.contains(HomeItemType.playlist)) {
      return _buildPlaylistRow(context);
    }

    return _buildStandardRow(context);
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    final songs = shelf.items
        .where((i) => i.type == HomeItemType.song)
        .map((i) => i.data as Song)
        .toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
        child: SizedBox(
          height: 140,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 8,
              childAspectRatio: 0.35,
            ),
            itemCount: songs.length,
            itemBuilder: (context, i) => _QuickAccessTile(
              song: songs[i],
              allSongs: allSongs,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistRow(BuildContext context) {
    final artists = shelf.items
        .where((i) => i.type == HomeItemType.artist)
        .map((i) => i.data as Map<String, dynamic>)
        .toList();

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            child: SectionHeader(title: shelf.title),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: artists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) => ArtistCard(
                artist: artists[i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ArtistScreen(
                      artist: artists[i],
                      allSongs: allSongs,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistRow(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            child: SectionHeader(title: shelf.title),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: shelf.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final item = shelf.items[i];
                if (item.type == HomeItemType.song) {
                  return SongCard(song: item.data as Song, queue: allSongs, index: allSongs.indexOf(item.data as Song));
                }
                final playlist = item.data as Playlist;
                return _HomePlaylistCard(playlist: playlist);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStandardRow(BuildContext context) {
    final songs = shelf.items
        .where((i) => i.type == HomeItemType.song)
        .map((i) => i.data as Song)
        .toList();

    if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            child: SectionHeader(title: shelf.title),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: songs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) => SongCard(
                song: songs[i],
                queue: allSongs,
                index: allSongs.indexOf(songs[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomePlaylistCard extends StatefulWidget {
  final Playlist playlist;
  const _HomePlaylistCard({required this.playlist});

  @override
  State<_HomePlaylistCard> createState() => _HomePlaylistCardState();
}

class _HomePlaylistCardState extends State<_HomePlaylistCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlaylistScreen(playlist: widget.playlist)),
        ),
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.04 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: widget.playlist.color,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(_isHovered ? 60 : 40),
                        blurRadius: _isHovered ? 20 : 12,
                        offset: Offset(0, _isHovered ? 8 : 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      if (widget.playlist.thumbnailUrl != null)
                        Positioned.fill(
                          child: Image.network(
                            widget.playlist.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.queue_music_rounded, color: Colors.white, size: 48),
                          ),
                        )
                      else
                        const Center(child: Icon(Icons.queue_music_rounded, color: Colors.white, size: 48)),
                      
                      if (_isHovered)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withAlpha(30),
                            child: const Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 42)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.playlist.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                widget.playlist.description,
                style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(140)),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton — shown while HomeCubit.isLoading == true
// ─────────────────────────────────────────────────────────────────────────────

class _HomeScreenSkeleton extends StatelessWidget {
  const _HomeScreenSkeleton();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: _SkeletonBox(width: 200, height: 32, radius: 8),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: SizedBox(
              height: 130,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.35,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => const SkeletonQuickAccessTile(),
              ),
            ),
          ),
        ),
        for (int i = 0; i < 3; i++) ...[
          _SkeletonSectionHeader(),
          _SkeletonHorizontalRow(),
        ],
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonSectionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        child: _SkeletonBox(width: 140, height: 20, radius: 7),
      ),
    );
  }
}

class _SkeletonHorizontalRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 190,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, __) => const SkeletonSongCard(),
        ),
      ),
    );
  }
}

class _QuickAccessTile extends StatefulWidget {
  final Song song;
  final List<Song> allSongs;
  const _QuickAccessTile({required this.song, required this.allSongs});

  @override
  State<_QuickAccessTile> createState() => _QuickAccessTileState();
}

class _QuickAccessTileState extends State<_QuickAccessTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = Breakpoints.isDesktop(MediaQuery.sizeOf(context).width);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.read<PlayerBloc>().add(
            PlayQueueEvent(
              songs: widget.allSongs,
              startIndex: widget.allSongs.indexOf(widget.song),
            ),
          );
          if (!isDesktop) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              _TileArtwork(song: widget.song),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.song.title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isHovered)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.play_arrow_rounded, size: 24),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileArtwork extends StatelessWidget {
  final Song song;
  const _TileArtwork({required this.song});

  @override
  Widget build(BuildContext context) {
    if (song.thumbnailUrl != null) {
      return Image.network(
        song.thumbnailUrl!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [song.colorPrimary, song.colorSecondary],
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
