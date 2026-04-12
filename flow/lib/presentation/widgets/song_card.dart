// ─────────────────────────────────────────────────────────────────────────────
// SongCard — portrait song tile used in horizontal scrolling lists.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/responsive/breakpoints.dart';
import '../../domain/entities/song.dart';
import '../blocs/player/player_bloc.dart';
import '../screens/player/player_screen.dart';

class SongCard extends StatefulWidget {
  final Song song;
  final List<Song> queue;
  final int index;
  final double cardWidth;

  const SongCard({
    super.key,
    required this.song,
    required this.queue,
    required this.index,
    this.cardWidth = 135,
  });

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
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
        onTap: () => _handleTap(context),
        child: SizedBox(
          width: widget.cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.04 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _Artwork(
                    song: widget.song,
                    size: widget.cardWidth,
                    isHovered: _isHovered,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.song.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                widget.song.artist,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withAlpha(140),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    context.read<PlayerBloc>().add(
      PlayQueueEvent(
        songs: List<Song>.from(widget.queue),
        startIndex: widget.index,
      ),
    );
    if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
      PlayerScreen.show(context);
    }
  }
}

class _Artwork extends StatelessWidget {
  final Song song;
  final double size;
  final bool isHovered;

  const _Artwork({
    required this.song,
    required this.size,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isHovered ? 60 : 40),
                blurRadius: isHovered ? 20 : 12,
                offset: Offset(0, isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Hero(
            tag: 'art_${song.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: song.thumbnailUrl != null
                  ? Image.network(
                      song.thumbnailUrl!,
                      width: size,
                      height: size * 9 / 16,
                      fit: BoxFit.cover,
                      cacheWidth: 640,
                      cacheHeight: 360,
                      errorBuilder: (context, error, stackTrace) => _fallback(),
                    )
                  : _fallback(),
            ),
          ),
        ),
        if (isHovered)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
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
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size * 9 / 16,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [song.colorPrimary, song.colorSecondary],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.25,
        color: Colors.white.withAlpha(45),
      ),
    );
  }
}

// ── Skeleton variants used by HomeScreen shimmer ──────────────────────────────

class SkeletonSongCard extends StatelessWidget {
  final double cardWidth;
  const SkeletonSongCard({super.key, this.cardWidth = 135});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    return SizedBox(
      width: cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              width: cardWidth,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: cardWidth * 0.8,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: cardWidth * 0.55,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonQuickAccessTile extends StatelessWidget {
  const SkeletonQuickAccessTile({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class SkeletonArtistCard extends StatelessWidget {
  const SkeletonArtistCard({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(height: 6),
        Container(
          width: 70,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }
}
