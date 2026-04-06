// ─────────────────────────────────────────────────────────────────────────────
// ArtistCard — square gradient card showing an artist name + initials.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A square card used in the "Trending Artists" horizontal list.
///
/// The [artist] map must contain:
///   - `'name'`           → String
///   - `'colorPrimary'`   → Color
///   - `'colorSecondary'` → Color
///
/// ── Replacing with real artwork ─────────────────────────────────────────────
/// When your backend provides artist profile-picture URLs, replace the
/// initials [Text] widget with:
///
///   ClipRRect(
///     borderRadius: BorderRadius.circular(16),
///     child: Image.network(artist['imageUrl'], fit: BoxFit.cover),
///   )
/// ────────────────────────────────────────────────────────────────────────────
class ArtistCard extends StatelessWidget {
  final Map<String, dynamic> artist;
  final VoidCallback? onTap;

  /// Width and height of the square artwork tile.
  final double cardSize;

  const ArtistCard({
    super.key,
    required this.artist,
    this.onTap,
    this.cardSize = 110,
  });

  @override
  Widget build(BuildContext context) {
    final name = artist['name'] as String;
    final primary = artist['colorPrimary'] as Color;
    final secondary = artist['colorSecondary'] as Color;

    // Build initials (up to 2 characters) from the artist name words.
    final initials = name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join();

    return SizedBox(
      width: cardSize,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            // ── Artwork tile ────────────────────────────────────────────────────
            // Replace this Container with Image.network() when artwork is ready.
            Container(
              width: cardSize,
              height: cardSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, secondary],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: cardSize * 0.26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withAlpha(220),
                ),
              ),
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
