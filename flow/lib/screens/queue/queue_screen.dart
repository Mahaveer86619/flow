import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../cubits/player_cubit.dart';
import '../../../models/song.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerCubit>().state;
    final colorScheme = Theme.of(context).colorScheme;

    final currentSong = state.currentSong;
    final queue = state.queue;
    final currentIndex = state.queueIndex;

    final nextSongs = queue.skip(currentIndex + 1).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Queue',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: currentSong == null
          ? const Center(child: Text('No song playing'))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Text(
                  'Now Playing',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                _QueueSongTile(song: currentSong, isPlaying: true),
                if (nextSongs.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Next In Queue',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...nextSongs.map(
                    (song) => _QueueSongTile(song: song, isPlaying: false),
                  ),
                ],
              ],
            ),
    );
  }
}

class _QueueSongTile extends StatelessWidget {
  final Song song;
  final bool isPlaying;

  const _QueueSongTile({required this.song, this.isPlaying = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [song.colorPrimary, song.colorSecondary],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isPlaying
            ? const Icon(Icons.graphic_eq_rounded, color: Colors.white)
            : const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 20,
              ),
      ),
      title: Text(
        song.title,
        style: TextStyle(
          fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w500,
          color: isPlaying ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      subtitle: Text(song.artist),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert_rounded),
        onPressed: () {},
      ),
      onTap: () {
        if (!isPlaying) {
          // If we tap a song in queue, we could play it
          context.read<PlayerCubit>().play(song);
        }
      },
    );
  }
}
