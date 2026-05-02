import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/ui/app_radius.dart';
import '../../../core/app_event_bus.dart';
import '../../cubits/home/home_cubit.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/song_card.dart';
import '../../widgets/song_tile.dart';
import '../playlist/playlist_screen.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/home_data.dart';
import '../../blocs/player/player_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<HomeCubit>().init();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final offset = _scrollController.offset;
    final opacity = (offset / 100).clamp(0.0, 1.0);
    if (opacity != _appBarOpacity) {
      setState(() => _appBarOpacity = opacity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Scrollable Content ───────────────────────────────────────────
          RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().refresh(),
            displacement: 100 + padding.top,
            color: cs.primary,
            backgroundColor: cs.surfaceContainerHigh,
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                if (state.status == HomeStatus.loading && state.shelves.isEmpty) {
                  return _buildLoadingState(padding);
                }

                if (state.status == HomeStatus.failure && state.shelves.isEmpty) {
                  return _buildErrorState(state.error ?? 'Failed to load feed', padding);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(16, padding.top + 20, 16, 150),
                  itemCount: state.shelves.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildHeader();
                    final shelf = state.shelves[index - 1];
                    return _buildShelf(shelf);
                  },
                );
              },
            ),
          ),

          // ── Floating App Bar ────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 15 * _appBarOpacity,
                  sigmaY: 15 * _appBarOpacity,
                ),
                child: Container(
                  height: 60 + padding.top,
                  padding: EdgeInsets.only(top: padding.top, left: 16, right: 16),
                  color: Colors.black.withValues(alpha: 0.7 * _appBarOpacity),
                  child: Row(
                    children: [
                      Text(
                        'flow',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.search_rounded, color: Colors.white),
                        onPressed: () {
                          AppEventBus.instance.fire(const SwitchTabEvent(1));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) greeting = 'Good Afternoon';
    if (hour >= 17 || hour < 5) greeting = 'Good Evening';

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Row(
            children: [
              Expanded(
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
                        children: const [
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
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withAlpha(20),
                child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShelf(HomeShelf shelf) {
    if (shelf.items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: shelf.title,
        ),
        const SizedBox(height: 12),
        if (shelf.section == 'quick_picks')
          _QuickPicksGrid(items: shelf.items)
        else
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: shelf.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final item = shelf.items[index];
                if (item.type == HomeItemType.song) {
                  return SongCard(
                    song: item.data as Song,
                    queue: shelf.items
                        .where((i) => i.type == HomeItemType.song)
                        .map((i) => i.data as Song)
                        .toList(),
                    index: shelf.items
                        .where((i) => i.type == HomeItemType.song)
                        .toList()
                        .indexOf(item),
                  );
                } else if (item.type == HomeItemType.playlist || item.type == HomeItemType.album) {
                  return _HomePlaylistCard(
                    playlist: item.data as Playlist,
                    isAlbum: item.type == HomeItemType.album,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLoadingState(EdgeInsets padding) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, padding.top + 20, 16, 100),
      children: [
        const SizedBox(height: 60),
        const Skeleton(height: 30, width: 200),
        const SizedBox(height: 40),
        const Skeleton(height: 24, width: 150),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, __) => const Skeleton(height: 200, width: 150),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message, EdgeInsets padding) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<HomeCubit>().refresh(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPicksGrid extends StatelessWidget {
  final List<HomeItem> items;
  const _QuickPicksGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final songs = items.where((i) => i.type == HomeItemType.song).map((i) => i.data as Song).toList();
    return SizedBox(
      height: 180,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisExtent: 300,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return SongTile(
            song: song,
            queue: songs,
            index: index,
            onTap: () {
              context.read<PlayerBloc>().add(PlayQueueEvent(songs: songs, startIndex: index));
            },
          );
        },
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
                      borderRadius: BorderRadius.circular(12),
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
