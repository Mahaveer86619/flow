import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/song.dart';
import '../blocs/player/player_bloc.dart';
import '../screens/player/player_screen.dart';
import '../../core/responsive/breakpoints.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song> queue;
  final int index;
  final String? heroTag;

  const SongTile({
    super.key,
    required this.song,
    required this.queue,
    required this.index,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = context.watch<PlayerBloc>().state;
    final isLiked = state.isLiked(song);
    final isDesktop = Breakpoints.isDesktop(MediaQuery.sizeOf(context).width);

    return ListTile(
      onTap: () {
        context.read<PlayerBloc>().add(
          PlayQueueEvent(songs: List<Song>.from(queue), startIndex: index),
        );
        if (!isDesktop) {
          PlayerScreen.show(context);
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Hero(
        tag: heroTag ?? 'tile_art_${song.id}_${song.hashCode}_$index',
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [song.colorPrimary, song.colorSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: song.thumbnailUrl != null
              ? Image.network(
                  song.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(),
                )
              : _fallback(),
        ),
      ),
      title: Text(
        song.title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: colorScheme.onSurface.withAlpha(140),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLiked)
            Icon(
              Icons.favorite_rounded,
              size: 16,
              color: const Color(0xFFEC4899),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showOptions(context, isLiked),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, bool isLiked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isLiked ? const Color(0xFFEC4899) : null,
                ),
                title: Text(
                  isLiked ? 'Remove from Favourites' : 'Add to Favourites',
                ),
                onTap: () {
                  context.read<PlayerBloc>().add(ToggleLikeEvent(song));
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('Add to another Playlist'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share Song'),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return const Center(
      child: Icon(Icons.music_note_rounded, color: Colors.white, size: 20),
    );
  }
}
