import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_constants.dart';
import '../../core/storage/local_storage.dart';
import '../../domain/entities/song.dart';
import '../blocs/player/player_bloc.dart';
import '../screens/player/player_screen.dart';
import '../../core/responsive/breakpoints.dart';
import 'add_to_playlist_dialog.dart';

import 'text_carousel.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song> queue;
  final int index;
  final String? heroTag;
  final VoidCallback? onTap;
  final bool startRadio;
  final bool skipPlayerScreen;

  const SongTile({
    super.key,
    required this.song,
    required this.queue,
    required this.index,
    this.heroTag,
    this.onTap,
    this.startRadio = false,
    this.skipPlayerScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = context.watch<PlayerBloc>().state;
    final isLiked = state.isLiked(song);
    final isDesktop = Breakpoints.isDesktop(MediaQuery.sizeOf(context).width);

    return ListTile(
      onTap:
          onTap ??
          () {
            if (startRadio) {
              context.read<PlayerBloc>().add(PlayRadioEvent(song));
            } else {
              context.read<PlayerBloc>().add(
                PlayQueueEvent(
                  songs: List<Song>.from(queue),
                  startIndex: index,
                ),
              );
            }
            if (!skipPlayerScreen && !isDesktop) {
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
            borderRadius: AppRadius.mediumBorderRadius,
            gradient: LinearGradient(
              colors: [song.colorPrimary, song.colorSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: () {
            String? thumbUrl = song.thumbnailUrl;
            final metadata = LocalStorage.instance.getDownloadMetadata(song.id);
            if (metadata != null && metadata['thumbnailUrl'] != null) {
              thumbUrl = metadata['thumbnailUrl'] as String;
            }

            if (thumbUrl == null) return _fallback();

            if (thumbUrl.startsWith('http')) {
              return Image.network(
                thumbUrl,
                fit: BoxFit.cover,
                headers: const {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
                },
                errorBuilder: (_, __, ___) => _fallback(),
              );
            } else {
              final file = File(thumbUrl);
              if (file.existsSync()) {
                return Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(),
                );
              }
              // Final fallback to remote URL from original song if local file is missing
              if (song.thumbnailUrl != null &&
                  song.thumbnailUrl!.startsWith('http')) {
                return Image.network(
                  song.thumbnailUrl!,
                  fit: BoxFit.cover,
                  headers: const {
                    'User-Agent':
                        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
                  },
                  errorBuilder: (_, __, ___) => _fallback(),
                );
              }
              return _fallback();
            }
          }(),
        ),
      ),
      title: TextCarousel(
        text: song.title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
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
          _SongOptionsButton(song: song, isLiked: isLiked),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Text(
        'f',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}

class _SongOptionsButton extends StatelessWidget {
  final Song song;
  final bool isLiked;

  const _SongOptionsButton({required this.song, required this.isLiked});

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isMobile =
        platform == TargetPlatform.iOS || platform == TargetPlatform.android;

    if (isMobile) {
      return IconButton(
        icon: const Icon(Icons.more_vert_rounded),
        onPressed: () => _showMobileOptions(context),
        iconSize: 20,
      );
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      iconSize: 20,
      onSelected: (value) {
        if (value == 'radio') {
          context.read<PlayerBloc>().add(PlayRadioEvent(song));
        } else if (value == 'play_next') {
          context.read<PlayerBloc>().add(InsertNextEvent(song));
        } else if (value == 'add_queue') {
          context.read<PlayerBloc>().add(AppendToQueueEvent(song));
        } else if (value == 'like') {
          context.read<PlayerBloc>().add(ToggleLikeEvent(song));
        } else if (value == 'playlist') {
          AddToPlaylistDialog.show(context, song);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'radio',
          child: Row(
            children: [
              const Icon(Icons.radio_rounded, size: 20),
              const SizedBox(width: 12),
              const Text('Start radio'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'play_next',
          child: Row(
            children: [
              const Icon(Icons.playlist_play_rounded, size: 20),
              const SizedBox(width: 12),
              const Text('Play Next'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'add_queue',
          child: Row(
            children: [
              const Icon(Icons.queue_music_rounded, size: 20),
              const SizedBox(width: 12),
              const Text('Add to Queue'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'like',
          child: Row(
            children: [
              Icon(
                isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 20,
                color: isLiked ? const Color(0xFFEC4899) : null,
              ),
              const SizedBox(width: 12),
              Text(isLiked ? 'Remove from Favourites' : 'Add to Favourites'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'playlist',
          child: Row(
            children: [
              const Icon(Icons.playlist_add_rounded, size: 20),
              const SizedBox(width: 12),
              const Text('Add to another Playlist'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              const Icon(Icons.share_rounded, size: 20),
              const SizedBox(width: 12),
              const Text('Share Song'),
            ],
          ),
        ),
      ],
    );
  }

  void _showMobileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
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
                leading: const Icon(Icons.radio_rounded),
                title: const Text('Start radio'),
                onTap: () {
                  context.read<PlayerBloc>().add(PlayRadioEvent(song));
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_play_rounded),
                title: const Text('Play Next'),
                onTap: () {
                  context.read<PlayerBloc>().add(InsertNextEvent(song));
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music_rounded),
                title: const Text('Add to Queue'),
                onTap: () {
                  context.read<PlayerBloc>().add(AppendToQueueEvent(song));
                  Navigator.pop(ctx);
                },
              ),
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
                onTap: () {
                  Navigator.pop(ctx);
                  AddToPlaylistDialog.show(context, song);
                },
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
}
