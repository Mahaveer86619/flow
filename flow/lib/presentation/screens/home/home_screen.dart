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
import '../../widgets/personality_bot_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/song_card.dart';
import '../artist/artist_screen.dart';
import '../player/player_screen.dart';
import '../playlist/playlist_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import '../history/recently_played_screen.dart';
import '../../widgets/text_carousel.dart';

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

        final hour = DateTime.now().hour;
        final localGreeting = hour < 12
            ? 'Good morning'
            : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
        final greeting = state.isLoading ? localGreeting : state.greeting;

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
                                color: theme.scaffoldBackgroundColor.withAlpha(80),
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
                                        color: colorScheme.onSurface.withAlpha(140),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.history_rounded),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const RecentlyPlayedScreen()),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.settings_outlined),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                  ),
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

              if (state.isLoading && state.shelves.isEmpty)
                const SliverFillRemaining(child: PersonalityBotView(isLoading: true))
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
                ...() {
                  final List<HomeShelf> displayShelves = List.from(state.shelves);
                  final requestedSections = [
                    ('Quick Picks', 'quickPicks', Icons.bolt_outlined),
                    ('Listen Again', 'listeningAgain', Icons.history_rounded),
                    ('Fresh Picks', 'newArrivals', Icons.new_releases_outlined),
                    ('Music Videos', 'musicVideos', Icons.play_circle_outline_rounded),
                    ('Long Listening', 'longListening', Icons.timer_outlined),
                    ('Podcasts', 'podcasts', Icons.podcasts_rounded),
                  ];

                  // Merge mandatory layout shells
                  for (final req in requestedSections) {
                    if (!displayShelves.any((s) => s.section == req.$2)) {
                      displayShelves.add(HomeShelf(title: req.$1, section: req.$2, items: const []));
                    }
                  }

                  // Strict sorting
                  displayShelves.sort((a, b) {
                    final indexA = requestedSections.indexWhere((r) => r.$2 == a.section);
                    final indexB = requestedSections.indexWhere((r) => r.$2 == b.section);
                    if (indexA == -1 && indexB == -1) return 0;
                    if (indexA == -1) return 1;
                    if (indexB == -1) return -1;
                    return indexA.compareTo(indexB);
                  });

                  return displayShelves.map(
                    (shelf) {
                      final req = requestedSections.firstWhere(
                        (r) => r.$2 == shelf.section,
                        orElse: () => ('', '', Icons.help_outline_rounded),
                      );
                      return SliverPadding(
                        padding: const EdgeInsets.only(bottom: 18),
                        sliver: _HomeShelfRenderer(
                          shelf: shelf,
                          allSongs: state.allSongs,
                          songIndexMap: songIndexMap,
                          profileUrl: state.profileUrl,
                          ytName: state.ytName,
                          icon: req.$3,
                        ),
                      );
                    },
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
  final IconData? icon;

  const _HomeShelfRenderer({
    required this.shelf,
    required this.allSongs,
    required this.songIndexMap,
    this.profileUrl,
    this.ytName,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final section = shelf.section;

    switch (section) {
      case 'quickPicks':
        return shelf.items.isEmpty 
          ? _buildEmptySliver(context, shelf.title, icon ?? Icons.bolt_outlined, 'No quick picks yet. Try playing some music!')
          : _buildQuickAccessRow(context, 'lets start with a radio', null, icon: icon);
      case 'listeningAgain':
        return shelf.items.isEmpty 
          ? _buildEmptySliver(context, shelf.title, icon ?? Icons.history_rounded, 'Your recent history will appear here.')
          : _buildListenAgainShelf(context, icon: icon);
      case 'newArrivals':
        return shelf.items.isEmpty 
          ? _buildEmptySliver(context, shelf.title, icon ?? Icons.new_releases_outlined, 'Fetching "Your daily discover"...')
          : _buildFreshFindsStaggered(context, 'personalized for you', null, icon: icon);
      case 'musicVideos':
        return shelf.items.isEmpty 
          ? _buildEmptySliver(context, shelf.title, icon ?? Icons.play_circle_outline_rounded, 'Trending videos will appear here.')
          : _buildVideoRow(context, icon: icon);
      case 'longListening':
        return shelf.items.isEmpty 
          ? _buildEmptySliver(context, shelf.title, icon ?? Icons.timer_outlined, 'Long tracks and sets for your flow.')
          : _buildPlaylistRow(context, 'long tracks & sets', null, icon: icon);
      case 'podcasts':
        return shelf.items.isEmpty 
          ? _buildEmptySliver(context, shelf.title, icon ?? Icons.podcasts_rounded, 'Discover your next favorite podcast.')
          : _buildPlaylistRow(context, 'podcasts for you', null, icon: icon);
      case 'mixedForYou':
        return _buildPlaylistRow(context, 'personalized for you', null, icon: icon ?? Icons.auto_awesome_rounded);
      case 'trending':
        return _buildPlaylistRow(context, null, null, icon: icon ?? Icons.trending_up_rounded);
      case 'trendingArtists':
        return _buildArtistRow(context, 'Popular Artists', null, icon: icon);
      default:
        final itemTypes = shelf.items.map((e) => e.type).toSet();
        if (itemTypes.contains(HomeItemType.artist) && shelf.items.length > 2) {
          return _buildArtistRow(context, null, null, icon: icon);
        }
        if (itemTypes.contains(HomeItemType.album) || itemTypes.contains(HomeItemType.playlist)) {
          return _buildPlaylistRow(context, null, null, icon: icon);
        }
        return _buildStandardRow(context, null, null, icon: icon);
    }
  }

  Widget _buildEmptySliver(BuildContext context, String title, IconData icon, String message) {
    final cs = Theme.of(context).colorScheme;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(title: title, icon: icon)),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: AppRadius.largeBorderRadius,
              border: Border.all(color: cs.outlineVariant.withAlpha(40)),
            ),
            child: Row(
              children: [
                Icon(icon, color: cs.primary.withAlpha(80), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(120),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoRow(BuildContext context, {IconData? icon}) {
    final songs = shelf.items.where((i) => i.type == HomeItemType.song).map((i) => i.data as Song).toList();
    if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(title: shelf.title, icon: icon)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: songs.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SongCard(
                  song: songs[i],
                  queue: allSongs,
                  index: songIndexMap[songs[i].id] ?? 0,
                  cardWidth: 240,
                  aspectRatio: 16 / 9,
                  heroTag: 'video_art_${songs[i].id}_${shelf.title}_$i',
                  startRadio: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListenAgainShelf(BuildContext context, {IconData? icon}) {
    final songs = shelf.items.where((i) => i.type == HomeItemType.song).map((i) => i.data as Song).toList();
    if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(title: shelf.title, profileUrl: profileUrl, profileName: ytName, icon: icon)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: songs.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SongCard(
                  song: songs[i],
                  queue: allSongs,
                  index: songIndexMap[songs[i].id] ?? 0,
                  cardWidth: 220,
                  aspectRatio: 1.6,
                  heroTag: 'listen_again_${songs[i].id}_$i',
                  startRadio: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFreshFindsStaggered(BuildContext context, String? subtitle, String? profileUrl, {IconData? icon}) {
    final items = shelf.items.where((i) => i.type == HomeItemType.song || i.type == HomeItemType.album || i.type == HomeItemType.playlist).take(27).toList();
    if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final List<List<HomeItem>> columns = [];
    for (var i = 0; i < items.length; i += 3) {
      columns.add(items.sublist(i, (i + 3 < items.length) ? i + 3 : items.length));
    }
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(title: shelf.title, subtitle: subtitle, profileUrl: profileUrl, icon: icon)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 400,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: columns.length,
              itemBuilder: (context, colIndex) {
                final columnItems = columns[colIndex];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 150,
                    child: Column(
                      children: List.generate(columnItems.length, (rowIndex) {
                        final item = columnItems[rowIndex];
                        if (item.type == HomeItemType.song) {
                          final song = item.data as Song;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16), 
                            child: _QuickPickStaggeredItem(
                              song: song, 
                              isLarge: rowIndex == 0, 
                              allSongs: allSongs, 
                              index: songIndexMap[song.id] ?? 0,
                              startRadio: true,
                            )
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessRow(BuildContext context, String? subtitle, String? profileUrl, {IconData? icon}) {
    final songs = shelf.items.where((i) => i.type == HomeItemType.song).map((i) => i.data as Song).take(24).toList();
    if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(title: shelf.title, subtitle: subtitle, profileUrl: profileUrl, icon: icon)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: (songs.length / 4).ceil(),
              itemBuilder: (context, colIndex) {
                final columnSongs = songs.skip(colIndex * 4).take(4).toList();
                return Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: SizedBox(
                    width: 300,
                    child: Column(
                      children: columnSongs.map((song) => _QuickPickListTile(
                        song: song, 
                        allSongs: allSongs, 
                        index: songIndexMap[song.id] ?? 0,
                        startRadio: true,
                      )).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtistRow(BuildContext context, String? subtitle, String? profileUrl, {IconData? icon}) {
    final artists = shelf.items.where((i) => i.type == HomeItemType.artist).map((i) => i.data as Map<String, dynamic>).toList();
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(title: shelf.title, subtitle: subtitle, profileUrl: profileUrl, icon: icon)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: artists.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: 14),
                child: ArtistCard(
                  artist: artists[i],
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArtistScreen(artist: artists[i], allSongs: allSongs))),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistRow(BuildContext context, String? subtitle, String? profileUrl, {bool isAlbum = false, IconData? icon}) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(title: shelf.title, subtitle: subtitle, profileUrl: profileUrl, icon: icon)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: shelf.items.length,
              itemBuilder: (context, i) {
                final item = shelf.items[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: item.type == HomeItemType.song 
                    ? SongCard(
                        song: item.data as Song, 
                        queue: allSongs, 
                        index: songIndexMap[(item.data as Song).id] ?? 0,
                        startRadio: true,
                      )
                    : _HomePlaylistCard(playlist: item.data as Playlist, isAlbum: item.type == HomeItemType.album || isAlbum),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStandardRow(BuildContext context, String? subtitle, String? profileUrl, {double cardWidth = 135, IconData? icon}) {
    final songs = shelf.items.where((i) => i.type == HomeItemType.song).map((i) => i.data as Song).toList();
    if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(title: shelf.title, subtitle: subtitle, profileUrl: profileUrl, icon: icon)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: cardWidth + 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: songs.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: 14),
                child: SongCard(
                  song: songs[i], 
                  queue: allSongs, 
                  index: songIndexMap[songs[i].id] ?? 0, 
                  cardWidth: cardWidth,
                  startRadio: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopCharts(BuildContext context, {IconData? icon}) {
    final songs = shelf.items.where((i) => i.type == HomeItemType.song).map((i) => i.data as Song).take(10).toList();
    if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(title: shelf.title, icon: icon)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: (songs.length / 3).ceil(),
              itemBuilder: (context, colIndex) {
                final columnSongs = songs.skip(colIndex * 3).take(3).toList();
                return Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: SizedBox(
                    width: 300,
                    child: Column(
                      children: List.generate(columnSongs.length, (rowIndex) {
                        final song = columnSongs[rowIndex];
                        return _ChartItem(song: song, rank: colIndex * 3 + rowIndex + 1, allSongs: allSongs, index: songIndexMap[song.id] ?? 0);
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedGrid(BuildContext context, {IconData? icon}) {
    final items = shelf.items.take(4).toList();
    if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(title: shelf.title, icon: icon)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 2.5),
              itemCount: items.length,
              itemBuilder: (context, i) {
                if (items[i].type == HomeItemType.song) {
                  final song = items[i].data as Song;
                  return _FeaturedSmallTile(
                    song: song, 
                    allSongs: allSongs, 
                    index: songIndexMap[song.id] ?? 0,
                    startRadio: true,
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
}

class _ChartItem extends StatelessWidget {
  final Song song;
  final int rank;
  final List<Song> allSongs;
  final int index;
  const _ChartItem({required this.song, required this.rank, required this.allSongs, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        context.read<PlayerBloc>().add(PlayRadioEvent(song));
        if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) PlayerScreen.show(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(width: 32, child: Text('$rank', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withAlpha(100)))),
            Container(width: 56, height: 56, decoration: BoxDecoration(borderRadius: AppRadius.mediumBorderRadius, color: theme.colorScheme.surfaceContainerHigh), clipBehavior: Clip.antiAlias, child: song.thumbnailUrl != null ? CachedNetworkImage(imageUrl: song.thumbnailUrl!, fit: BoxFit.fill) : _fallback(song)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(song.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis), Text(song.artist, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(140)), maxLines: 1, overflow: TextOverflow.ellipsis)]))
          ],
        ),
      ),
    );
  }
  Widget _fallback(Song s) => Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [s.colorPrimary, s.colorSecondary])), child: Center(child: Text('f', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white))));
}

class _FeaturedSmallTile extends StatelessWidget {
  final Song song;
  final List<Song> allSongs;
  final int index;
  final bool startRadio;
  const _FeaturedSmallTile({required this.song, required this.allSongs, required this.index, this.startRadio = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        if (startRadio) {
          context.read<PlayerBloc>().add(PlayRadioEvent(song));
        } else {
          context.read<PlayerBloc>().add(PlayQueueEvent(songs: allSongs, startIndex: index));
        }
        if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) PlayerScreen.show(context);
      },
      child: Container(
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh, borderRadius: AppRadius.largeBorderRadius),
        clipBehavior: Clip.antiAlias,
        child: Row(children: [AspectRatio(aspectRatio: 1, child: song.thumbnailUrl != null ? CachedNetworkImage(imageUrl: song.thumbnailUrl!, fit: BoxFit.fill) : Container(color: song.colorPrimary)), const SizedBox(width: 12), Expanded(child: Text(song.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)), const SizedBox(width: 8)]),
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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaylistScreen(playlist: widget.playlist, isAlbum: widget.isAlbum))),
        child: SizedBox(width: 140, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [AspectRatio(aspectRatio: 1, child: AnimatedScale(scale: _isHovered ? 1.04 : 1, duration: const Duration(milliseconds: 200), child: Container(decoration: BoxDecoration(color: widget.playlist.color, borderRadius: AppRadius.mediumBorderRadius), clipBehavior: Clip.antiAlias, child: widget.playlist.thumbnailUrl != null ? CachedNetworkImage(imageUrl: widget.playlist.thumbnailUrl!, fit: BoxFit.fill) : const Center(child: Icon(Icons.queue_music_rounded, color: Colors.white, size: 48))))), const SizedBox(height: 10), Text(widget.playlist.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 1), Text(widget.playlist.description, style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(140)), overflow: TextOverflow.ellipsis, maxLines: 1)])),
      ),
    );
  }
}

class _QuickPickStaggeredItem extends StatefulWidget {
  final Song song;
  final bool isLarge;
  final List<Song> allSongs;
  final int index;
  final bool startRadio;
  const _QuickPickStaggeredItem({required this.song, required this.isLarge, required this.allSongs, required this.index, this.startRadio = false});
  @override
  State<_QuickPickStaggeredItem> createState() => _QuickPickStaggeredItemState();
}

class _QuickPickStaggeredItemState extends State<_QuickPickStaggeredItem> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    final size = widget.isLarge ? 150.0 : 100.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          if (widget.startRadio) {
            context.read<PlayerBloc>().add(PlayRadioEvent(widget.song));
          } else {
            context.read<PlayerBloc>().add(PlayQueueEvent(songs: widget.allSongs, startIndex: widget.index));
          }
          if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) PlayerScreen.show(context);
        },
        child: Container(
          width: 150,
          height: size,
          decoration: BoxDecoration(borderRadius: AppRadius.mediumBorderRadius),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(child: widget.song.thumbnailUrl != null ? CachedNetworkImage(imageUrl: widget.song.thumbnailUrl!, fit: BoxFit.fill) : Container(color: widget.song.colorPrimary)),
              Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withAlpha(200), Colors.transparent])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [TextCarousel(text: widget.song.title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: widget.isLarge ? 13 : 10, color: Colors.white)), Text(widget.song.artist, style: GoogleFonts.outfit(fontSize: widget.isLarge ? 11 : 8, color: Colors.white.withAlpha(180)), maxLines: 1, overflow: TextOverflow.ellipsis)]))),
              if (_isHovered) Positioned.fill(child: Container(color: Colors.black.withAlpha(40), child: const Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38)))),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickPickListTile extends StatelessWidget {
  final Song song;
  final List<Song> allSongs;
  final int index;
  final bool startRadio;
  const _QuickPickListTile({required this.song, required this.allSongs, required this.index, this.startRadio = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        if (startRadio) {
          context.read<PlayerBloc>().add(PlayRadioEvent(song));
        } else {
          context.read<PlayerBloc>().add(PlayQueueEvent(songs: List.from(allSongs), startIndex: index));
        }
        if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) PlayerScreen.show(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(borderRadius: AppRadius.smallBorderRadius, color: theme.colorScheme.surfaceContainerHigh), clipBehavior: Clip.antiAlias, child: song.thumbnailUrl != null ? CachedNetworkImage(imageUrl: song.thumbnailUrl!, fit: BoxFit.fill) : Container(color: song.colorPrimary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(song.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis), Text(song.artist, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(140)), maxLines: 1, overflow: TextOverflow.ellipsis)]))
          ],
        ),
      ),
    );
  }
}
