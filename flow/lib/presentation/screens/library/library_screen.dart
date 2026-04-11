import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../../cubits/library/library_cubit.dart';
import '../../widgets/error_view.dart';
import '../playlist/playlist_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmall = Breakpoints.isMobile(screenWidth);
    final columns = screenWidth > 1200 ? 5 : (screenWidth > 800 ? 3 : 2);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              children: [
                Text(
                  'Your Library',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: isSmall ? 28.0 : 32.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Create playlist coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Filter Chips
        SliverToBoxAdapter(
          child: BlocBuilder<LibraryCubit, LibraryState>(
            buildWhen: (prev, curr) => prev.filterIndex != curr.filterIndex,
            builder: (context, state) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                children: List.generate(LibraryState.filterOptions.length, (i) {
                  final selected = state.filterIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(LibraryState.filterOptions[i]),
                      selected: selected,
                      onSelected: (_) =>
                          context.read<LibraryCubit>().setFilter(i),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: selected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      selectedColor: colorScheme.primary,
                      checkmarkColor: colorScheme.onPrimary,
                      backgroundColor: colorScheme.surfaceContainerHigh,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),

        BlocBuilder<LibraryCubit, LibraryState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            if (state.error) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: ErrorView(
                    errorType: state.errorType,
                    onRetry: () => context.read<LibraryCubit>().reload(),
                  ),
                ),
              );
            }

            final playlists = state.playlists;

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
