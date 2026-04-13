import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/player/player_bloc.dart';
import '../screens/player/player_screen.dart';
import '../../domain/entities/song.dart';
import 'like_button.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) => prev.currentSong?.id != curr.currentSong?.id,
      builder: (context, state) {
        final song = state.currentSong;
        if (song == null) return const SizedBox.shrink();

        final colorScheme = Theme.of(context).colorScheme;

        return GestureDetector(
          onTap: () => PlayerScreen.show(context),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            height: 68,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withAlpha(235),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withAlpha(50),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  // ── Album art ────────────────────────────────────────────────────
                  Hero(
                    tag: 'active_art_${song.id}',
                    child: RepaintBoundary(
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: song.thumbnailUrl != null
                            ? Image.network(
                                song.thumbnailUrl!,
                                fit: BoxFit.cover,
                                cacheWidth: 320,
                                cacheHeight: 180,
                                headers: const {
                                  'User-Agent':
                                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    _ArtFallback(song: song),
                              )
                            : _ArtFallback(song: song),
                      ),
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
                        BlocBuilder<PlayerBloc, PlayerState>(
                          buildWhen: (prev, curr) =>
                              prev.progress != curr.progress,
                          builder: (context, state) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: RepaintBoundary(
                                child: LinearProgressIndicator(
                                  value: state.progress,
                                  minHeight: 3,
                                  backgroundColor: colorScheme.onSurface
                                      .withAlpha(25),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    song.colorPrimary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),

                  // ── Like button ──────────────────────────────────────────────────
                  BlocBuilder<PlayerBloc, PlayerState>(
                    buildWhen: (prev, curr) =>
                        prev.likedSongIds.length != curr.likedSongIds.length ||
                        prev.currentSong?.id != curr.currentSong?.id,
                    builder: (context, state) {
                      return LikeButton(
                        isLiked: state.isLiked(song),
                        size: 22,
                        onTap: () => context.read<PlayerBloc>().add(
                          ToggleLikeEvent(song),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),

                  // ── Controls ──────────────────────────────────────────────────────
                  BlocBuilder<PlayerBloc, PlayerState>(
                    buildWhen: (prev, curr) => prev.isPlaying != curr.isPlaying,
                    builder: (context, state) {
                      return IconButton(
                        icon: Icon(
                          state.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 30,
                        ),
                        onPressed: () => context.read<PlayerBloc>().add(
                          const TogglePlayPauseEvent(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 26),
                    onPressed: () =>
                        context.read<PlayerBloc>().add(const SkipNextEvent()),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArtFallback extends StatelessWidget {
  final Song song;
  const _ArtFallback({required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [song.colorPrimary, song.colorSecondary],
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}
