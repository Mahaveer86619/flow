import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../player/player_screen.dart';

class ListScreen extends StatelessWidget {
  final String title;
  final List<Song> songs;
  final List<Song> allSongs;

  const ListScreen({
    super.key,
    required this.title,
    required this.songs,
    required this.allSongs,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = Breakpoints.isDesktop(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: songs.isEmpty
          ? const Center(child: Text('No songs found'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: songs.length,
              itemBuilder: (context, i) {
                final song = songs[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [song.colorPrimary, song.colorSecondary],
                        ),
                      ),
                      child: song.thumbnailUrl != null
                          ? Image.network(
                              song.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _fallback(),
                            )
                          : _fallback(),
                    ),
                  ),
                  title: Text(
                    song.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(song.artist),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () {},
                  ),
                  onTap: () {
                    context.read<PlayerBloc>().add(
                      PlayQueueEvent(
                        songs: allSongs,
                        startIndex: allSongs.indexOf(song),
                      ),
                    );
                    if (!isDesktop) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PlayerScreen()),
                      );
                    }
                  },
                );
              },
            ),
    );
  }

  Widget _fallback() {
    return const Center(
      child: Icon(Icons.music_note_rounded, color: Colors.white, size: 20),
    );
  }
}
