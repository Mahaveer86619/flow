// ─────────────────────────────────────────────────────────────────────────────
// AlbumArtWidget — shows a network thumbnail when available, otherwise falls
// back to the vinyl-style gradient placeholder.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class AlbumArtWidget extends StatelessWidget {
  /// Side length of the square artwork tile in logical pixels.
  final double size;
  final Color colorPrimary;
  final Color colorSecondary;

  /// Corner radius of the surrounding rounded rectangle.
  final double borderRadius;

  /// Remote thumbnail URL. When non-null, a network image is shown instead of
  /// the gradient placeholder. Falls back to the placeholder on error.
  final String? thumbnailUrl;

  const AlbumArtWidget({
    super.key,
    required this.size,
    required this.colorPrimary,
    required this.colorSecondary,
    this.borderRadius = 24,
    this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          thumbnailUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _buildVinyl(),
          errorBuilder: (context, error, stackTrace) => _buildVinyl(),
        ),
      );
    }
    return _buildVinyl();
  }

  Widget _buildVinyl() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorPrimary, colorSecondary],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: colorPrimary.withAlpha(100),
            blurRadius: 50,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: size * 0.06,
            top: size * 0.06,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(14),
              ),
            ),
          ),
          Container(
            width: size * 0.78,
            height: size * 0.78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withAlpha(20),
              border: Border.all(color: Colors.white.withAlpha(18), width: 1.5),
            ),
          ),
          Container(
            width: size * 0.52,
            height: size * 0.52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withAlpha(40),
              border: Border.all(color: Colors.white.withAlpha(14), width: 1),
            ),
          ),
          Container(
            width: size * 0.26,
            height: size * 0.26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withAlpha(60),
              border: Border.all(color: Colors.white.withAlpha(30), width: 1),
            ),
            child: Icon(
              Icons.music_note_rounded,
              size: size * 0.13,
              color: Colors.white.withAlpha(210),
            ),
          ),
        ],
      ),
    );
  }
}
