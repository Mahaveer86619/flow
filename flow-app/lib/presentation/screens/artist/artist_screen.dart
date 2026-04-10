import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../player/player_screen.dart';

class ArtistScreen extends StatelessWidget {
  final Map<String, dynamic> artist;
  final List<Song> allSongs;

  const ArtistScreen({super.key, required this.artist, required this.allSongs});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = Breakpoints.isDesktop(MediaQuery.sizeOf(context).width);

    final name = artist['name'] as String;
    final primary = artist['colorPrimary'] as Color;
    final secondary = artist['colorSecondary'] as Color;
    final artistSongs = allSongs.where((s) => s.artist == name).toList();
    final isSmall = Breakpoints.isMobile(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(name,
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: isSmall ? 140.0 : 180.0,
            height: isSmall ? 140.0 : 180.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primary, secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withAlpha(80),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              name
                  .split(' ')
                  .map((w) => w.isNotEmpty ? w[0] : '')
                  .take(2)
                  .join(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: isSmall ? 44.0 : 64.0,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(name,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: isSmall ? 20.0 : 28.0,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Artist',
              style:
                  TextStyle(color: colorScheme.onSurface.withAlpha(180))),
          const SizedBox(height: 24),
          Expanded(
            child: artistSongs.isEmpty
                ? Center(
                    child: Text('No songs found',
                        style: TextStyle(
                            color: colorScheme.onSurface.withAlpha(140))))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: artistSongs.length,
                    itemBuilder: (context, i) {
                      final song = artistSongs[i];
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
                          child: const Icon(Icons.music_note_rounded,
                              color: Colors.white, size: 20),
                        ),
                        title: Text(song.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(song.album),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert_rounded),
                          onPressed: () {},
                        ),
                        onTap: () {
                          context.read<PlayerBloc>().add(
                            PlayQueueEvent(
                              songs: artistSongs,
                              startIndex: i,
                            ),
                          );
                          if (!isDesktop) {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const PlayerScreen(),
                            ));
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
