// ─────────────────────────────────────────────────────────────────────────────
// SongCard — specialized grid-item for songs.
//
// Shows a square thumbnail with a subtle "play" overlay on hover, followed by
// title and artist. Used on Home and Search screens.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/storage/local_storage.dart';
import '../../domain/entities/song.dart';
import '../blocs/player/player_bloc.dart';
import '../screens/player/player_screen.dart';
import '../../core/intelligence/app_intelligence.dart';

class SongCard extends StatefulWidget {
  final Song song;
  final List<Song> queue;
  final int index;
  final double size;
  final double? cardWidth;
  final double aspectRatio;
  final String? heroTag;
  final bool startRadio;
  final bool skipPlayerScreen;

  const SongCard({
    super.key,
    required this.song,
    this.queue = const [],
    this.index = 0,
    this.size = 140,
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
    final isLiked = LocalStorage.instance.likedSongIds.contains(widget.song.id);
    final width = widget.cardWidth ?? widget.size;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          if (widget.startRadio) {
            context.read<PlayerBloc>().add(PlayRadioEvent(widget.song));
          } else if (widget.queue.isNotEmpty) {
            context.read<PlayerBloc>().add(PlayQueueEvent(songs: widget.queue, startIndex: widget.index));
          } else {
            context.read<PlayerBloc>().add(PlaySingleEvent(widget.song));
          }
          
          if (!widget.skipPlayerScreen) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PlayerScreen(),
              ),
            );
          }
        },
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail with Hover Overlay ───────────────────────────────────
              AspectRatio(
                aspectRatio: widget.aspectRatio,
                child: AnimatedScale(
                  scale: _isHovered ? 1.04 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Hero(
                    tag: widget.heroTag ?? widget.song.id,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: widget.song.colorPrimary.withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              if (_isHovered)
                                BoxShadow(
                                  color: widget.song.colorPrimary.withAlpha(60),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: widget.song.thumbnailUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.song.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorWidget: (context, url, error) => _buildPlaceholder(),
                                )
                              : _buildPlaceholder(),
                        ),
                        // Hover Overlay
                        AnimatedOpacity(
                          opacity: _isHovered ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(100),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Title ──────────────────────────────────────────────────────────
              Text(
                widget.song.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // ── Artist & Taste Match ──────────────────────────────────────────
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
                  _TasteMatchIndicator(song: widget.song),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        'f',
        style: GoogleFonts.spaceGrotesk(
          fontSize: widget.size * 0.45,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}

class _TasteMatchIndicator extends StatelessWidget {
  final Song song;
  const _TasteMatchIndicator({required this.song});

  @override
  Widget build(BuildContext context) {
    // Generate fingerprint to match AppIntelligence node ID
    final fingerprint = '${_normalize(song.artist)}::${_normalize(song.title)}';
    final trackNodeId = 'track:$fingerprint';
    
    final score = AppIntelligence.instance.graph.nodes[trackNodeId]?.score ?? 0.0;
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

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[^\w\s]"), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

