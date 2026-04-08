// ─────────────────────────────────────────────────────────────────────────────
// SongCard — portrait song tile used in horizontal scrolling lists.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/responsive/breakpoints.dart';
import '../../domain/entities/song.dart';
import '../blocs/player/player_bloc.dart';
import '../screens/player/player_screen.dart';

/// A portrait-orientation card showing artwork, title, and artist.
///
/// Tapping starts playback from [index] within [queue].
/// On mobile/tablet the full-screen [PlayerScreen] is also pushed as a route.
/// On desktop playback starts silently — the persistent player sidebar updates.
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
            Container(
              width: cardWidth,
              height: cardWidth,
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
                size: cardWidth * 0.33,
                color: Colors.white.withAlpha(45),
              ),
            ),
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
      PlayQueueEvent(
        songs: List<Song>.from(queue),
        startIndex: index,
      ),
    );

    if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
    }
  }
}
