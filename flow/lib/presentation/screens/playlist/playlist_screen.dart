import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/repositories/song_repository.dart';
import '../../blocs/player/player_bloc.dart';
import '../../widgets/song_tile.dart';
import '../player/player_screen.dart';

class PlaylistScreen extends StatefulWidget {
  final Playlist playlist;
  final bool isAlbum;
  const PlaylistScreen({super.key, required this.playlist, this.isAlbum = false});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late Playlist _playlist;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
    if (_playlist.songs.isEmpty) {
      _fetchTracks();
    }
  }

  Future<void> _fetchTracks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<SongRepository>();
      final List<Song> tracks;
      if (widget.isAlbum) {
        tracks = await repo.getAlbumTracks(_playlist.id);
      } else {
        tracks = await repo.getPlaylistTracks(_playlist.id);
      }

      if (mounted) {
        setState(() {
          _playlist = Playlist(
            id: _playlist.id,
            name: _playlist.name,
            description: _playlist.description,
            color: _playlist.color,
            thumbnailUrl: _playlist.thumbnailUrl,
            songs: tracks,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

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
            backgroundColor: _playlist.color,
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
                        colors: [_playlist.color, colorScheme.surface],
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
                          tag: 'playlist_${_playlist.id}',
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
                            child: _playlist.thumbnailUrl != null
                                ? Image.network(
                                    _playlist.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _fallback(),
                                  )
                                : _fallback(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _playlist.name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: isSmall ? 24.0 : 32.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (_playlist.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 8,
                            ),
                            child: Text(
                              _playlist.description,
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
                      if (_playlist.songs.isNotEmpty) {
                        context.read<PlayerBloc>().add(
                          PlayQueueEvent(songs: _playlist.songs, startIndex: 0),
                        );
                        if (!isDesktop) {
                          PlayerScreen.show(context);
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
                    '${_playlist.songs.length} tracks',
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
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $_error'),
                    TextButton(onPressed: _fetchTracks, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else _playlist.songs.isEmpty
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
                      final song = _playlist.songs[i];
                      return SongTile(
                        song: song,
                        queue: _playlist.songs,
                        index: i,
                      );
                    }, childCount: _playlist.songs.length),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: _playlist.color,
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
