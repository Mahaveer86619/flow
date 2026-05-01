import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../blocs/player/player_bloc.dart';
import '../../core/platform/desktop_controller.dart';


class DesktopMiniPlayer extends StatelessWidget {
  const DesktopMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        final song = state.currentSong;
        if (song == null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'No song playing',
                style: GoogleFonts.outfit(color: Colors.white70),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                // Artwork
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: song.thumbnailUrl!,
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 130,
                          height: 130,
                          color: cs.primary.withAlpha(40),
                          child: const Icon(Icons.music_note_rounded),
                        ),
                ),
                const SizedBox(width: 16),
                // Info & Controls
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded),
                            onPressed: () => context.read<PlayerBloc>().add(const SkipPreviousEvent()),
                          ),
                          IconButton(
                            icon: Icon(
                              state.isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_filled_rounded,
                              size: 36,
                              color: cs.primary,
                            ),
                            onPressed: () => context.read<PlayerBloc>().add(const TogglePlayPauseEvent()),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            onPressed: () => context.read<PlayerBloc>().add(const SkipNextEvent()),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.open_in_full_rounded, size: 18),
                            onPressed: () => DesktopController.instance.toggleMiniPlayer(),
                            tooltip: 'Exit Mini Player',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
