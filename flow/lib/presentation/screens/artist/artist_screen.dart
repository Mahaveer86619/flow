import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/repositories/music_repository.dart';
import '../../blocs/player/player_bloc.dart';
import '../../widgets/song_tile.dart';
import '../../widgets/skeleton.dart';
import '../player/player_screen.dart';

class ArtistScreen extends StatefulWidget {
  final Map<String, dynamic> artist;
  final List<Song> allSongs;

  const ArtistScreen({super.key, required this.artist, required this.allSongs});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  List<Song> _artistSongs = [];
  bool _isLoading = true;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _loadArtistSongs();
  }

  Future<void> _loadArtistSongs() async {
    try {
      final repo = context.read<MusicRepository>();
      final channelId = widget.artist['browseId'] as String?;
      if (channelId != null) {
        final songs = await repo.getArtistSongs(channelId);
        if (mounted) {
          setState(() {
            _artistSongs = songs;
            _isLoading = false;
          });
        }
      } else {
        // Fallback to filtering local songs if no browseId
        final name = widget.artist['name'] as String;
        if (mounted) {
          setState(() {
            _artistSongs = widget.allSongs.where((s) => s.artist == name).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleLike() {
    final channelId = widget.artist['browseId'] as String?;
    if (channelId == null) return;

    final repo = context.read<MusicRepository>();
    if (_isLiked) {
      repo.unlikeArtist(channelId);
    } else {
      repo.likeArtist(channelId);
    }
    setState(() => _isLiked = !_isLiked);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLiked ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _playAll() {
    if (_artistSongs.isEmpty) return;
    context.read<PlayerBloc>().add(
      PlayQueueEvent(songs: _artistSongs, startIndex: 0),
    );
    if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
      PlayerScreen.show(context);
    }
  }

  void _startRadio() {
    if (_artistSongs.isEmpty) return;
    context.read<PlayerBloc>().add(
      PlayRadioEvent(_artistSongs.first),
    );
    if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
      PlayerScreen.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = widget.artist['name'] as String;
    final primary = widget.artist['colorPrimary'] is Color 
        ? widget.artist['colorPrimary'] as Color 
        : Color(widget.artist['colorPrimary'] as int);
    final secondary = widget.artist['colorSecondary'] is Color 
        ? widget.artist['colorSecondary'] as Color 
        : Color(widget.artist['colorSecondary'] as int);
    final thumbnailUrl = widget.artist['thumbnailUrl'] as String?;
    final isSmall = Breakpoints.isMobile(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackHelper.expand,
                children: [
                  // Gradient Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary.withAlpha(150), colorScheme.surface],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Centered Circle Image
                  Center(
                    child: Hero(
                      tag: 'artist_art_${widget.artist['name']}',
                      child: ClipOval(
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary, secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: thumbnailUrl != null
                              ? Image.network(
                                  thumbnailUrl,
                                  fit: BoxFit.fill,
                                  errorBuilder: (_, __, ___) => _artistFallback(name, false),
                                )
                              : _artistFallback(name, false),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'Artist',
                  style: TextStyle(
                    color: colorScheme.onSurface.withAlpha(140),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionButton(
                        icon: Icons.play_arrow_rounded,
                        label: 'Play',
                        onTap: _playAll,
                        isPrimary: true,
                      ),
                      const SizedBox(width: 12),
                      _ActionButton(
                        icon: Icons.rss_feed_rounded,
                        label: 'Radio',
                        onTap: _startRadio,
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: _toggleLike,
                        icon: Icon(
                          _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _isLiked ? Colors.red : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Skeleton(height: 60),
                ),
                childCount: 5,
              ),
            )
          else if (_artistSongs.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No songs found')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final song = _artistSongs[i];
                    return SongTile(
                      song: song,
                      queue: _artistSongs,
                      index: i,
                    );
                  },
                  childCount: _artistSongs.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _artistFallback(String name, bool isSmall) {
    return Center(
      child: Text(
        name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: isSmall ? 44.0 : 64.0,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: isPrimary ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isPrimary ? theme.colorScheme.onPrimary : null,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isPrimary ? theme.colorScheme.onPrimary : null,
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

// Helper because I used StackHelper.expand which might not exist in the project constants
// but Stack usually has fit: StackFit.expand
class StackHelper {
  static const expand = StackFit.expand;
}
