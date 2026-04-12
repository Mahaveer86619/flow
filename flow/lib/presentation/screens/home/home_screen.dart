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

import '../settings/settings_screen.dart';

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
        final cs = Theme.of(context).colorScheme;
        // Pre-compute index map for performance (O(N) once instead of O(N^2) total)
        final Map<String, int> songIndexMap = {
          for (int i = 0; i < state.allSongs.length; i++)
            state.allSongs[i].id: i,
        };

        return RefreshIndicator(
          onRefresh: () => context.read<HomeCubit>().refresh(),
          backgroundColor: cs.surfaceContainerHigh,
          color: cs.primary,
          displacement: 100,
          child: CustomScrollView(
            cacheExtent: 2000,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── Custom immersive AppBar (Always Visible) ─────────────────────────
              SliverAppBar(
                expandedHeight: 100,
                floating: true,
                pinned: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
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
                            Text(
                              'Flow',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.2,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.history_rounded),
                              onPressed: () {},
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              state.greeting,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withAlpha(140),
                              ),
                            ),
                            if (state.isLoading && state.shelves.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white24,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Filter Chips ───────────────────────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterChipsDelegate(),
              ),

              // ── Body Logic (Error / Loading / Content) ──────────────────────────
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
                // Dynamic Shelves
                ...state.shelves.map(
                  (shelf) => _HomeShelfRenderer(
                    shelf: shelf,
                    allSongs: state.allSongs,
                    songIndexMap: songIndexMap,
                    profileUrl: state.profileUrl,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FilterChipsDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final tags = ['All', 'Relax', 'Sleep', 'Energize', 'Sadhana', 'Focus'];

    return Container(
      color: Theme.of(
        context,
      ).scaffoldBackgroundColor.withAlpha(overlapsContent ? 255 : 0),
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: tags.length,
        itemBuilder: (context, i) {
          final isFirst = i == 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tags[i]),
              selected: isFirst,
              onSelected: (_) {},
              backgroundColor: colorScheme.surfaceContainerHigh,
              selectedColor: colorScheme.onSurface,
              labelStyle: TextStyle(
                color: isFirst ? colorScheme.surface : colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide.none,
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  @override
  double get maxExtent => 60;
  @override
  double get minExtent => 60;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _HomeShelfRenderer extends StatelessWidget {
  final HomeShelf shelf;
  final List<Song> allSongs;
  final Map<String, int> songIndexMap;
  final String? profileUrl;

  const _HomeShelfRenderer({
    required this.shelf,
    required this.allSongs,
    required this.songIndexMap,
    this.profileUrl,
  });

  @override
  Widget build(BuildContext context) {
    final title = shelf.title.toLowerCase();
    String? shelfSubtitle;
    String? shelfProfileUrl;

    if (title.contains('listen again')) {
      shelfSubtitle = 'MAHAVEER PANIGRAHI'; // Placeholder name as per ref image
      shelfProfileUrl = profileUrl; // Use dynamic profile URL
    }

    // Determine layout based on title or content
    if (title.contains('quick pick') || title.contains('top pick')) {
      return _buildQuickAccessGrid(context, shelfSubtitle, shelfProfileUrl);
    }

    final itemTypes = shelf.items.map((e) => e.type).toSet();

    if (itemTypes.contains(HomeItemType.artist) && shelf.items.length > 2) {
      return _buildArtistRow(context, shelfSubtitle, shelfProfileUrl);
    }

    if (itemTypes.contains(HomeItemType.album) ||
        itemTypes.contains(HomeItemType.playlist)) {
      return _buildPlaylistRow(context, shelfSubtitle, shelfProfileUrl);
    }

    return _buildStandardRow(context, shelfSubtitle, shelfProfileUrl);
  }

  Widget _buildQuickAccessGrid(
    BuildContext context,
    String? subtitle,
    String? profileUrl,
  ) {
    final songs = shelf.items
        .where((i) => i.type == HomeItemType.song)
        .map((i) => i.data as Song)
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
          child: SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: songs.length,
              itemBuilder: (context, i) => _QuickAccessLargeCard(
                song: songs[i],
                allSongs: allSongs,
                songIndexMap: songIndexMap,
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
                    builder: (_) =>
                        ArtistScreen(artist: artists[i], allSongs: allSongs),
                  ),
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
    String? profileUrl,
  ) {
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
                  final song = item.data as Song;
                  return SongCard(
                    song: song,
                    queue: allSongs,
                    index: songIndexMap[song.id] ?? 0,
                  );
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

  Widget _buildStandardRow(
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
                index: songIndexMap[songs[i].id] ?? 0,
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
          MaterialPageRoute(
            builder: (_) => PlaylistScreen(playlist: widget.playlist),
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
                  scale: _isHovered ? 1.04 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
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
                              cacheWidth: 300,
                              cacheHeight: 300,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.queue_music_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          )
                        else
                          const Center(
                            child: Icon(
                              Icons.queue_music_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),

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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: _SkeletonBox(width: 200, height: 32, radius: 8),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (_, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 240, height: 135, radius: 16),
                    const SizedBox(height: 12),
                    _SkeletonBox(width: 180, height: 16, radius: 4),
                    const SizedBox(height: 6),
                    _SkeletonBox(width: 120, height: 12, radius: 4),
                  ],
                ),
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

class _QuickAccessLargeCard extends StatefulWidget {
  final Song song;
  final List<Song> allSongs;
  final Map<String, int> songIndexMap;
  const _QuickAccessLargeCard({
    required this.song,
    required this.allSongs,
    required this.songIndexMap,
  });

  @override
  State<_QuickAccessLargeCard> createState() => _QuickAccessLargeCardState();
}

class _QuickAccessLargeCardState extends State<_QuickAccessLargeCard> {
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
              startIndex: widget.songIndexMap[widget.song.id] ?? 0,
            ),
          );
          if (!isDesktop) {
            PlayerScreen.show(context);
          }
        },
        child: Container(
          width: 240,
          margin: const EdgeInsets.only(right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Hero(
                  tag: 'art_${widget.song.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: widget.song.thumbnailUrl != null
                        ? Image.network(
                            widget.song.thumbnailUrl!,
                            fit: BoxFit.cover,
                            cacheWidth: 800,
                            cacheHeight: 450,
                            errorBuilder: (context, error, stackTrace) =>
                                _fallback(),
                          )
                        : _fallback(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.song.title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.song.artist,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: colorScheme.onSurface.withAlpha(140),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.song.colorPrimary, widget.song.colorSecondary],
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Colors.white, size: 40),
      ),
    );
  }
}
