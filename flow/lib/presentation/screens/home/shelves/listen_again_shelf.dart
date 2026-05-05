import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../domain/entities/song.dart';
import '../../../../domain/entities/home_data.dart';

/// Listen Again: 2-row horizontal grid.
/// Each card = square thumbnail with title below.
/// Performance: fixed itemExtent + RepaintBoundary.
class ListenAgainShelf extends StatelessWidget {
  final List<HomeItem> items;
  final void Function(Song song, List<Song> queue, int index) onSongTap;

  const ListenAgainShelf({
    super.key,
    required this.items,
    required this.onSongTap,
  });

  static const double _cardSize = 110;
  static const double _spacing = 12;
  static const int _rows = 2;
  static const double _labelHeight = 42;

  @override
  Widget build(BuildContext context) {
    final songs = items
        .where((i) => i.type == HomeItemType.song)
        .map((i) => i.data as Song)
        .toList();
    if (songs.isEmpty) return const SizedBox.shrink();

    final columns = <List<Song>>[];
    for (var i = 0; i < songs.length; i += _rows) {
      columns.add(songs.sublist(i, (i + _rows).clamp(0, songs.length)));
    }

    final totalHeight = _rows * (_cardSize + _labelHeight) + (_rows - 1) * _spacing;

    return RepaintBoundary(
      child: SizedBox(
        height: totalHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: columns.length,
          separatorBuilder: (_, __) => const SizedBox(width: _spacing),
          itemBuilder: (context, colIndex) {
            final colSongs = columns[colIndex];
            return SizedBox(
              width: _cardSize,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < colSongs.length; i++) ...[
                    if (i > 0) const SizedBox(height: _spacing),
                    _ListenAgainCard(
                      song: colSongs[i],
                      size: _cardSize,
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

class _ListenAgainCard extends StatelessWidget {
  final Song song;
  final double size;
  final VoidCallback onTap;

  const _ListenAgainCard({
    required this.song,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: size,
              height: size,
              child: song.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: song.thumbnailUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 220,
                      placeholder: (_, __) => _Placeholder(),
                      errorWidget: (_, __, ___) => _Placeholder(),
                    )
                  : _Placeholder(),
            ),
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
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withAlpha(18),
      child: const Icon(Icons.music_note_rounded, color: Colors.white30, size: 28),
    );
  }
}
