// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — scrollable feed with music sections.
//
// Sections (all horizontally scrollable):
//   1. Quick Access grid   — 2-col grid of recently accessed songs
//   2. Listening Again     — standard horizontal song cards
//   3. Forgotten Favorites — standard horizontal song cards
//   4. Music For You       — 2-row horizontal grid (portrait cards)
//   5. Trending Artists    — square artist cards
//
// Content data comes from [HomeCubit] / [HomeState].
// To populate sections from a real API, update [HomeCubit._build] or replace
// it with async loading (add a Loading/Loaded state variant to [HomeState]).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/responsive/breakpoints.dart';
import '../../cubits/home_cubit.dart';
import '../../cubits/player_cubit.dart';
import '../../models/song.dart';
import '../../widgets/artist_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/song_card.dart';
import '../player/player_screen.dart';
import '../artist/artist_screen.dart';
import '../list/list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeCubit>().state;

    return CustomScrollView(
      slivers: [
        // ── Greeting ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              state.greeting,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            child: SectionHeader(
              title: 'Listening Again',
              onSeeAll: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListScreen(
                      title: 'Listening Again',
                      songs: state.listeningAgain,
                      allSongs: state.allSongs,
                    ),
                  ),
                );
              },
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

        // ── Forgotten Favorites ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            child: SectionHeader(
              title: 'Forgotten Favorites',
              onSeeAll: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListScreen(
                      title: 'Forgotten Favorites',
                      songs: state.forgottenFavorites,
                      allSongs: state.allSongs,
                    ),
                  ),
                );
              },
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

        // ── Music For You — 2-row horizontal grid ─────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            child: SectionHeader(
              title: 'Music For You',
              onSeeAll: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListScreen(
                      title: 'Music For You',
                      songs: state.musicForYou,
                      allSongs: state.allSongs,
                    ),
                  ),
                );
              },
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

        // ── Trending Artists ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            child: SectionHeader(
              title: 'Trending Artists',
              onSeeAll: () {
                /* TODO: navigate to artists list */
              },
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

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
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

/// Single tile in the quick-access grid — artwork strip on left, title on right.
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
        context.read<PlayerCubit>().playQueue(
          allSongs,
          startIndex: allSongs.indexOf(song),
        );
        // Navigate to full-screen player only on mobile/tablet.
        if (!isDesktop) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
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
            // Coloured artwork strip with fade out effect
            ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [
                    0.0,
                    0.7,
                    1.0,
                  ], // Fade out on the 30% from left to right
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

/// Wraps [SongCard] in a horizontal [ListView].
///
/// [allSongs] is used as the playback queue when a card is tapped so that
/// "next" / "previous" work across the full catalogue, not just this section.
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
        // Queue from the full catalogue so controls stay meaningful.
        queue: allSongs,
        index: allSongs.indexOf(songs[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Music For You — 2-row horizontal grid (portrait cards)
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontal [GridView] with [crossAxisCount] = 2 so two rows scroll together.
///
/// Each cell is a portrait card (artwork + title + artist).
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
        crossAxisCount: 2, // 2 rows visible at once
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        // childAspectRatio = cell width / cell height in a horizontal grid.
        // 0.72 produces portrait cells (~119 × 165 px at 340 px panel height).
        childAspectRatio: 0.72,
      ),
      itemCount: songs.length,
      itemBuilder: (context, i) {
        final song = songs[i];
        return GestureDetector(
          onTap: () {
            context.read<PlayerCubit>().playQueue(
              List<Song>.from(allSongs),
              startIndex: allSongs.indexOf(song),
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
              // Artwork — replace gradient with Image.network when ready
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [song.colorPrimary, song.colorSecondary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 32,
                    color: Colors.white.withAlpha(45),
                  ),
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
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ArtistScreen(artist: artists[i], allSongs: allSongs),
            ),
          );
        },
      ),
    );
  }
}
