import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../domain/entities/song.dart';
import '../../../../domain/entities/home_data.dart';

/// Quick Picks: 4-row compact horizontal grid.
/// Each tile = thumbnail + title + artist with a floating play button.
/// Performance: itemExtent = fixed width for O(1) scroll math.
class QuickPicksShelf extends StatelessWidget {
  final List<HomeItem> items;
  final void Function(Song song, List<Song> queue, int index) onSongTap;

  const QuickPicksShelf({
    super.key,
    required this.items,
    required this.onSongTap,
  });

  static const double _tileHeight = 64;
  static const double _tileWidth = 280;
  static const double _spacing = 8;
  static const int _rows = 4;

  @override
  Widget build(BuildContext context) {
    final songs = items
        .where((i) => i.type == HomeItemType.song)
        .map((i) => i.data as Song)
        .toList();
    if (songs.isEmpty) return const SizedBox.shrink();

    // Build column groups: each column has up to _rows tiles
    final columns = <List<Song>>[];
    for (var i = 0; i < songs.length; i += _rows) {
      columns.add(songs.sublist(i, (i + _rows).clamp(0, songs.length)));
    }

    return RepaintBoundary(
      child: SizedBox(
        height: _rows * _tileHeight + (_rows - 1) * _spacing,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: columns.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, colIndex) {
            final colSongs = columns[colIndex];
            return SizedBox(
              width: _tileWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < colSongs.length; i++) ...[
                    if (i > 0) const SizedBox(height: _spacing),
                    _QuickPickTile(
                      song: colSongs[i],
                      onTap: () => onSongTap(
                        colSongs[i],
                        songs,
                        colIndex * _rows + i,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuickPickTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const _QuickPickTile({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 64,
              height: 64,
              child: song.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: song.thumbnailUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 128,
                      placeholder: (_, __) => _PlaceholderBox(icon: Icons.music_note_rounded),
                      errorWidget: (_, __, ___) => _PlaceholderBox(icon: Icons.music_note_rounded),
                    )
                  : _PlaceholderBox(icon: Icons.music_note_rounded),
            ),

            // Text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.artist,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withAlpha(140),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Play icon
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white.withAlpha(160),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  final IconData icon;
  const _PlaceholderBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withAlpha(20),
      child: Icon(icon, color: Colors.white38, size: 24),
    );
  }
}
