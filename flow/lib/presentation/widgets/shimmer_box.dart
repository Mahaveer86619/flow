import 'package:flutter/material.dart';

/// A self-contained shimmer placeholder. Wrap any size/shape with it.
///
/// Usage:
///   ShimmerBox(width: 135, height: 135, borderRadius: 14)
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFE0E0E0);
    final highlight = isDark ? const Color(0xFF2E2E42) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + _anim.value * 3, 0),
              end: Alignment(-0.5 + _anim.value * 3, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for a portrait song card (artwork + two text lines).
class SkeletonSongCard extends StatelessWidget {
  final double cardWidth;
  const SkeletonSongCard({super.key, this.cardWidth = 135});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: cardWidth,
            height: cardWidth,
            borderRadius: 14,
          ),
          const SizedBox(height: 8),
          ShimmerBox(width: cardWidth * 0.85, height: 12, borderRadius: 6),
          const SizedBox(height: 5),
          ShimmerBox(width: cardWidth * 0.6, height: 10, borderRadius: 6),
        ],
      ),
    );
  }
}

/// Skeleton for a quick-access tile (wide rect).
class SkeletonQuickAccessTile extends StatelessWidget {
  const SkeletonQuickAccessTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: double.infinity,
      height: double.infinity,
      borderRadius: 10,
    );
  }
}

/// Skeleton for a horizontal artist circle + label.
class SkeletonArtistCard extends StatelessWidget {
  const SkeletonArtistCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          ShimmerBox(width: 72, height: 72, borderRadius: 36),
          const SizedBox(height: 8),
          ShimmerBox(width: 60, height: 11, borderRadius: 6),
        ],
      ),
    );
  }
}
