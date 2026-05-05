import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../domain/entities/song.dart';
import '../../../../domain/entities/home_data.dart';

/// Music Videos / Livestreams: wide 16:9 cards with a YouTube-style play overlay.
///
/// Accepts items of type [HomeItemType.video] (the new explicit type for 16:9
/// widescreen content) as well as legacy [HomeItemType.song] items, so it works
/// whether the shelf was routed by explicit section key or by content sniffing.
class MusicVideoShelf extends StatelessWidget {
  final List<HomeItem> items;
  final void Function(Song song, List<Song> queue, int index) onSongTap;

  const MusicVideoShelf({
    super.key,
    required this.items,
    required this.onSongTap,
  });

  static const double _cardWidth = 248;
  static const double _labelHeight = 48;

  @override
  Widget build(BuildContext context) {
    // Accept both video and song types so the shelf is robust to both routing
    // paths (explicit section key 'musicVideos' vs. content-type sniffing).
    final songs = items
        .where((i) =>
            i.type == HomeItemType.video || i.type == HomeItemType.song)
        .map((i) => i.data as Song)
        .toList();
    if (songs.isEmpty) return const SizedBox.shrink();

    const thumbHeight = _cardWidth * 9 / 16;

    return RepaintBoundary(
      child: SizedBox(
        height: thumbHeight + _labelHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: songs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            return _VideoCard(
              song: songs[index],
              onTap: () => onSongTap(songs[index], songs, index),
            );
          },
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const _VideoCard({required this.song, required this.onTap});

  static const double _cardWidth = 248;

  /// Show a LIVE badge for UGC content (livestreams), MV badge otherwise.
  String get _badge {
    final type = song.extras?['musicVideoType'] as String? ?? '';
    return type == 'MUSIC_VIDEO_TYPE_UGC' ? 'LIVE' : 'MV';
  }

  Color get _badgeColor {
    return _badge == 'LIVE' ? Colors.red : Colors.white.withAlpha(180);
  }

  @override
  Widget build(BuildContext context) {
    const thumbHeight = _cardWidth * 9 / 16;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  SizedBox(
                    width: _cardWidth,
                    height: thumbHeight,
                    child: song.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: song.thumbnailUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 496,
                            placeholder: (_, __) => const _VideoPlaceholder(),
                            errorWidget: (_, __, ___) =>
                                const _VideoPlaceholder(),
                          )
                        : const _VideoPlaceholder(),
                  ),
                  // Dark gradient at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 56,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Play button overlay
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(120),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  // LIVE / MV badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _badge == 'LIVE'
                            ? Colors.red.withAlpha(220)
                            : Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                      child: Text(
                        _badge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withAlpha(130),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withAlpha(15),
      child: const Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          color: Colors.white30,
          size: 40,
        ),
      ),
    );
  }
}
