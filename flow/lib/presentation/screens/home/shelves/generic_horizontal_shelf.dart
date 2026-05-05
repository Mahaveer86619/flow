import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../domain/entities/home_data.dart';
import '../../../../domain/entities/song.dart';
import '../../playlist/playlist_screen.dart';

/// Generic horizontal shelf — handles Song, Video, Playlist, Album, and Artist cards.
///
/// Width and aspect ratio are configurable so it doubles as the shelf for
/// New Releases, Mixed For You, Recommended Albums, and any catch-all shelf.
class GenericHorizontalShelf extends StatelessWidget {
  final List<HomeItem> items;
  final void Function(Song song, List<Song> queue, int index)? onSongTap;
  final double cardWidth;
  final double aspectRatio; // 1.0 = square, < 1 = portrait
  final bool showArtist;
  final bool circleArt;

  const GenericHorizontalShelf({
    super.key,
    required this.items,
    this.onSongTap,
    this.cardWidth = 140,
    this.aspectRatio = 1.0,
    this.showArtist = true,
    this.circleArt = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Playable songs (used as the tap queue for song/video items)
    final playableQueue = items
        .where((i) =>
            i.type == HomeItemType.song || i.type == HomeItemType.video)
        .map((i) => i.data as Song)
        .toList();

    final thumbHeight = cardWidth / aspectRatio;
    const labelHeight = 46.0;

    return RepaintBoundary(
      child: SizedBox(
        height: thumbHeight + labelHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final item = items[index];

            switch (item.type) {
              case HomeItemType.song:
              case HomeItemType.video:
                final song = item.data as Song;
                return _SongCard(
                  song: song,
                  cardWidth: cardWidth,
                  thumbHeight: thumbHeight,
                  circleArt: circleArt,
                  showArtist: showArtist,
                  isVideo: item.type == HomeItemType.video,
                  onTap: onSongTap == null
                      ? null
                      : () => onSongTap!(
                            song,
                            playableQueue,
                            playableQueue.indexOf(song),
                          ),
                );

              case HomeItemType.album:
              case HomeItemType.playlist:
                final playlist = item.data as Playlist;
                return _PlaylistCard(
                  playlist: playlist,
                  cardWidth: cardWidth,
                  thumbHeight: thumbHeight,
                  circleArt: circleArt,
                  isAlbum: item.type == HomeItemType.album,
                );

              case HomeItemType.artist:
                // Artist data is a Map<String, dynamic> set by HomeDataModel
                final artistData = item.data as Map<String, dynamic>;
                return _ArtistCard(
                  name: artistData['name'] as String? ?? 'Unknown',
                  thumbnailUrl: artistData['thumbnailUrl'] as String?,
                  cardWidth: cardWidth,
                  thumbHeight: thumbHeight,
                );
            }
          },
        ),
      ),
    );
  }
}

// ─── Song / Video Card ────────────────────────────────────────────────────────

class _SongCard extends StatelessWidget {
  final Song song;
  final double cardWidth;
  final double thumbHeight;
  final bool circleArt;
  final bool showArtist;
  final bool isVideo;
  final VoidCallback? onTap;

  const _SongCard({
    required this.song,
    required this.cardWidth,
    required this.thumbHeight,
    this.circleArt = false,
    this.showArtist = true,
    this.isVideo = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget thumb = SizedBox(
      width: cardWidth,
      height: thumbHeight,
      child: song.thumbnailUrl != null
          ? CachedNetworkImage(
              imageUrl: song.thumbnailUrl!,
              fit: BoxFit.cover,
              memCacheWidth: (cardWidth * 2).toInt(),
              placeholder: (_, __) =>
                  _ThumbPlaceholder(icon: Icons.music_note_rounded),
              errorWidget: (_, __, ___) =>
                  _ThumbPlaceholder(icon: Icons.music_note_rounded),
            )
          : _ThumbPlaceholder(icon: Icons.music_note_rounded),
    );

    // Wrap in clip shape
    Widget art = circleArt
        ? ClipOval(child: thumb)
        : ClipRRect(borderRadius: BorderRadius.circular(10), child: thumb);

    // For video items add a small play-arrow overlay so they're visually
    // distinct from regular songs even at small card widths.
    if (isVideo && !circleArt) {
      art = Stack(
        children: [
          art,
          Positioned.fill(
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: circleArt
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            art,
            const SizedBox(height: 8),
            Text(
              song.title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: circleArt ? TextAlign.center : TextAlign.start,
            ),
            if (showArtist)
              Text(
                song.artist,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withAlpha(130),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: circleArt ? TextAlign.center : TextAlign.start,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Playlist / Album Card ────────────────────────────────────────────────────

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final double cardWidth;
  final double thumbHeight;
  final bool circleArt;
  final bool isAlbum;

  const _PlaylistCard({
    required this.playlist,
    required this.cardWidth,
    required this.thumbHeight,
    this.circleArt = false,
    this.isAlbum = false,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = Container(
      width: cardWidth,
      height: thumbHeight,
      color: playlist.color,
      child: playlist.thumbnailUrl != null
          ? CachedNetworkImage(
              imageUrl: playlist.thumbnailUrl!,
              fit: BoxFit.cover,
              memCacheWidth: (cardWidth * 2).toInt(),
              placeholder: (_, __) =>
                  _ThumbPlaceholder(icon: Icons.queue_music_rounded),
              errorWidget: (_, __, ___) =>
                  _ThumbPlaceholder(icon: Icons.queue_music_rounded),
            )
          : _ThumbPlaceholder(icon: Icons.queue_music_rounded),
    );

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              PlaylistScreen(playlist: playlist, isAlbum: isAlbum),
        ),
      ),
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: circleArt
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            circleArt
                ? ClipOval(child: thumb)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10), child: thumb),
            const SizedBox(height: 8),
            Text(
              playlist.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: circleArt ? TextAlign.center : TextAlign.start,
            ),
            Text(
              playlist.description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withAlpha(130),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: circleArt ? TextAlign.center : TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Artist Card ──────────────────────────────────────────────────────────────

class _ArtistCard extends StatelessWidget {
  final String name;
  final String? thumbnailUrl;
  final double cardWidth;
  final double thumbHeight;

  const _ArtistCard({
    required this.name,
    this.thumbnailUrl,
    required this.cardWidth,
    required this.thumbHeight,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = SizedBox(
      width: cardWidth,
      height: thumbHeight,
      child: thumbnailUrl != null
          ? CachedNetworkImage(
              imageUrl: thumbnailUrl!,
              fit: BoxFit.cover,
              memCacheWidth: (cardWidth * 2).toInt(),
              placeholder: (_, __) =>
                  _ThumbPlaceholder(icon: Icons.person_rounded),
              errorWidget: (_, __, ___) =>
                  _ThumbPlaceholder(icon: Icons.person_rounded),
            )
          : _ThumbPlaceholder(icon: Icons.person_rounded),
    );

    return SizedBox(
      width: cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(child: thumb),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Shared placeholder ───────────────────────────────────────────────────────

class _ThumbPlaceholder extends StatelessWidget {
  final IconData icon;
  const _ThumbPlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withAlpha(18),
      child: Icon(icon, color: Colors.white30, size: 28),
    );
  }
}
