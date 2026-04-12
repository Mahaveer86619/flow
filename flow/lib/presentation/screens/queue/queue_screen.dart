import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  /// Opens the [QueueScreen] as a draggable modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      enableDrag: false,
      builder: (context) => const QueueScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerBloc>().state;
    final colorScheme = Theme.of(context).colorScheme;
    final nextSongs = state.queue.skip(state.queueIndex + 1).toList();

    final currentSong = state.currentSong;

    if (currentSong == null) return const SizedBox.shrink();

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        if (notification.extent <= 0.0) {
          Navigator.pop(context);
        }
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.0,
        maxChildSize: 1.0,
        snap: true,
        snapSizes: const [0.0, 1.0],
        builder: (context, scrollController) {
          return SafeArea(
            bottom: false,
            child: Scaffold(
              backgroundColor: const Color(0xFF0A0A14), // Solid background
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      currentSong.colorPrimary.withAlpha(40),
                      const Color(0xFF0A0A14),
                    ],
                  ),
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    // ── Dynamic Top Padding ────────────────────────────────────
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.paddingOf(context).top + 32,
                      ),
                    ),
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      pinned: true,
                      title: Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.paddingOf(context).top,
                        ),
                        child: Text(
                          'Queue',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      centerTitle: true,
                      leading: Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.paddingOf(context).top,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 32,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),

                    // Now Playing Header
                    _SectionHeader(
                      title: 'Now Playing',
                      color: colorScheme.primary,
                    ),

                    // Now Playing Item
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _QueueSongTile(
                          song: currentSong,
                          isPlaying: true,
                          isNowPlaying: true,
                        ),
                      ),
                    ),

                    if (nextSongs.isNotEmpty) ...[
                      // Next Up Header
                      _SectionHeader(
                        title: 'Next In Queue',
                        color: colorScheme.onSurface,
                      ),

                      // Queue List
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final song = nextSongs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: _QueueSongTile(
                              song: song,
                              isPlaying: false,
                              onTap: () {
                                context.read<PlayerBloc>().add(
                                  PlayQueueEvent(
                                    songs: state.queue,
                                    startIndex: state.queueIndex + 1 + index,
                                  ),
                                );
                              },
                            ),
                          );
                        }, childCount: nextSongs.length),
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 16, 12),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color.withAlpha(180),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _QueueSongTile extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final bool isNowPlaying;
  final VoidCallback? onTap;

  const _QueueSongTile({
    required this.song,
    this.isPlaying = false,
    this.isNowPlaying = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isNowPlaying
              ? colorScheme.primaryContainer.withAlpha(80)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Artwork
            _Artwork(song: song, isPlaying: isPlaying),
            const SizedBox(width: 16),

            // Title & Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isNowPlaying
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
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

            // Reorder Handle / More
            if (!isNowPlaying)
              ReorderableDragStartListener(
                index: 0, // Placeholder
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: colorScheme.onSurface.withAlpha(80),
                  size: 20,
                ),
              )
            else
              const Icon(
                Icons.graphic_eq_rounded,
                color: Colors.white70,
                size: 20,
              ),

            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () {
                _showOptions(context);
              },
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Add to Playlist'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share Song'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Remove from Queue',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  const _Artwork({required this.song, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (isPlaying)
            BoxShadow(
              color: song.colorPrimary.withAlpha(100),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (song.thumbnailUrl != null)
            Image.network(
              song.thumbnailUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          else
            _fallback(),

          if (isPlaying)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
        ],
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
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
