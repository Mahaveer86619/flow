import 'package:flutter/material.dart';
import 'skeleton.dart';

class ShimmerShelf extends StatelessWidget {
  final bool isGrid;
  final int itemCount;

  const ShimmerShelf({
    super.key,
    this.isGrid = false,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return SizedBox(
        height: 180,
        child: GridView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: 300,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: itemCount,
          itemBuilder: (_, _) => const _ShimmerSongTile(),
        ),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, _) => const _ShimmerCard(),
      ),
    );
  }
}

class _ShimmerSongTile extends StatelessWidget {
  const _ShimmerSongTile();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Skeleton(height: 48, width: 48, borderRadius: 8),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Skeleton(height: 14, width: double.infinity),
              const SizedBox(height: 6),
              const Skeleton(height: 10, width: 100),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(
            aspectRatio: 1,
            child: Skeleton(height: 140, width: 140, borderRadius: 12),
          ),
          const SizedBox(height: 12),
          const Skeleton(height: 14, width: 120),
          const SizedBox(height: 6),
          const Skeleton(height: 12, width: 80),
        ],
      ),
    );
  }
}
