// ─────────────────────────────────────────────────────────────────────────────
// SongCard — portrait song tile used in horizontal scrolling lists.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final double? cardWidth;
  final double aspectRatio;
  final String? heroTag;
  final bool startRadio;
  final bool skipPlayerScreen;

  const SongCard({
    super.key,
    required this.song,
    required this.queue,
    required this.index,
    this.cardWidth,
    this.aspectRatio = 1.0,
    this.heroTag,
    this.startRadio = false,
    this.skipPlayerScreen = false,
  });

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLiked = context.select<PlayerBloc, bool>(
      (bloc) => bloc.state.isLiked(widget.song),
    );

    final resolvedAspectRatio =
        widget.song.thumbnailWidth != null &&
            widget.song.thumbnailHeight != null
        ? widget.song.thumbnailWidth! / widget.song.thumbnailHeight!
        : widget.aspectRatio;

    // Use a fixed artwork height to keep the row consistent
    const double artworkHeight = 130;
    final double calculatedWidth =
        widget.cardWidth ?? (artworkHeight * resolvedAspectRatio);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _handleTap(context),
        onLongPress: () => _showMenu(context),
        child: SizedBox(
          width: calculatedWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.04 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Container(
                  height: artworkHeight,
                  width: calculatedWidth,
                  child: AspectRatio(
                    aspectRatio: resolvedAspectRatio,
                    child: _Artwork(
                      song: widget.song,
                      size: calculatedWidth,
                      aspectRatio: resolvedAspectRatio,
                      isHovered: _isHovered,
                      heroTag: widget.heroTag,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextCarousel(
                      text: widget.song.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: -0.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showMenu(context),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 16,
                      color: colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                import '../../core/intelligence/app_intelligence.dart';

                class SongCard extends StatefulWidget {
                ...
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
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _TasteMatchIndicator(songId: widget.song.id),
                                ],
                              ),
                ...
                class _TasteMatchIndicator extends StatelessWidget {
                  final String songId;
                  const _TasteMatchIndicator({required this.songId});

                  @override
                  Widget build(BuildContext context) {
                    final score = AppIntelligence.instance.graph.nodes[songId]?.score ?? 0.0;
                    if (score <= 0) return const SizedBox.shrink();

                    // Simple normalization: 1.0 score = 50%, 5.0+ = 99%
                    final matchPercent = (50 + (score * 10)).clamp(50, 99).toInt();

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(40),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$matchPercent%',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }
                }

          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (widget.startRadio) {
      context.read<PlayerBloc>().add(PlayRadioEvent(widget.song));
    } else {
      context.read<PlayerBloc>().add(
        PlayQueueEvent(
          songs: List<Song>.from(widget.queue),
          startIndex: widget.index,
        ),
      );
    }
    if (!widget.skipPlayerScreen &&
        !Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
      PlayerScreen.show(context);
    }
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(modalContext).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  modalContext,
                ).colorScheme.onSurface.withAlpha(40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded),
              title: const Text('Play'),
              onTap: () {
                _handleTap(context);
                Navigator.pop(modalContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_outline_rounded),
              title: const Text('Start Radio'),
              onTap: () {
                context.read<PlayerBloc>().add(PlayRadioEvent(widget.song));
                Navigator.pop(modalContext);
                if (!widget.skipPlayerScreen &&
                    !Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
                  PlayerScreen.show(context);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_play_rounded),
              title: const Text('Play Next'),
              onTap: () {
                context.read<PlayerBloc>().add(InsertNextEvent(widget.song));
                Navigator.pop(modalContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: const Text('Add to Queue'),
              onTap: () {
                context.read<PlayerBloc>().add(AppendToQueueEvent(widget.song));
                Navigator.pop(modalContext);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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
                    fit: BoxFit.cover,
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
                      fit: BoxFit.cover,
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
                      fit: BoxFit.cover,
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
      child: Center(
        child: Text(
          'f',
          style: GoogleFonts.spaceGrotesk(
            fontSize: size * 0.45,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
