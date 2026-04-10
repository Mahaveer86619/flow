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
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/home/home_cubit.dart';
import '../../widgets/artist_card.dart';
import '../../widgets/error_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/song_card.dart';
import '../artist/artist_screen.dart';
import '../auth/auth_screen.dart';
import '../list/list_screen.dart';
import '../player/player_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeCubit>().state;

    if (state.isLoading) return const _HomeScreenSkeleton();

    if (state.error) {
      return ErrorView(
        errorType: state.errorType,
        onRetry: () => context.read<HomeCubit>().reload(),
      );
    }

    final isSmall = Breakpoints.isMobile(MediaQuery.sizeOf(context).width);

    return CustomScrollView(
      slivers: [
        // ── Sign-in banner (unauthenticated) ──────────────────────────────────
        if (!state.isAuthenticated)
          SliverToBoxAdapter(child: _SignInBanner()),

        // ── Greeting ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, state.isAuthenticated ? 4 : 12, 16, 0),
            child: Text(
              state.greeting,
              style: GoogleFonts.spaceGrotesk(
                fontSize: isSmall ? 19.0 : 24.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        // ── Quick Access 2-col grid ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
            child: SizedBox(
              height: 130,
              child: _QuickAccessGrid(
                songs: state.quickAccess,
                allSongs: state.allSongs,
              ),
            ),
          ),
        ),

        // ── Listening Again ───────────────────────────────────────────────────
        if (state.listeningAgain.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              child: SectionHeader(
                title: 'Listening Again',
                onSeeAll: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListScreen(
                      title: 'Listening Again',
                      songs: state.listeningAgain,
                      allSongs: state.allSongs,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 190,
              child: _HorizontalSongRow(
                songs: state.listeningAgain,
                allSongs: state.allSongs,
              ),
            ),
          ),
        ],

        // ── Forgotten Favorites ───────────────────────────────────────────────
        if (state.forgottenFavorites.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              child: SectionHeader(
                title: 'Forgotten Favorites',
                onSeeAll: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListScreen(
                      title: 'Forgotten Favorites',
                      songs: state.forgottenFavorites,
                      allSongs: state.allSongs,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 190,
              child: _HorizontalSongRow(
                songs: state.forgottenFavorites,
                allSongs: state.allSongs,
              ),
            ),
          ),
        ],

        // ── Music For You — 2-row horizontal grid ─────────────────────────────
        if (state.musicForYou.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              child: SectionHeader(
                title: 'Music For You',
                onSeeAll: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListScreen(
                      title: 'Music For You',
                      songs: state.musicForYou,
                      allSongs: state.allSongs,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 340,
              child: _MusicForYouGrid(
                songs: state.musicForYou,
                allSongs: state.allSongs,
              ),
            ),
          ),
        ],

        // ── Trending (worldwide charts) ───────────────────────────────────────
        if (state.trending.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              child: SectionHeader(
                title: 'Trending',
                onSeeAll: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListScreen(
                      title: 'Trending',
                      songs: state.trending,
                      allSongs: state.allSongs,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 190,
              child: _HorizontalSongRow(
                songs: state.trending,
                allSongs: state.allSongs,
              ),
            ),
          ),
        ],

        // ── Trending Artists ──────────────────────────────────────────────────
        if (state.trendingArtists.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              child: SectionHeader(
                title: 'Trending Artists',
                onSeeAll: () {/* TODO: navigate to artists list */},
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 148,
              child: _TrendingArtistRow(
                artists: state.trendingArtists,
                allSongs: state.allSongs,
              ),
            ),
          ),
        ],

        // ── Empty state: unauthenticated with no personalised content ─────────
        if (!state.isAuthenticated &&
            state.listeningAgain.isEmpty &&
            state.forgottenFavorites.isEmpty &&
            state.musicForYou.isEmpty &&
            state.trending.isEmpty &&
            state.trendingArtists.isEmpty)
          SliverToBoxAdapter(child: _EmptyFeedPrompt()),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty feed prompt — shown below Quick Access when unauthenticated with no
// other sections populated from the server.
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyFeedPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 52,
            color: colorScheme.primary.withAlpha(180),
          ),
          const SizedBox(height: 16),
          Text(
            'Discover your music',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to unlock personalised recommendations, listening history, and your playlists.',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withAlpha(150),
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openAuthScreen(context),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Sign in with YouTube Music'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAuthScreen(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    Navigator.of(context)
        .push<bool>(MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: authCubit,
            child: AuthScreen(
              onSubmitHeaders: (h) => authCubit.submitHeaders(h),
            ),
          ),
        ))
        .then((success) {
          if (success == true && context.mounted) {
            context.read<HomeCubit>().reload();
          }
        });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign-in banner — shown at top when not authenticated
// ─────────────────────────────────────────────────────────────────────────────

class _SignInBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(180),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline_rounded,
              color: colorScheme.onPrimaryContainer, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sign in for personalised music',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _openAuthScreen(context),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }

  void _openAuthScreen(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    Navigator.of(context)
        .push<bool>(MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: authCubit,
            child: AuthScreen(
              onSubmitHeaders: (h) => authCubit.submitHeaders(h),
            ),
          ),
        ))
        .then((success) {
          if (success == true && context.mounted) {
            context.read<HomeCubit>().reload();
          }
        });
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

class _QuickAccessTile extends StatelessWidget {
  final Song song;
  final List<Song> allSongs;
  const _QuickAccessTile({required this.song, required this.allSongs});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = Breakpoints.isDesktop(MediaQuery.sizeOf(context).width);

    return GestureDetector(
      onTap: () {
        context.read<PlayerBloc>().add(
          PlayQueueEvent(
            songs: allSongs,
            startIndex: allSongs.indexOf(song),
          ),
        );
        if (!isDesktop) {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, 0.7, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Container(
                width: 60,
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
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                song.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
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
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
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
                          errorBuilder: (_, __, ___) => _MusicForYouFallback(song: song),
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
