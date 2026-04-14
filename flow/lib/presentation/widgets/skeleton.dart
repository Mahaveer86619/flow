import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Widget? child;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: child ??
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: borderRadius != 0
                  ? BorderRadius.circular(borderRadius)
                  : null,
              shape: borderRadius == -1 ? BoxShape.circle : BoxShape.rectangle,
            ),
          ),
    );
  }
}

class SkeletonText extends StatelessWidget {
  final double width;
  final double height;
  const SkeletonText({super.key, required this.width, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      width: width,
      height: height,
      borderRadius: height / 2,
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;
  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      width: size,
      height: size,
      borderRadius: -1,
    );
  }
}

class SkeletonSongCard extends StatelessWidget {
  final double width;
  final double aspectRatio;
  const SkeletonSongCard({
    super.key,
    this.width = 135,
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: Skeleton(borderRadius: 14, width: width),
          ),
          const SizedBox(height: 10),
          SkeletonText(width: width * 0.8, height: 13),
          const SizedBox(height: 6),
          SkeletonText(width: width * 0.5, height: 11),
        ],
      ),
    );
  }
}

class SkeletonArtistCard extends StatelessWidget {
  const SkeletonArtistCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          const SkeletonCircle(size: 90),
          const SizedBox(height: 8),
          const SkeletonText(width: 70, height: 11),
        ],
      ),
    );
  }
}

class SkeletonPlaylistCard extends StatelessWidget {
  final double width;
  const SkeletonPlaylistCard({super.key, this.width = 140});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Skeleton(borderRadius: 14, width: width),
          ),
          const SizedBox(height: 10),
          SkeletonText(width: width * 0.7, height: 13),
          const SizedBox(height: 6),
          SkeletonText(width: width * 0.5, height: 11),
        ],
      ),
    );
  }
}

class SkeletonSongTile extends StatelessWidget {
  const SkeletonSongTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Skeleton(width: 50, height: 50, borderRadius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonText(width: 180, height: 14),
                const SizedBox(height: 6),
                const SkeletonText(width: 120, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
