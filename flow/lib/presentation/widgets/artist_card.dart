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
class ArtistCard extends StatefulWidget {
  final Map<String, dynamic> artist;
  final VoidCallback? onTap;
  final double cardSize;

  const ArtistCard({
    super.key,
    required this.artist,
    this.onTap,
    this.cardSize = 100,
  });

  @override
  State<ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<ArtistCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.artist['name'] as String;
    final primary = widget.artist['colorPrimary'] as Color;
    final secondary = widget.artist['colorSecondary'] as Color;
    final thumbnailUrl = widget.artist['thumbnailUrl'] as String?;

    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.cardSize,
          child: Column(
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: widget.cardSize,
                  height: widget.cardSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(_isHovered ? 60 : 40),
                        blurRadius: _isHovered ? 20 : 12,
                        offset: Offset(0, _isHovered ? 8 : 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: thumbnailUrl != null
                        ? Image.network(
                            thumbnailUrl,
                            width: widget.cardSize,
                            height: widget.cardSize,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _Initials(
                                  size: widget.cardSize,
                                  initials: initials,
                                  primary: primary,
                                  secondary: secondary,
                                ),
                          )
                        : _Initials(
                            size: widget.cardSize,
                            initials: initials,
                            primary: primary,
                            secondary: secondary,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ),
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
