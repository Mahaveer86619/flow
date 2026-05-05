import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/app_constants.dart';
import '../../../domain/entities/home_data.dart';
import '../../../domain/entities/song.dart';
import '../../cubits/home/home_cubit.dart';
import '../../widgets/flow_app_bar.dart';
import '../../widgets/shimmer_shelf.dart';
import '../settings/settings_screen.dart';

import 'shelves/quick_picks_shelf.dart';
import 'shelves/listen_again_shelf.dart';
import 'shelves/music_video_shelf.dart';
import 'shelves/podcast_shelf.dart';
import 'shelves/trending_shelf.dart';
import 'shelves/generic_horizontal_shelf.dart';
import 'shelves/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().init();
  }

  // ── Section routing ────────────────────────────────────────────────────────
  //
  // Priority order:
  //   1. Explicit section key (set by GetHomeDataUseCase heuristics)
  //   2. Content-type sniffing (all videos → video shelf; artist → artist shelf)
  //   3. Generic horizontal fallback
  //
  // Add new explicit section keys here as the backend grows.
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildShelf(HomeShelf shelf) {
    if (shelf.items.isEmpty) return const SizedBox.shrink();

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: shelf.title,
              onSeeAll: _hasSeeAll(shelf) ? () {} : null,
            ),
            const SizedBox(height: 12),
            _buildShelfBody(shelf),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  bool _hasSeeAll(HomeShelf shelf) {
    const explicitSections = {
      'trending',
      'newReleases',
      'recommendedAlbums',
      'podcasts',
      'musicVideos',
    };
    if (shelf.section != null && explicitSections.contains(shelf.section)) {
      return true;
    }
    // Any shelf that is purely playlists or albums is browsable
    if (_shelfContentType(shelf.items) == _ShelfContent.playlistsOrAlbums) {
      return true;
    }
    return false;
  }

  Widget _buildShelfBody(HomeShelf shelf) {
    final onSongTap = (Song song, List<Song> queue, int index) {
      // TODO: dispatch to your PlayerCubit / AudioService
    };

    // ── 1. Explicit section key routing ──────────────────────────────────────
    switch (shelf.section) {
      case 'quickPicks':
        return QuickPicksShelf(items: shelf.items, onSongTap: onSongTap);

      case 'listeningAgain':
        return ListenAgainShelf(items: shelf.items, onSongTap: onSongTap);

      case 'musicVideos':
        return MusicVideoShelf(items: shelf.items, onSongTap: onSongTap);

      case 'podcasts':
        return PodcastShelf(
          items: shelf.items,
          onItemTap: (item) {
            // TODO: navigate to podcast episode screen
          },
        );

      case 'trending':
        return TrendingShelf(items: shelf.items, onSongTap: onSongTap);

      case 'newReleases':
        return GenericHorizontalShelf(
          items: shelf.items,
          onSongTap: onSongTap,
          cardWidth: 150,
        );

      case 'artists':
        return GenericHorizontalShelf(
          items: shelf.items,
          onSongTap: onSongTap,
          cardWidth: 110,
          circleArt: true,
          showArtist: false,
        );
    }

    // ── 2. Content-type sniffing (section == null or unrecognised) ────────────
    //
    // Inspect what item types are actually in this shelf so we can pick the
    // right widget even when the title-keyword heuristic didn't fire.
    switch (_shelfContentType(shelf.items)) {
      // All items are videos (16:9 aspect ratio, UGC/livestreams, etc.)
      case _ShelfContent.videos:
        return MusicVideoShelf(items: shelf.items, onSongTap: onSongTap);

      // All items are artists — circular portrait cards
      case _ShelfContent.artists:
        return GenericHorizontalShelf(
          items: shelf.items,
          onSongTap: onSongTap,
          cardWidth: 110,
          circleArt: true,
          showArtist: false,
        );

      // Playlists / albums — square art, description subtitle
      case _ShelfContent.playlistsOrAlbums:
        return GenericHorizontalShelf(
          items: shelf.items,
          onSongTap: onSongTap,
          cardWidth: 140,
        );

      // Songs or mixed — standard horizontal card list
      case _ShelfContent.songs:
      case _ShelfContent.mixed:
        return GenericHorizontalShelf(
          items: shelf.items,
          onSongTap: onSongTap,
          cardWidth: 140,
        );
    }
  }

  /// Classifies the dominant content type of a shelf's items.
  _ShelfContent _shelfContentType(List<HomeItem> items) {
    if (items.isEmpty) return _ShelfContent.mixed;

    final types = items.map((i) => i.type).toSet();

    if (types.length == 1) {
      switch (types.first) {
        case HomeItemType.video:
          return _ShelfContent.videos;
        case HomeItemType.artist:
          return _ShelfContent.artists;
        case HomeItemType.album:
        case HomeItemType.playlist:
          return _ShelfContent.playlistsOrAlbums;
        case HomeItemType.song:
          return _ShelfContent.songs;
      }
    }

    // Mixed: if majority are videos treat as video shelf
    final videoCount = items.where((i) => i.type == HomeItemType.video).length;
    if (videoCount > items.length / 2) return _ShelfContent.videos;

    // If majority are playlists/albums treat as playlist shelf
    final playlistCount = items
        .where(
          (i) =>
              i.type == HomeItemType.playlist || i.type == HomeItemType.album,
        )
        .length;
    if (playlistCount > items.length / 2)
      return _ShelfContent.playlistsOrAlbums;

    return _ShelfContent.mixed;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().refresh(),
            displacement: 100 + padding.top,
            color: cs.primary,
            backgroundColor: cs.surfaceContainerHigh,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                const FlowAppBar(title: 'flow'),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: _GreetingHeader(),
                  ),
                ),

                if (state.status == HomeStatus.loading && state.shelves.isEmpty)
                  _buildShimmerLoading()
                else if (state.status == HomeStatus.failure &&
                    state.shelves.isEmpty)
                  SliverFillRemaining(child: _buildErrorState(state, padding))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildShelf(state.shelves[index]),
                      childCount: state.shelves.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 180)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Shimmer loading ────────────────────────────────────────────────────────

  Widget _buildShimmerLoading() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const SectionHeader(title: 'Quick Picks'),
          const SizedBox(height: 12),
          const ShimmerShelf(isGrid: true),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Recommended'),
          const SizedBox(height: 12),
          const ShimmerShelf(),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Trending'),
          const SizedBox(height: 12),
          const ShimmerShelf(),
        ]),
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildErrorState(HomeState state, EdgeInsets padding) {
    final is400 = state.errorCode == '400';
    final message = is400
        ? 'YouTube Music configuration error (400)'
        : (state.error ?? 'Failed to load feed');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              is400
                  ? Icons.settings_suggest_rounded
                  : Icons.error_outline_rounded,
              color: is400 ? Colors.orangeAccent : Colors.redAccent,
              size: 56,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              is400
                  ? 'Your YouTube Music cookies or visitor data might be invalid. '
                        'Please re-configure the source in Settings.'
                  : 'Try checking your YouTube Music connection in Settings.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (is400)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    icon: const Icon(Icons.settings_rounded, size: 18),
                    label: const Text('Go to Settings'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  )
                else ...[
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: const Text('Settings'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => context.read<HomeCubit>().refresh(),
                    child: const Text('Try Again'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Internal enum for content-type sniffing ───────────────────────────────────

enum _ShelfContent { songs, videos, artists, playlistsOrAlbums, mixed }

// ── Greeting header ───────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!AppConfig.intelligenceActive) return const SizedBox(height: 4);

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    return Text(
      greeting,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white60,
      ),
    );
  }
}
