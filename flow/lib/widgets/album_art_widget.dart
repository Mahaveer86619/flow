// ─────────────────────────────────────────────────────────────────────────────
// AlbumArtWidget — vinyl-style album art placeholder.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// Renders a square vinyl-record–style artwork tile.
///
/// Concentric rings over a gradient background mimic a physical record.
/// The center hub shows a music note.
///
/// ── Replacing with real artwork ─────────────────────────────────────────────
/// When your backend provides artwork URLs, replace the [Stack] body with:
///
///   ClipRRect(
///     borderRadius: BorderRadius.circular(borderRadius),
///     child: Image.network(
///       artworkUrl,
///       width: size, height: size,
///       fit: BoxFit.cover,
///       // Optionally keep the gradient as a loadingBuilder fallback:
///       loadingBuilder: (_, child, progress) =>
///           progress == null ? child : _PlaceholderRings(size: size, ...),
///     ),
///   )
/// ────────────────────────────────────────────────────────────────────────────
class AlbumArtWidget extends StatelessWidget {
  /// Side length of the square artwork tile in logical pixels.
  final double size;
  final Color colorPrimary;
  final Color colorSecondary;

  /// Corner radius of the surrounding rounded rectangle.
  final double borderRadius;

  const AlbumArtWidget({
    super.key,
    required this.size,
    required this.colorPrimary,
    required this.colorSecondary,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
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
          // Decorative highlight bubble (top-right corner)
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
          // Outer vinyl ring
          Container(
            width: size * 0.78,
            height: size * 0.78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withAlpha(20),
              border: Border.all(
                color: Colors.white.withAlpha(18),
                width: 1.5,
              ),
            ),
          ),
          // Middle vinyl ring
          Container(
            width: size * 0.52,
            height: size * 0.52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withAlpha(40),
              border: Border.all(
                color: Colors.white.withAlpha(14),
                width: 1,
              ),
            ),
          ),
          // Center hub with music note icon
          Container(
            width: size * 0.26,
            height: size * 0.26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withAlpha(60),
              border: Border.all(
                color: Colors.white.withAlpha(30),
                width: 1,
              ),
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
