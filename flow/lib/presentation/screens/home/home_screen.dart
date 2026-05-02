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
import '../../widgets/flow_app_bar.dart';
import '../../widgets/shimmer_shelf.dart';

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
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
            
            // ── Greeting & Mood Chips (Fixed Section) ──────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: _buildFixedHeader(),
              ),
            ),

            // ── Feed Content ───────────────────────────────────────────
            BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                if (state.status == HomeStatus.loading && state.shelves.isEmpty) {
                  return _buildShimmerLoading();
                }

                if (state.status == HomeStatus.failure && state.shelves.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildErrorState(state.error ?? 'Failed to load feed', padding),
                  );
                }

                // Sort shelves to prioritize quick_picks if present
                final sortedShelves = List<HomeShelf>.from(state.shelves);
                final qpIndex = sortedShelves.indexWhere((s) => s.section == 'quick_picks');
                if (qpIndex > 0) {
                  final qp = sortedShelves.removeAt(qpIndex);
                  sortedShelves.insert(0, qp);
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final shelf = sortedShelves[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildShelf(shelf),
                      );
                    },
                    childCount: sortedShelves.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 150)),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedHeader() {
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) greeting = 'Good Afternoon';
    if (hour >= 17 || hour < 5) greeting = 'Good Evening';

    return Row(
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
    );
  }

  Widget _buildShimmerLoading() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const SectionHeader(title: 'Quick Picks'),
          const ShimmerShelf(isGrid: true),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Recommended'),
          const ShimmerShelf(),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Listen Again'),
          const ShimmerShelf(),
        ]),
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
}}

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
