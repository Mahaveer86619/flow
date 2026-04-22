import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_constants.dart';
import '../../core/storage/local_storage.dart';
import '../blocs/player/player_bloc.dart';
import '../screens/player/player_screen.dart';
import '../../domain/entities/song.dart';
import 'text_carousel.dart';

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
            margin: const EdgeInsets.symmetric(horizontal: 10),
            height: 66,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withAlpha(220),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(20), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Row(
                    children: [
                      // ── 1. Thumbnail ───────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Hero(
                          tag: 'active_art_${song.id}',
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(20),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: RepaintBoundary(
                              child: () {
                                String? thumbUrl = song.thumbnailUrl;
                                final metadata = LocalStorage.instance
                                    .getDownloadMetadata(song.id);
                                if (metadata != null &&
                                    metadata['thumbnailUrl'] != null) {
                                  thumbUrl = metadata['thumbnailUrl'] as String;
                                }

                                if (thumbUrl == null)
                                  return _ArtFallback(song: song);

                                if (thumbUrl.startsWith('http')) {
                                  return Image.network(
                                    thumbUrl,
                                    fit: BoxFit.cover,
                                    cacheWidth: 150,
                                    cacheHeight: 150,
                                    errorBuilder: (_, __, ___) =>
                                        _ArtFallback(song: song),
                                  );
                                } else {
                                  final file = File(thumbUrl);
                                  if (file.existsSync()) {
                                    return Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                      cacheWidth: 150,
                                      cacheHeight: 150,
                                      errorBuilder: (_, __, ___) =>
                                          _ArtFallback(song: song),
                                    );
                                  }
                                  // Final fallback to remote URL from original song if local file is missing
                                  if (song.thumbnailUrl != null &&
                                      song.thumbnailUrl!.startsWith('http')) {
                                    return Image.network(
                                      song.thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      cacheWidth: 150,
                                      cacheHeight: 150,
                                      errorBuilder: (_, __, ___) =>
                                          _ArtFallback(song: song),
                                    );
                                  }
                                  return _ArtFallback(song: song);
                                }
                              }(),
                            ),
                          ),
                        ),
                      ),

                      // ── 2. Information, Controls & Progress ─────────────────
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(2, 7, 16, 7),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Song & Artist Info
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Song Title
                                        TextCarousel(
                                          text: song.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13.5,
                                            letterSpacing: -0.3,
                                            color: colorScheme.onSurface,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        // Artist
                                        Text(
                                          song.artist,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface
                                                .withAlpha(150),
                                            height: 1.1,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Controls
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _ControlButton(
                                        icon: Icons.skip_previous_rounded,
                                        size: 32,
                                        onTap: () => context
                                            .read<PlayerBloc>()
                                            .add(const SkipPreviousEvent()),
                                      ),
                                      const SizedBox(width: 4),
                                      BlocBuilder<PlayerBloc, PlayerState>(
                                        buildWhen: (prev, curr) =>
                                            prev.isPlaying != curr.isPlaying,
                                        builder: (context, state) {
                                          return _ControlButton(
                                            icon: state.isPlaying
                                                ? Icons
                                                      .pause_circle_filled_rounded
                                                : Icons
                                                      .play_circle_filled_rounded,
                                            size: 42,
                                            color: colorScheme.primary,
                                            onTap: () =>
                                                context.read<PlayerBloc>().add(
                                                  const TogglePlayPauseEvent(),
                                                ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      _ControlButton(
                                        icon: Icons.skip_next_rounded,
                                        size: 32,
                                        onTap: () => context
                                            .read<PlayerBloc>()
                                            .add(const SkipNextEvent()),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Row 3: Progress Bar
                              BlocBuilder<PlayerBloc, PlayerState>(
                                buildWhen: (prev, curr) =>
                                    prev.progress != curr.progress ||
                                    prev.isBuffering != curr.isBuffering,
                                builder: (context, state) {
                                  return Container(
                                    height: 2,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: AppRadius.smallBorderRadius,
                                      color: colorScheme.onSurface.withAlpha(
                                        20,
                                      ),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: state.progress.clamp(
                                        0.0,
                                        1.0,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              AppRadius.smallBorderRadius,
                                          color: colorScheme.primary,
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorScheme.primary
                                                  .withAlpha(60),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final Color? color;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Icon(icon, size: size, color: color),
      ),
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
      child: Center(
        child: Text(
          'f',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
