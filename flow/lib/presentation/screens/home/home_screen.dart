import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/app_constants.dart';
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
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import '../history/recently_played_screen.dart';

import '../../widgets/text_carousel.dart';

import '../../widgets/skeleton.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeScreenContent();
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        // Local-only data like greeting can be computed immediately or kept from state
        final hour = DateTime.now().hour;
        final localGreeting = hour < 12
            ? 'Good morning'
            : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
        final greeting = state.isLoading ? localGreeting : state.greeting;

        // Pre-compute index map for performance
        final Map<String, int> songIndexMap = {
          for (int i = 0; i < state.allSongs.length; i++)
            state.allSongs[i].id: i,
        };

        return RefreshIndicator(
          onRefresh: () => context.read<HomeCubit>().refresh(),
          backgroundColor: cs.surfaceContainerHigh,
          color: cs.primary,
          edgeOffset: 110,
          displacement: 40,
          child: CustomScrollView(
            cacheExtent: 2000,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── Custom immersive AppBar ─────────────────────────
              SliverAppBar(
                expandedHeight: 110,
                floating: false,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                centerTitle: false,
                title: LayoutBuilder(
                  builder: (context, constraints) {
                    final top = constraints.biggest.height;
                    final isCollapsed = top < 100;
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isCollapsed ? 1.0 : 0.0,
                      child: Text(
                        'Flow',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    );
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  expandedTitleScale: 1.0,
                  background: Stack(
                    children: [
                      Positioned.fill(
                        child: ShaderMask(
                          shaderCallback: (rect) {
                            return const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.transparent, Colors.black],
                              stops: [0.0, 1.0],
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.dstIn,
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                color: theme.scaffoldBackgroundColor
                                    .withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          MediaQuery.paddingOf(context).top + 12,
                          16,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Flow',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.2,
                                      ),
                                    ),
                                    Text(
                                      greeting,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface.withAlpha(
                                          140,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.history_rounded),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RecentlyPlayedScreen(),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                ),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Body Logic ──────────────────────────
              if (state.isLoading && state.shelves.isEmpty)
                const _HomeScreenSkeleton()
              else if (state.noSource)
                const SliverFillRemaining(child: NoSourceView())
              else if (state.error && state.shelves.isEmpty)
                SliverFillRemaining(
                  child: ErrorView(
                    errorType: state.errorType,
                    onRetry: () => context.read<HomeCubit>().reload(),
                  ),
                )
              else ...[
                // ... (rest of the shelves logic)
                // ── Dynamic Shelves (Reordered) ─────────
                ...() {
                  final List<HomeShelf> rawShelves = state.shelves;
                  final List<HomeShelf> displayShelves = [];

                  // 1. Identify priority shelves
                  HomeShelf? listeningAgain;
                  HomeShelf? quickPicks;
                  HomeShelf? freshFinds;
                  HomeShelf? trending;
                  final List<HomeShelf> otherShelves = [];

                  for (final shelf in rawShelves) {
                    if (shelf.section == 'quickPicks' && quickPicks == null) {
                      quickPicks = shelf;
                    } else if ((shelf.section == 'listeningAgain' ||
                            shelf.section == 'frequentListens') &&
                        listeningAgain == null) {
                      listeningAgain = shelf;
                    } else if (shelf.section == 'freshFinds' &&
                        freshFinds == null) {
                      freshFinds = shelf;
                    } else if (shelf.section == 'trending' &&
                        trending == null) {
                      trending = shelf;
                    } else {
                      otherShelves.add(shelf);
                    }
                  }

                  // 2. Add in requested order
                  if (listeningAgain != null)
                    displayShelves.add(listeningAgain);
                  if (quickPicks != null) displayShelves.add(quickPicks);
                  if (freshFinds != null) displayShelves.add(freshFinds);
                  if (trending != null) displayShelves.add(trending);

                  // 3. Add the rest
                  displayShelves.addAll(otherShelves);

                  return displayShelves.map(
                    (shelf) => SliverPadding(
                      padding: const EdgeInsets.only(bottom: 18),
                      sliver: _HomeShelfRenderer(
                        shelf: shelf,
                        allSongs: state.allSongs,
                        songIndexMap: songIndexMap,
                        profileUrl: state.profileUrl,
                        ytName: state.ytName,
                      ),
                    ),
                  );
                }(),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HomeShelfRenderer extends StatelessWidget {
  final HomeShelf shelf;
  final List<Song> allSongs;
  final Map<String, int> songIndexMap;
  final String? profileUrl;
  final String? ytName;

  const _HomeShelfRenderer({
    required this.shelf,
    required this.allSongs,
    required this.songIndexMap,
    this.profileUrl,
    this.ytName,
  });

  @override
  Widget build(BuildContext context) {
    final section = shelf.section;

    switch (section) {
      case 'quickPicks':
        return _buildQuickAccessRow(context, 'lets start with a radio', null);
      case 'listeningAgain':
      case 'frequentListens':
        return _buildListenAgainShelf(context);
      case 'freshFinds':
        return _buildFreshPicksShelf(context);
      case 'trendingArtists':
        return _buildArtistRow(context, 'Popular Artists', null);
      case 'newArrivals':
        return _buildFreshFindsStaggered(context, null, null);
      case 'recentlyPlayed':
      case 'pickedForYou':
      case 'forgottenFavorites':
        return _buildStandardRow(context, null, null);
      case 'albumsForYou':
        return _buildPlaylistRow(context, null, null);
      case 'moodsAndGenres':
        return _buildStandardRow(context, null, null);
      case 'musicVideos':
      case 'videoRecommendations':
        return _buildVideoRow(context);
      case 'favArtistsSongs':
        return _buildStandardRow(context, 'from your fav artists', null);
      case 'topCharts':
        return _buildTopCharts(context);
      case 'featuredGrid':
        return _buildFeaturedGrid(context);
      case 'artistSpotlight':
        return _buildArtistRow(context, null, null);
      case 'moodMix':
        return _buildStandardRow(context, null, null, cardWidth: 160);
      case 'similarTo':
        return _buildStandardRow(context, 'fans also like', null);
      default:
        // Fallback logic
        final itemTypes = shelf.items.map((e) => e.type).toSet();
        if (itemTypes.contains(HomeItemType.artist) && shelf.items.length > 2) {
          return _buildArtistRow(context, null, null);
        }
        if (itemTypes.contains(HomeItemType.album) ||
            itemTypes.contains(HomeItemType.playlist)) {
          return _buildPlaylistRow(context, null, null);
        }
        return _buildStandardRow(context, null, null);
    }
  }

  Widget _buildVideoRow(BuildContext context) {
    final songs = shelf.items
        .where((i) => i.type == HomeItemType.song)
        .map((i) => i.data as Song)
        .toList();

    if (songs.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(title: shelf.title)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: songs.length,
                addRepaintBoundaries: true,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SongCard(
                      song: songs[i],
                      queue: allSongs,
                      index: songIndexMap[songs[i].id] ?? 0,
                      cardWidth: 240,
                      aspectRatio: 16 / 9, // Video style
                      heroTag: 'video_art_${songs[i].id}_${shelf.title}_$i',
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopCharts(BuildContext context) {
    final songs = shelf.items
        .where((i) => i.type == HomeItemType.song)
        .map((i) => i.data as Song)
        .take(10)
        .toList();

    if (songs.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(title: shelf.title)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: (songs.length / 3).ceil(),
                addRepaintBoundaries: true,
                itemBuilder: (context, colIndex) {
                  final startIndex = colIndex * 3;
                  final columnSongs = songs.skip(startIndex).take(3).toList();
                  return Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: SizedBox(
                      width: 300,
                      child: Column(
                        children: List.generate(columnSongs.length, (rowIndex) {
                          final song = columnSongs[rowIndex];
                          final rank = startIndex + rowIndex + 1;
                          return _ChartItem(
                            song: song,
                            rank: rank,
                            allSongs: allSongs,
                            index: songIndexMap[song.id] ?? 0,
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedGrid(BuildContext context) {
    final items = shelf.items.take(4).toList();
    if (items.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(title: shelf.title)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.5,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                if (item.type == HomeItemType.song) {
                  final song = item.data as Song;
                  return _FeaturedSmallTile(
                    song: song,
                    allSongs: allSongs,
                    index: songIndexMap[song.id] ?? 0,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListenAgainShelf(BuildContext context) {
    final songs = shelf.items
        .where((i) => i.type == HomeItemType.song)
        .map((i) => i.data as Song)
        .toList();

    if (songs.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeader(
            title: shelf.title,
            profileUrl: profileUrl,
            profileName: ytName,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: songs.length,
                addRepaintBoundaries: true,
                itemBuilder: (context, i) {
                  final song = songs[i];
                  final globalIndex = songIndexMap[song.id] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SongCard(
                      song: song,
                      queue: allSongs,
                      index: globalIndex,
                      cardWidth: 220,
                      aspectRatio: 1.6,
                      heroTag: 'listen_again_${song.id}_$i',
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFreshFindsStaggered(
    BuildContext context,
    String? subtitle,
    String? profileUrl,
  ) {
    final items = shelf.items
        .where(
          (i) =>
              i.type == HomeItemType.song ||
              i.type == HomeItemType.album ||
              i.type == HomeItemType.playlist,
        )
        .take(27)
        .toList();

    if (items.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    // Group items into columns of 3 for staggered grid
    final List<List<HomeItem>> columns = [];
    for (var i = 0; i < items.length; i += 3) {
      final end = (i + 3 < items.length) ? i + 3 : items.length;
      columns.add(items.sublist(i, end));
    }

    const double gap = 16.0;
    const double largeSize = 150.0;
    const double smallSize = 100.0;
    const double totalHeight = largeSize + (smallSize * 2) + (gap * 2);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeader(
            title: shelf.title,
            subtitle: subtitle,
            profileUrl: profileUrl,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: totalHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: columns.length,
                addRepaintBoundaries: true,
                itemBuilder: (context, colIndex) {
                  final columnItems = columns[colIndex];
                  final pattern = [0, 1, 2, 1];
                  final largeIndex = pattern[colIndex % pattern.length];
                  final isRightAligned = colIndex % 2 == 0;

                  return Padding(
                    padding: const EdgeInsets.only(right: gap),
                    child: SizedBox(
                      width: largeSize,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: isRightAligned
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: List.generate(columnItems.length * 2 - 1, (
                          index,
                        ) {
                          if (index.isOdd) return const SizedBox(height: gap);

                          final rowIndex = index ~/ 2;
                          final item = columnItems[rowIndex];
                          final isLarge = rowIndex == largeIndex;

                          if (item.type == HomeItemType.song) {
                            final song = item.data as Song;
                            return _QuickPickStaggeredItem(
                              song: song,
                              isLarge: isLarge,
                              allSongs: allSongs,
                              index: songIndexMap[song.id] ?? 0,
                            );
                          } else {
                            // Handle Album/Playlist as a Song entity for UI consistency
                            final p = item.data as Playlist;
                            final song = Song(
                              id: p.id,
                              title: p.name,
                              artist: p.description,
                              album: p.name,
                              duration: Duration.zero,
                              thumbnailUrl: p.thumbnailUrl,
                              colorPrimary: p.color,
                              colorSecondary: p.color,
                            );
                            return _QuickPickStaggeredItem(
                              song: song,
                              isLarge: isLarge,
                              allSongs:
                                  const [], // Cannot play album directly as song yet
                              index: 0,
                            );
                          }
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessRow(
    BuildContext context,
    String? subtitle,
    String? profileUrl,
  ) {
    final songs = shelf.items
        .where((i) => i.type == HomeItemType.song)
        .map((i) => i.data as Song)
        .toList();

    if (songs.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    // 4 rows, up to 6 columns = 24 items
    final displaySongs = songs.take(24).toList();

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeader(
            title: shelf.title,
            subtitle: subtitle,
            profileUrl: profileUrl,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 260, // Height for 4 items (~60 each)
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: (displaySongs.length / 4).ceil(),
                addRepaintBoundaries: true,
                itemBuilder: (context, colIndex) {
                  final startIndex = colIndex * 4;
                  final columnSongs = displaySongs
                      .skip(startIndex)
                      .take(4)
                      .toList();
                  return Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: SizedBox(
                      width: 300,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: columnSongs.map((song) {
                          return _QuickPickListTile(
                            song: song,
                            allSongs: allSongs,
                            index: songIndexMap[song.id] ?? 0,
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFreshPicksShelf(BuildContext context) {
    final songs = shelf.items
        .where((i) => i.type == HomeItemType.song)
        .map((i) => i.data as Song)
        .toList();

    if (songs.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    // 4 rows, up to 6 columns = 24 items
    final displaySongs = songs.take(24).toList();

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(title: shelf.title)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 480, // Height for 4 square cards (~110 each + gap)
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: (displaySongs.length / 4).ceil(),
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, colIndex) {
                  final startIndex = colIndex * 4;
                  final columnSongs = displaySongs
                      .skip(startIndex)
                      .take(4)
                      .toList();
                  return SizedBox(
                    width: 150,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: columnSongs.map((song) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _QuickPickStaggeredItem(
                            song: song,
                            isLarge: false,
                            allSongs: allSongs,
                            index: songIndexMap[song.id] ?? 0,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtistRow(
    BuildContext context,
    String? subtitle,
    String? profileUrl,
  ) {
    final artists = shelf.items
        .where((i) => i.type == HomeItemType.artist)
        .map((i) => i.data as Map<String, dynamic>)
        .toList();

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeader(
            title: shelf.title,
            subtitle: subtitle,
            profileUrl: profileUrl,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: artists.length,
                addRepaintBoundaries: true,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: ArtistCard(
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
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistRow(
    BuildContext context,
    String? subtitle,
    String? profileUrl, {
    bool isAlbum = false,
  }) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeader(
            title: shelf.title,
            subtitle: subtitle,
            profileUrl: profileUrl,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: shelf.items.length,
                addRepaintBoundaries: true,
                itemBuilder: (context, i) {
                  final item = shelf.items[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Builder(
                      builder: (context) {
                        if (item.type == HomeItemType.song) {
                          final song = item.data as Song;
                          return SongCard(
                            song: song,
                            queue: allSongs,
                            index: songIndexMap[song.id] ?? 0,
                            heroTag: 'card_art_${song.id}_${shelf.title}_$i',
                          );
                        }
                        final playlist = item.data as Playlist;
                        return _HomePlaylistCard(
                          playlist: playlist,
                          isAlbum: item.type == HomeItemType.album || isAlbum,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStandardRow(
    BuildContext context,
    String? subtitle,
    String? profileUrl, {
    double cardWidth = 135,
  }) {
    final songs = shelf.items
        .where((i) => i.type == HomeItemType.song)
        .map((i) => i.data as Song)
        .toList();

    if (songs.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeader(
            title: shelf.title,
            subtitle: subtitle,
            profileUrl: profileUrl,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: cardWidth + 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: songs.length,
                addRepaintBoundaries: true,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: SongCard(
                      song: songs[i],
                      queue: allSongs,
                      index: songIndexMap[songs[i].id] ?? 0,
                      cardWidth: cardWidth,
                      heroTag: 'card_art_${songs[i].id}_${shelf.title}_$i',
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartItem extends StatelessWidget {
  final Song song;
  final int rank;
  final List<Song> allSongs;
  final int index;

  const _ChartItem({
    required this.song,
    required this.rank,
    required this.allSongs,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cacheSize = (56 * MediaQuery.devicePixelRatioOf(context)).round();

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          context.read<PlayerBloc>().add(
            PlayQueueEvent(songs: List<Song>.from(allSongs), startIndex: index),
          );
          if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
            PlayerScreen.show(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '$rank',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withAlpha(100),
                  ),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.mediumBorderRadius,
                  color: theme.colorScheme.surfaceContainerHigh,
                ),
                clipBehavior: Clip.antiAlias,
                child: song.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: song.thumbnailUrl!,
                        fit: BoxFit.fill,
                        maxWidthDiskCache: cacheSize,
                        maxHeightDiskCache: cacheSize,
                        placeholder: (context, url) => _fallback(),
                        errorWidget: (context, url, error) => _fallback(),
                      )
                    : _fallback(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(140),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [song.colorPrimary, song.colorSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          'f',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _FeaturedSmallTile extends StatelessWidget {
  final Song song;
  final List<Song> allSongs;
  final int index;

  const _FeaturedSmallTile({
    required this.song,
    required this.allSongs,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cacheSize = (80 * MediaQuery.devicePixelRatioOf(context)).round();

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          context.read<PlayerBloc>().add(
            PlayQueueEvent(songs: List<Song>.from(allSongs), startIndex: index),
          );
          if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
            PlayerScreen.show(context);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: AppRadius.largeBorderRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: song.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: song.thumbnailUrl!,
                        fit: BoxFit.fill,
                        maxWidthDiskCache: cacheSize,
                        maxHeightDiskCache: cacheSize,
                        placeholder: (context, url) =>
                            Container(color: song.colorPrimary.withAlpha(50)),
                        errorWidget: (context, url, error) =>
                            Container(color: song.colorPrimary),
                      )
                    : Container(color: song.colorPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  song.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListenAgainItem extends StatelessWidget {
  final Song song;
  final List<Song> allSongs;
  final int index;

  const _ListenAgainItem({
    required this.song,
    required this.allSongs,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = Breakpoints.isDesktop(MediaQuery.sizeOf(context).width);
    final cacheSize = (48 * MediaQuery.devicePixelRatioOf(context)).round();

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          context.read<PlayerBloc>().add(
            PlayQueueEvent(songs: List<Song>.from(allSongs), startIndex: index),
          );
          if (!isDesktop) {
            PlayerScreen.show(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.mediumBorderRadius,
                  color: colorScheme.surfaceContainerHigh,
                ),
                clipBehavior: Clip.antiAlias,
                child: song.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: song.thumbnailUrl!,
                        fit: BoxFit.fill,
                        maxWidthDiskCache: cacheSize,
                        maxHeightDiskCache: cacheSize,
                        placeholder: (context, url) => _fallback(),
                        errorWidget: (context, url, error) => _fallback(),
                      )
                    : _fallback(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextCarousel(
                      text: song.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      song.artist,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withAlpha(140),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [song.colorPrimary, song.colorSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          'f',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _HomePlaylistCard extends StatefulWidget {
  final Playlist playlist;
  final bool isAlbum;
  const _HomePlaylistCard({required this.playlist, this.isAlbum = false});

  @override
  State<_HomePlaylistCard> createState() => _HomePlaylistCardState();
}

class _HomePlaylistCardState extends State<_HomePlaylistCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cacheSize = (280 * MediaQuery.devicePixelRatioOf(context)).round();

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlaylistScreen(
                playlist: widget.playlist,
                isAlbum: widget.isAlbum,
              ),
            ),
          ),
          child: SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: AnimatedScale(
                    scale: _isHovered ? 1.04 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.playlist.color,
                        borderRadius: AppRadius.mediumBorderRadius,
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
                              child: CachedNetworkImage(
                                imageUrl: widget.playlist.thumbnailUrl!,
                                fit: BoxFit.fill,
                                maxWidthDiskCache: cacheSize,
                                maxHeightDiskCache: cacheSize,
                                placeholder: (context, url) => _fallbackIcon(),
                                errorWidget: (context, url, error) =>
                                    _fallbackIcon(),
                              ),
                            )
                          else
                            _fallbackIcon(),

                          if (_isHovered)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withAlpha(30),
                                child: const Center(
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 42,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.playlist.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  widget.playlist.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withAlpha(140),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return const Center(
      child: Icon(Icons.queue_music_rounded, color: Colors.white, size: 48),
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
    return SliverMainAxisGroup(
      slivers: [
        // Featured Grid Skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.5,
              ),
              itemCount: 4,
              itemBuilder: (context, i) =>
                  const Skeleton(borderRadius: AppRadius.medium),
            ),
          ),
        ),

        // Multiple Rows of Shelves
        for (int i = 0; i < 5; i++) ...[
          const _SkeletonSectionHeader(),
          _SkeletonHorizontalRow(isArtist: i == 2),
        ],
      ],
    );
  }
}

class _SkeletonSectionHeader extends StatelessWidget {
  const _SkeletonSectionHeader();

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: SkeletonText(width: 150, height: 20),
      ),
    );
  }
}

class _SkeletonHorizontalRow extends StatelessWidget {
  final bool isArtist;
  const _SkeletonHorizontalRow({this.isArtist = false});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: isArtist ? 130 : 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, __) =>
              isArtist ? const SkeletonArtistCard() : const SkeletonSongCard(),
        ),
      ),
    );
  }
}

class _QuickPickStaggeredItem extends StatefulWidget {
  final Song song;
  final bool isLarge;
  final List<Song> allSongs;
  final int index;

  const _QuickPickStaggeredItem({
    required this.song,
    required this.isLarge,
    required this.allSongs,
    required this.index,
  });

  @override
  State<_QuickPickStaggeredItem> createState() =>
      _QuickPickStaggeredItemState();
}

class _QuickPickStaggeredItemState extends State<_QuickPickStaggeredItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = widget.isLarge ? 150.0 : 100.0;
    const totalWidth = 150.0;
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            context.read<PlayerBloc>().add(
              PlayQueueEvent(songs: widget.allSongs, startIndex: widget.index),
            );
            if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
              PlayerScreen.show(context);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: totalWidth,
            child: Hero(
              tag: 'quick_art_${widget.song.id}_${widget.isLarge}',
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.mediumBorderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Artwork
                    if (widget.song.thumbnailUrl != null)
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: widget.song.thumbnailUrl!,
                          fit: BoxFit.fill,
                          maxWidthDiskCache: cacheSize,
                          maxHeightDiskCache: cacheSize,
                          placeholder: (context, url) => _fallback(),
                          errorWidget: (context, url, error) => _fallback(),
                        ),
                      )
                    else
                      _fallback(),

                    // Text Overlay (Bottom)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 24, 10, 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withAlpha(200),
                              Colors.black.withAlpha(0),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextCarousel(
                              text: widget.song.title,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: widget.isLarge ? 13 : 10,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              widget.song.artist,
                              style: GoogleFonts.outfit(
                                fontSize: widget.isLarge ? 11 : 8,
                                color: Colors.white.withAlpha(180),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_isHovered)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withAlpha(40),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.song.colorPrimary, widget.song.colorSecondary],
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _QuickPickListTile extends StatelessWidget {
  final Song song;
  final List<Song> allSongs;
  final int index;

  const _QuickPickListTile({
    required this.song,
    required this.allSongs,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cacheSize = (48 * MediaQuery.devicePixelRatioOf(context)).round();

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          context.read<PlayerBloc>().add(
            PlayQueueEvent(songs: List<Song>.from(allSongs), startIndex: index),
          );
          if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
            PlayerScreen.show(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.smallBorderRadius,
                  color: theme.colorScheme.surfaceContainerHigh,
                ),
                clipBehavior: Clip.antiAlias,
                child: song.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: song.thumbnailUrl!,
                        fit: BoxFit.fill,
                        maxWidthDiskCache: cacheSize,
                        maxHeightDiskCache: cacheSize,
                        placeholder: (context, url) => _fallback(),
                        errorWidget: (context, url, error) => _fallback(),
                      )
                    : _fallback(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withAlpha(140),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [song.colorPrimary, song.colorSecondary],
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Colors.white24, size: 20),
      ),
    );
  }
}
