import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../domain/entities/home_data.dart';
import '../../../../domain/entities/podcast.dart';

/// Podcast shelf: circle art + show name below.
/// Falls back gracefully if no Podcast entity — uses HomeItem generic data.
class PodcastShelf extends StatelessWidget {
  final List<HomeItem> items;
  final void Function(HomeItem item) onItemTap;

  const PodcastShelf({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  static const double _thumbSize = 108;
  static const double _labelHeight = 46;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return RepaintBoundary(
      child: SizedBox(
        height: _thumbSize + _labelHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            return _PodcastCard(
              item: items[index],
              onTap: () => onItemTap(items[index]),
            );
          },
        ),
      ),
    );
  }
}

class _PodcastCard extends StatelessWidget {
  final HomeItem item;
  final VoidCallback onTap;

  const _PodcastCard({required this.item, required this.onTap});

  static const double _thumbSize = 108;

  String get _thumbnailUrl {
    final data = item.data;
    if (data is Podcast) return data.thumbnailUrl ?? '';
    // fallback for generic playlist-like objects
    return '';
  }

  String get _title {
    final data = item.data;
    if (data is Podcast) return data.title;
    return 'Podcast';
  }

  String get _episodeInfo {
    final data = item.data;
    if (data is Podcast) return data.publisher ?? '';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _thumbSize,
        child: Column(
          children: [
            // Circular thumbnail
            Container(
              width: _thumbSize,
              height: _thumbSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: _thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _thumbnailUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 216,
                      placeholder: (_, __) => _PodcastPlaceholder(),
                      errorWidget: (_, __, ___) => _PodcastPlaceholder(),
                    )
                  : _PodcastPlaceholder(),
            ),
            const SizedBox(height: 8),
            Text(
              _title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (_episodeInfo.isNotEmpty)
              Text(
                _episodeInfo,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withAlpha(120),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

class _PodcastPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withAlpha(15),
      child: const Icon(
        Icons.podcasts_rounded,
        color: Colors.white38,
        size: 36,
      ),
    );
  }
}
