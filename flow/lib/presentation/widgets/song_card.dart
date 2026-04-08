// ─────────────────────────────────────────────────────────────────────────────
// SongCard — portrait song tile used in horizontal scrolling lists.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/responsive/breakpoints.dart';
import '../../domain/entities/song.dart';
import '../blocs/player/player_bloc.dart';
import '../screens/player/player_screen.dart';

class SongCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Artwork(song: song, size: cardWidth),
            const SizedBox(height: 8),
            Text(
              song.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withAlpha(140),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    context.read<PlayerBloc>().add(
          PlayQueueEvent(songs: List<Song>.from(queue), startIndex: index),
        );
    if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
    }
  }
}

class _Artwork extends StatelessWidget {
  final Song song;
  final double size;
  const _Artwork({required this.song, required this.size});

  @override
  Widget build(BuildContext context) {
    if (song.thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          song.thumbnailUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [song.colorPrimary, song.colorSecondary],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.33,
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
          Container(
            width: cardWidth,
            height: cardWidth,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
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
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
        ),
      ],
    );
  }
}
