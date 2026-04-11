import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../player/player_screen.dart';

class PlaylistScreen extends StatelessWidget {
  final Playlist playlist;
  const PlaylistScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = Breakpoints.isDesktop(screenWidth);
    final isSmall = Breakpoints.isMobile(screenWidth);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: isSmall ? 300 : 350,
            pinned: true,
            stretch: true,
            backgroundColor: playlist.color,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [playlist.color, colorScheme.surface],
                      ),
                    ),
                  ),

                  // Artwork & Info
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'playlist_${playlist.id}',
                          child: Container(
                            width: isSmall ? 160.0 : 200.0,
                            height: isSmall ? 160.0 : 200.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(60),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: playlist.thumbnailUrl != null
                                ? Image.network(
                                    playlist.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _fallback(),
                                  )
                                : _fallback(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          playlist.name,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: isSmall ? 24.0 : 32.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (playlist.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 8,
                            ),
                            child: Text(
                              playlist.description,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.white.withAlpha(180),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          // Action Bar (Play All, Shuffle)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      if (playlist.songs.isNotEmpty) {
                        context.read<PlayerBloc>().add(
                          PlayQueueEvent(songs: playlist.songs, startIndex: 0),
                        );
                        if (!isDesktop) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PlayerScreen(),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play All'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: () {},
                    icon: const Icon(Icons.shuffle_rounded),
                  ),
                  const SizedBox(width: 12),
                  _EndlessRadioToggle(),
                  const Spacer(),
                  Text(
                    '${playlist.songs.length} tracks',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Songs List
          playlist.songs.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Text(
                        'No songs in this playlist',
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final song = playlist.songs[i];
                      return _SongTile(
                        song: song,
                        onTap: () {
                          context.read<PlayerBloc>().add(
                            PlayQueueEvent(
                              songs: playlist.songs,
                              startIndex: i,
                            ),
                          );
                          if (!isDesktop) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PlayerScreen(),
                              ),
                            );
                          }
                        },
                      );
                    }, childCount: playlist.songs.length),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: playlist.color,
      child: const Center(
        child: Icon(Icons.queue_music_rounded, color: Colors.white, size: 80),
      ),
    );
  }
}

class _EndlessRadioToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerBloc>().state;
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton.filledTonal(
      onPressed: () =>
          context.read<PlayerBloc>().add(const ToggleEndlessRadioEvent()),
      icon: Icon(
        Icons.wifi_tethering_rounded,
        color: state.isEndlessRadio
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
      ),
      tooltip: 'Endless Radio',
    );
  }
}

class _SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const _SongTile({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: song.thumbnailUrl != null
            ? Image.network(
                song.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
      title: Text(
        song.title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: colorScheme.onSurface.withAlpha(140),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert_rounded),
        onPressed: () {
          _showSongOptions(context);
        },
        iconSize: 20,
      ),
    );
  }

  void _showSongOptions(BuildContext context) {
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
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.favorite_border_rounded),
              title: const Text('Add to Favorites'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Add to another Playlist'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share Song'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 24),
          ],
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
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
