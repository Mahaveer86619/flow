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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
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

        return Scaffold(
          backgroundColor: Colors.black,
          body: RefreshIndicator(
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
                  expandedHeight: 140,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.black.withAlpha(200),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: false,
                  title: Text(
                    'Flow',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.history_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecentlyPlayedScreen(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black, Colors.black.withAlpha(0)],
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              MediaQuery.paddingOf(context).top + 50,
                              16,
                              0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  greeting,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 38,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      _MoodChip(
                                        label: 'Chill',
                                        icon: Icons.nightlight_round,
                                        color: Colors.blueAccent,
                                      ),
                                      _MoodChip(
                                        label: 'Energetic',
                                        icon: Icons.bolt_rounded,
                                        color: Colors.orangeAccent,
                                      ),
                                      _MoodChip(
                                        label: 'Focus',
                                        icon: Icons.center_focus_strong_rounded,
                                        color: Colors.greenAccent,
                                      ),
                                      _MoodChip(
                                        label: 'Workout',
                                        icon: Icons.fitness_center_rounded,
                                        color: Colors.redAccent,
                                      ),
                                    ],
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                if (state.isLoading && state.shelves.isEmpty)
                  const SliverFillRemaining(
                    child: PersonalityBotView(isLoading: true),
                  )
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
                    final List<HomeShelf> displayShelves = List.from(
                      state.shelves,
                    );
                    final requestedSections = [
                      (
                        'Daily Rotation',
                        'listeningAgain',
                        Icons.replay_rounded,
                      ),
                      (
                        'Listen Again',
                        'quickPicks',
                        Icons.grid_view_rounded,
                      ), // This will be our 4-row grid
                      (
                        'Music Videos',
                        'musicVideos',
                        Icons.play_circle_filled_rounded,
                      ),
                      ('Albums', 'albumsForYou', Icons.album_rounded),
                      ('Deep Dives', 'longListening', Icons.timer_rounded),
                      ('Podcasts', 'podcasts', Icons.podcasts_rounded),
                    ];

                    final List<HomeShelf> orderedShelves = [];
                    for (final req in requestedSections) {
                      final shelf = displayShelves.firstWhere(
                        (s) => s.section == req.$2,
                        orElse: () => HomeShelf(
                          title: req.$1,
                          section: req.$2,
                          items: const [],
                        ),
                      );
                      orderedShelves.add(shelf);
                    }

                    return orderedShelves.map((shelf) {
                      final req = requestedSections.firstWhere(
                        (r) => r.$2 == shelf.section,
                      );

                      return SliverPadding(
                        padding: const EdgeInsets.only(bottom: 12),
                        sliver: _HomeShelfRenderer(
                          shelf: shelf,
                          allSongs: state.allSongs,
                          songIndexMap: songIndexMap,
                          profileUrl: state.profileUrl,
                          ytName: state.ytName,
                          icon: req.$3,
                        ),
                      );
                    });
                  }(),
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              ],
            ),
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
      case 'listeningAgain': // Daily Rotation
        return _buildDailyRotation(context, icon: icon);
      case 'quickPicks': // Listen Again (4-row grid)
        return _buildListenAgainGrid(context, icon: icon);
      case 'musicVideos':
        return _buildVideoRow(context, icon: icon);
      case 'albumsForYou':
        return _buildPlaylistRow(
          context,
          'Expand your collection',
          null,
          isAlbum: true,
          icon: icon,
        );
      case 'longListening':
        return _buildPlaylistRow(context, 'Extended tracks', null, icon: icon);
      case 'podcasts':
        return _buildPlaylistRow(
          context,
          'Stories and conversations',
          null,
          icon: icon,
        );
      default:
        return _buildStandardRow(context, null, null, icon: icon);
    }
  }

  Widget _buildDailyRotation(BuildContext context, {IconData? icon}) {
    final songs = shelf.items
        .where((i) => i.type == HomeItemType.song)
        .map((i) => i.data as Song)
        .toList();
    if (songs.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeader(title: shelf.title, icon: icon),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
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
                  aspectRatio: 1.0,
                  heroTag: 'daily_${songs[i].id}_$i',
                  startRadio: true,
                  skipPlayerScreen: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListenAgainGrid(BuildContext context, {IconData? icon}) {
    if (shelf.items.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeader(title: shelf.title, icon: icon),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: (shelf.items.length / 4).ceil(),
              itemBuilder: (context, colIndex) {
                final columnItems = shelf.items
                    .skip(colIndex * 4)
                    .take(4)
                    .toList();
                return Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: SizedBox(
                    width: 300,
                    child: Column(
                      children: columnItems.map((item) {
                        if (item.type == HomeItemType.song) {
                          return _QuickPickListTile(
                            song: item.data as Song,
                            allSongs: allSongs,
                            index: songIndexMap[(item.data as Song).id] ?? 0,
                            startRadio: true,
                          );
                        }
                        return const SizedBox.shrink();
                      }).toList(),
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

  Widget _buildVideoRow(BuildContext context, {IconData? icon}) {
    final songs = shelf.items
        .where((i) => i.type == HomeItemType.song)
        .map((i) => i.data as Song)
        .toList();
    if (songs.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeader(title: shelf.title, icon: icon),
        ),
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
                  aspectRatio: 16 / 9,
                  heroTag: 'video_${songs[i].id}_$i',
                  startRadio: true,
                  skipPlayerScreen: true,
                ),
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
    IconData? icon,
  }) {
    final items = shelf.items;
    if (items.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeader(
            title: shelf.title,
            subtitle: subtitle,
            icon: icon,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: item.type == HomeItemType.song
                      ? SongCard(
                          song: item.data as Song,
                          queue: allSongs,
                          index: songIndexMap[(item.data as Song).id] ?? 0,
                          startRadio: true,
                          skipPlayerScreen: true,
                        )
                      : _HomePlaylistCard(
                          playlist: item.data as Playlist,
                          isAlbum: item.type == HomeItemType.album || isAlbum,
                        ),
                );
              },
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
    double cardWidth = 140,
    IconData? icon,
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
            icon: icon,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: cardWidth + 70,
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
                  skipPlayerScreen: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickPickListTile extends StatelessWidget {
  final Song song;
  final List<Song> allSongs;
  final int index;
  final bool startRadio;
  const _QuickPickListTile({
    required this.song,
    required this.allSongs,
    required this.index,
    this.startRadio = false,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        if (startRadio) {
          context.read<PlayerBloc>().add(PlayRadioEvent(song));
        } else {
          context.read<PlayerBloc>().add(
            PlayQueueEvent(songs: List.from(allSongs), startIndex: index),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: AppRadius.smallBorderRadius,
                color: theme.colorScheme.surfaceContainerHigh,
              ),
              clipBehavior: Clip.antiAlias,
              child: song.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: song.thumbnailUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(color: song.colorPrimary),
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
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withAlpha(140),
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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
                aspectRatio: 1,
                child: AnimatedScale(
                  scale: _isHovered ? 1.04 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.playlist.color,
                      borderRadius: AppRadius.mediumBorderRadius,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: widget.playlist.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.playlist.thumbnailUrl!,
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Icon(
                              Icons.queue_music_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
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
                  color: Colors.white.withAlpha(140),
                ),
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

class _MoodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _MoodChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.read<PlayerBloc>().add(FilterByMoodEvent(label));
          },

          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(80), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withAlpha(220),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

