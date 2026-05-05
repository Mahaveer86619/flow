import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../domain/entities/song.dart';
import '../../../../domain/entities/home_data.dart';

/// Trending: horizontal scroll of ranked song tiles.
/// Each tile shows rank number, square thumbnail, title + artist.
class TrendingShelf extends StatelessWidget {
  final List<HomeItem> items;
  final void Function(Song song, List<Song> queue, int index) onSongTap;

  const TrendingShelf({
    super.key,
    required this.items,
    required this.onSongTap,
  });

  static const double _cardWidth = 180;
  static const double _thumbSize = 140;
  static const double _labelHeight = 46;

  @override
  Widget build(BuildContext context) {
    final songs = items
        .where((i) => i.type == HomeItemType.song)
        .map((i) => i.data as Song)
        .toList();
    if (songs.isEmpty) return const SizedBox.shrink();

    return RepaintBoundary(
      child: SizedBox(
        height: _thumbSize + _labelHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: songs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 4),
          itemBuilder: (context, index) {
            return _TrendingCard(
              song: songs[index],
              rank: index + 1,
              onTap: () => onSongTap(songs[index], songs, index),
            );
          },
        ),
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final Song song;
  final int rank;
  final VoidCallback onTap;

  const _TrendingCard({
    required this.song,
    required this.rank,
    required this.onTap,
  });

  static const double _thumbSize = 140;

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700); // gold
    if (rank == 2) return const Color(0xFFC0C0C0); // silver
    if (rank == 3) return const Color(0xFFCD7F32); // bronze
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _thumbSize,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: _thumbSize,
                    height: _thumbSize,
                    child: song.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: song.thumbnailUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 280,
                            placeholder: (_, __) => _Placeholder(),
                            errorWidget: (_, __, ___) => _Placeholder(),
                          )
                        : _Placeholder(),
                  ),
                ),
                // Rank badge — big translucent number bottom-left
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black87, Colors.black.withAlpha(0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: rank <= 9 ? 26 : 22,
                        fontWeight: FontWeight.w900,
                        color: _rankColor,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              song.title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: TextStyle(
                fontSize: 11,
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

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withAlpha(18),
      child: const Icon(Icons.bar_chart_rounded, color: Colors.white30, size: 32),
    );
  }
}
