import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/player/player_bloc.dart';
import '../screens/player/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerBloc>().state;
    final song = state.currentSong;
    if (song == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PlayerScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        height: 76,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(70),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Album art ────────────────────────────────────────────────────
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [song.colorPrimary, song.colorSecondary],
                ),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),

            // ── Song info + inline progress bar ───────────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withAlpha(140),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 6),
                  // Progress bar — embedded in song info for clear association
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 3,
                      backgroundColor: colorScheme.onSurface.withAlpha(25),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        song.colorPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),

            // ── Controls ──────────────────────────────────────────────────────
            IconButton(
              icon: Icon(
                state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 30,
              ),
              onPressed: () => context.read<PlayerBloc>().add(
                const TogglePlayPauseEvent(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, size: 26),
              onPressed: () => context.read<PlayerBloc>().add(
                const SkipNextEvent(),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
