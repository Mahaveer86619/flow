// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — scrollable feed with music sections.
//
// Sections (all horizontally scrollable):
//   1. Quick Access grid   — 2-col grid of recently accessed songs
//   2. Listening Again     — standard horizontal song cards
//   3. Forgotten Favorites — standard horizontal song cards
//   4. Music For You       — 2-row horizontal grid (portrait cards)
//   5. Trending Artists    — square artist cards
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../../cubits/home/home_cubit.dart';
import '../../widgets/artist_card.dart';
import '../../widgets/error_view.dart';
import '../../widgets/no_source_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/song_card.dart';
import '../artist/artist_screen.dart';
import '../list/list_screen.dart';
import '../player/player_screen.dart';

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

    return CustomScrollView(
      cacheExtent: 1000, // Pre-render some area to smooth scrolling
      slivers: [
        // ── Greeting ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: BlocBuilder<HomeCubit, HomeState>(
              buildWhen: (prev, curr) => prev.greeting != curr.greeting,
              builder: (context, state) => Text(
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
        ),

        // ── Quick Access 2-col grid ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
            child: SizedBox(
              height: 140,
              child: BlocBuilder<HomeCubit, HomeState>(
                buildWhen: (prev, curr) => prev.quickAccess != curr.quickAccess,
                builder: (context, state) => RepaintBoundary(
                  child: _QuickAccessGrid(
                    songs: state.quickAccess,
                    allSongs: state.allSongs,
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Listening Again ───────────────────────────────────────────────────
        _HomeSection(
          title: 'Listening Again',
          selector: (s) => s.listeningAgain,
          builder: (songs, allSongs) =>
              _HorizontalSongRow(songs: songs, allSongs: allSongs),
        ),

        // ── Forgotten Favorites ───────────────────────────────────────────────
        _HomeSection(
          title: 'Forgotten Favorites',
          selector: (s) => s.forgottenFavorites,
          builder: (songs, allSongs) =>
              _HorizontalSongRow(songs: songs, allSongs: allSongs),
        ),

        // ── Music For You — 2-row horizontal grid ─────────────────────────────
        _HomeSection(
          title: 'Music For You',
          selector: (s) => s.musicForYou,
          height: 340,
          builder: (songs, allSongs) =>
              _MusicForYouGrid(songs: songs, allSongs: allSongs),
        ),

        // ── Trending (worldwide charts) ───────────────────────────────────────
        _HomeSection(
          title: 'Trending',
          selector: (s) => s.trending,
          builder: (songs, allSongs) =>
              _HorizontalSongRow(songs: songs, allSongs: allSongs),
        ),

        // ── Trending Artists ──────────────────────────────────────────────────
        _HomeSection(
          title: 'Trending Artists',
          selector: (s) => s.trendingArtists,
          height: 160,
          builder: (artists, allSongs) => _TrendingArtistRow(
            artists: artists as List<Map<String, dynamic>>,
            allSongs: allSongs,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _HomeSection<T> extends StatelessWidget {
  final String title;
  final List<T> Function(HomeState) selector;
  final Widget Function(List<T> items, List<Song> allSongs) builder;
  final double height;

  const _HomeSection({
    required this.title,
    required this.selector,
    required this.builder,
    this.height = 190,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, curr) => selector(prev) != selector(curr),
      builder: (context, state) {
        final items = selector(state);
        if (items.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
                child: SectionHeader(
                  title: title,
                  onSeeAll: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ListScreen(
                        title: title,
                        songs: items.every((e) => e is Song)
                            ? items.cast<Song>()
                            : [], // Should not happen for song sections
                        allSongs: state.allSongs,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: height,
                child: RepaintBoundary(child: builder(items, state.allSongs)),
              ),
            ),
          ],
        );
      },
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
        // Greeting placeholder
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _SkeletonBox(width: 180, height: 26, radius: 8),
          ),
        ),

        // Quick Access grid skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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

        // Listening Again skeleton
        _SkeletonSectionHeader(),
        _SkeletonHorizontalRow(),

        // Forgotten Favorites skeleton
        _SkeletonSectionHeader(),
        _SkeletonHorizontalRow(),

        // Music For You skeleton
        _SkeletonSectionHeader(),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 340,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const SkeletonSongCard(cardWidth: 120),
            ),
          ),
        ),

        // Trending Artists skeleton
        _SkeletonSectionHeader(),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) => const SkeletonArtistCard(),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SkeletonBox(width: 140, height: 18, radius: 7),
            _SkeletonBox(width: 55, height: 14, radius: 6),
          ],
        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Quick Access grid (2-column, fixed height tiles)
// ─────────────────────────────────────────────────────────────────────────────

class _QuickAccessGrid extends StatelessWidget {
  final List<Song> songs;
  final List<Song> allSongs;
  const _QuickAccessGrid({required this.songs, required this.allSongs});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 8,
        childAspectRatio: 0.35,
      ),
      itemCount: songs.length,
      itemBuilder: (context, i) =>
          _QuickAccessTile(song: songs[i], allSongs: allSongs),
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

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal song row (Listening Again / Forgotten Favorites)
// ─────────────────────────────────────────────────────────────────────────────

class _HorizontalSongRow extends StatelessWidget {
  final List<Song> songs;
  final List<Song> allSongs;
  const _HorizontalSongRow({required this.songs, required this.allSongs});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: songs.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (context, i) => SongCard(
        song: songs[i],
        queue: allSongs,
        index: allSongs.indexOf(songs[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Music For You — 2-row horizontal grid (portrait cards)
// ─────────────────────────────────────────────────────────────────────────────

class _MusicForYouGrid extends StatelessWidget {
  final List<Song> songs;
  final List<Song> allSongs;
  const _MusicForYouGrid({required this.songs, required this.allSongs});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = Breakpoints.isDesktop(MediaQuery.sizeOf(context).width);

    return GridView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: songs.length,
      itemBuilder: (context, i) {
        final song = songs[i];
        return GestureDetector(
          onTap: () {
            context.read<PlayerBloc>().add(
              PlayQueueEvent(
                songs: List<Song>.from(allSongs),
                startIndex: allSongs.indexOf(song),
              ),
            );
            if (!isDesktop) {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: song.thumbnailUrl != null
                      ? Image.network(
                          song.thumbnailUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              _MusicForYouFallback(song: song),
                        )
                      : _MusicForYouFallback(song: song),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                song.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                song.artist,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withAlpha(140),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MusicForYouFallback extends StatelessWidget {
  final Song song;
  const _MusicForYouFallback({required this.song});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [song.colorPrimary, song.colorSecondary],
      ),
    ),
    child: Icon(
      Icons.music_note_rounded,
      size: 32,
      color: Colors.white.withAlpha(45),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Trending Artists row
// ─────────────────────────────────────────────────────────────────────────────

class _TrendingArtistRow extends StatelessWidget {
  final List<Map<String, dynamic>> artists;
  final List<Song> allSongs;
  const _TrendingArtistRow({required this.artists, required this.allSongs});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: artists.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (context, i) => ArtistCard(
        artist: artists[i],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ArtistScreen(artist: artists[i], allSongs: allSongs),
          ),
        ),
      ),
    );
  }
}
