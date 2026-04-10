// ─────────────────────────────────────────────────────────────────────────────
// ArtistCard — shows artist thumbnail when available, initials fallback.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A square card used in the "Trending Artists" horizontal list.
///
/// The [artist] map must contain:
///   - `'name'`           → String
///   - `'colorPrimary'`   → Color   (gradient fallback)
///   - `'colorSecondary'` → Color   (gradient fallback)
///   - `'thumbnailUrl'`   → String? (shown when non-null)
class ArtistCard extends StatelessWidget {
  final Map<String, dynamic> artist;
  final VoidCallback? onTap;
  final double cardSize;

  const ArtistCard({
    super.key,
    required this.artist,
    this.onTap,
    this.cardSize = 110,
  });

  @override
  Widget build(BuildContext context) {
    final name         = artist['name'] as String;
    final primary      = artist['colorPrimary'] as Color;
    final secondary    = artist['colorSecondary'] as Color;
    final thumbnailUrl = artist['thumbnailUrl'] as String?;

    final initials =
        name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();

    return SizedBox(
      width: cardSize,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            // ── Artwork tile ─────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: thumbnailUrl != null
                  ? Image.network(
                      thumbnailUrl,
                      width: cardSize,
                      height: cardSize,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _Initials(size: cardSize, initials: initials,
                              primary: primary, secondary: secondary),
                    )
                  : _Initials(size: cardSize, initials: initials,
                        primary: primary, secondary: secondary),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final double size;
  final String initials;
  final Color primary;
  final Color secondary;
  const _Initials({
    required this.size,
    required this.initials,
    required this.primary,
    required this.secondary,
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
          colors: [primary, secondary],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.spaceGrotesk(
          fontSize: size * 0.26,
          fontWeight: FontWeight.w800,
          color: Colors.white.withAlpha(220),
        ),
      ),
    );
  }
}
