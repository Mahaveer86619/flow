import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../blocs/player/player_bloc.dart';
import '../screens/player/player_screen.dart';
import 'text_carousel.dart';
import 'album_art_widget.dart';
import '../../core/platform/desktop_controller.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        if (state.currentSong == null) return const SizedBox.shrink();

        final colorScheme = Theme.of(context).colorScheme;
        final song = state.currentSong!;

        return GestureDetector(
          onTap: () => PlayerScreen.show(context),
          onVerticalDragEnd: (_) => PlayerScreen.show(context),
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                state.customPrimary?.withAlpha(40) ?? colorScheme.primary.withAlpha(40),
                Colors.black,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: state.customPrimary?.withAlpha(40) ?? Colors.white.withAlpha(20),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Artwork
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: song.thumbnailUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(song.thumbnailUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: song.thumbnailUrl == null
                            ? const _PlaceholderIcon(size: 44)
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextCarousel(
                              text: song.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              song.artist,
                              style: TextStyle(
                                color: colorScheme.onSurface.withAlpha(140),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))
                            _ControlButton(
                              icon: Icons.open_in_new_rounded,
                              size: 24,
                              onTap: () => DesktopController.instance.toggleMiniPlayer(),
                            ),
                          _ControlButton(
                            icon: Icons.skip_previous_rounded,
                            size: 32,
                            onTap: () => context
                                .read<PlayerBloc>()
                                .add(const SkipPreviousEvent()),
                          ),
                          _ControlButton(
                            icon: state.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 38,
                            color: state.customPrimary ?? colorScheme.primary,
                            onTap: () => context
                                .read<PlayerBloc>()
                                .add(const TogglePlayPauseEvent()),
                          ),
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
                ),
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
  final Color? color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.size,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: size,
            color: color ?? Colors.white,
          ),
        ),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  final double size;
  const _PlaceholderIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Center(
        child: Text(
          'f',
          style: GoogleFonts.spaceGrotesk(
            fontSize: size * 0.6,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
