// ─────────────────────────────────────────────────────────────────────────────
// SongCard — portrait song tile used in horizontal scrolling lists.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config/app_constants.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/storage/local_storage.dart';
import '../../domain/entities/song.dart';
import '../blocs/player/player_bloc.dart';
import '../screens/player/player_screen.dart';

import 'text_carousel.dart';

class SongCard extends StatefulWidget {
  final Song song;
  final List<Song> queue;
  final int index;
  final double cardWidth;
  final double aspectRatio;
  final String? heroTag;

  const SongCard({
    super.key,
    required this.song,
    required this.queue,
    required this.index,
    this.cardWidth = 135,
    this.aspectRatio = 1.0,
    this.heroTag,
  });

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = Breakpoints.isDesktop(MediaQuery.sizeOf(context).width);
    final isLiked = context.select<PlayerBloc, bool>(
      (bloc) => bloc.state.isLiked(widget.song),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _handleTap(context),
        child: SizedBox(
          width: widget.cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.04 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: AspectRatio(
                  aspectRatio: widget.aspectRatio,
                  child: _Artwork(
                    song: widget.song,
                    size: widget.cardWidth,
                    aspectRatio: widget.aspectRatio,
                    isHovered: _isHovered,
                    heroTag: widget.heroTag,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextCarousel(
                text: widget.song.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (isLiked)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 12,
                        color: const Color(0xFFEC4899),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      widget.song.artist,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withAlpha(140),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    context.read<PlayerBloc>().add(
      PlayQueueEvent(
        songs: List<Song>.from(widget.queue),
        startIndex: widget.index,
      ),
    );
    if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
      PlayerScreen.show(context);
    }
  }
}

class _Artwork extends StatelessWidget {
  final Song song;
  final double size;
  final double aspectRatio;
  final bool isHovered;
  final String? heroTag;

  const _Artwork({
    required this.song,
    required this.size,
    required this.aspectRatio,
    required this.isHovered,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.mediumBorderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isHovered ? 60 : 40),
                blurRadius: isHovered ? 20 : 12,
                offset: Offset(0, isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Hero(
            tag: heroTag ?? 'card_art_${song.id}_${song.hashCode}',
            child: ClipRRect(
              borderRadius: AppRadius.mediumBorderRadius,
              child: () {
                String? thumbUrl = song.thumbnailUrl;
                final metadata = LocalStorage.instance.getDownloadMetadata(
                  song.id,
                );
                if (metadata != null && metadata['thumbnailUrl'] != null) {
                  thumbUrl = metadata['thumbnailUrl'] as String;
                }

                if (thumbUrl == null) return _fallback();

                if (thumbUrl.startsWith('http')) {
                  return Image.network(
                    thumbUrl,
                    width: size,
                    height: size / aspectRatio,
                    fit: BoxFit.fill,
                    cacheWidth: 640,
                    cacheHeight: (640 / aspectRatio).round(),
                    headers: const {
                      'User-Agent':
                          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
                    },
                    errorBuilder: (context, error, stackTrace) => _fallback(),
                  );
                } else {
                  final file = File(thumbUrl);
                  if (file.existsSync()) {
                    return Image.file(
                      file,
                      width: size,
                      height: size / aspectRatio,
                      fit: BoxFit.fill,
                      cacheWidth: 640,
                      cacheHeight: (640 / aspectRatio).round(),
                      errorBuilder: (context, error, stackTrace) => _fallback(),
                    );
                  }
                  // Final fallback to remote URL from original song if local file is missing
                  if (song.thumbnailUrl != null &&
                      song.thumbnailUrl!.startsWith('http')) {
                    return Image.network(
                      song.thumbnailUrl!,
                      width: size,
                      height: size / aspectRatio,
                      fit: BoxFit.fill,
                      cacheWidth: 640,
                      cacheHeight: (640 / aspectRatio).round(),
                      errorBuilder: (context, error, stackTrace) => _fallback(),
                    );
                  }
                  return _fallback();
                }
              }(),
            ),
          ),
        ),
        if (isHovered)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(30),
                borderRadius: AppRadius.mediumBorderRadius,
              ),
              child: const Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size / aspectRatio,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [song.colorPrimary, song.colorSecondary],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.25,
        color: Colors.white.withAlpha(45),
      ),
    );
  }
}
