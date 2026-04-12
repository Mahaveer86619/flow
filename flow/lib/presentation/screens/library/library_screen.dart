import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../../cubits/library/library_cubit.dart';
import '../../widgets/error_view.dart';
import '../playlist/playlist_screen.dart';
import '../settings/settings_screen.dart';

class _LibraryFilterDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Theme.of(
        context,
      ).scaffoldBackgroundColor.withAlpha(overlapsContent ? 255 : 0),
      height: 60,
      child: BlocBuilder<LibraryCubit, LibraryState>(
        buildWhen: (prev, curr) => prev.filterIndex != curr.filterIndex,
        builder: (context, state) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: LibraryState.filterOptions.length,
          itemBuilder: (context, i) {
            final selected = state.filterIndex == i;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(LibraryState.filterOptions[i]),
                selected: selected,
                onSelected: (_) => context.read<LibraryCubit>().setFilter(i),
                backgroundColor: colorScheme.surfaceContainerHigh,
                selectedColor: colorScheme.onSurface,
                labelStyle: TextStyle(
                  color: selected ? colorScheme.surface : colorScheme.onSurface,
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

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns = screenWidth > 1200 ? 5 : (screenWidth > 800 ? 3 : 2);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
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
                MediaQuery.paddingOf(context).top + 8,
                16,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    'Library',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
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
            ),
          ),
        ),

        // Filter Chips
        SliverPersistentHeader(
          pinned: true,
          delegate: _LibraryFilterDelegate(),
        ),

        BlocBuilder<LibraryCubit, LibraryState>(
          builder: (context, state) {
            if (state.isLoading && state.playlists.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state.error && state.playlists.isEmpty) {
              return SliverFillRemaining(
                child: ErrorView(
                  errorType: state.errorType,
                  onRetry: () => context.read<LibraryCubit>().reload(),
                ),
              );
            }

            final playlists = state.playlists;

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate((context, i) {
                  if (i == 0) {
                    return BlocSelector<PlayerBloc, PlayerState, int>(
                      selector: (s) => s.likedSongsCount,
                      builder: (context, likedCount) => _SpecialPlaylistCard(
                        icon: Icons.favorite_rounded,
                        color: const Color(0xFFEC4899),
                        name: 'Liked Songs',
                        subtitle: '$likedCount songs',
                      ),
                    );
                  }
                  return _PlaylistCard(playlist: playlists[i - 1]);
                }, childCount: playlists.length + 1),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _PlaylistCard extends StatefulWidget {
  final Playlist playlist;
  const _PlaylistCard({required this.playlist});

  @override
  State<_PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<_PlaylistCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlaylistScreen(playlist: widget.playlist),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AnimatedScale(
                scale: _isHovered ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
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
                    fit: StackFit.expand,
                    children: [
                      if (widget.playlist.thumbnailUrl != null)
                        Image.network(
                          widget.playlist.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallback(),
                        )
                      else
                        _fallback(),

                      if (_isHovered)
                        Container(
                          color: Colors.black26,
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.playlist.name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.playlist.description.isEmpty
                  ? 'Playlist'
                  : widget.playlist.description,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: colorScheme.onSurface.withAlpha(140),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: widget.playlist.color,
      child: const Center(
        child: Icon(Icons.queue_music_rounded, color: Colors.white, size: 40),
      ),
    );
  }
}

class _SpecialPlaylistCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String name;
  final String subtitle;

  const _SpecialPlaylistCard({
    required this.icon,
    required this.color,
    required this.name,
    required this.subtitle,
  });

  @override
  State<_SpecialPlaylistCard> createState() => _SpecialPlaylistCardState();
}

class _SpecialPlaylistCardState extends State<_SpecialPlaylistCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.name} coming soon!')),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AnimatedScale(
                scale: _isHovered ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [widget.color, widget.color.withAlpha(180)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withAlpha(_isHovered ? 80 : 50),
                        blurRadius: _isHovered ? 20 : 12,
                        offset: Offset(0, _isHovered ? 8 : 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(widget.icon, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Text(
              widget.subtitle,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
