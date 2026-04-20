// ─────────────────────────────────────────────────────────────────────────────
// AlbumArtWidget — shows a network thumbnail when available, otherwise falls
// back to the minimal 'f' placeholder.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class AlbumArtWidget extends StatelessWidget {
  /// Side length of the square artwork tile in logical pixels.
  final double size;
  final Color colorPrimary;
  final Color colorSecondary;

  /// Corner radius of the surrounding rounded rectangle.
  final double borderRadius;

  /// Remote thumbnail URL or local file path.
  final String? thumbnailUrl;

  const AlbumArtWidget({
    super.key,
    required this.size,
    required this.colorPrimary,
    required this.colorSecondary,
    this.borderRadius = 12,
    this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl != null) {
      final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: thumbnailUrl!.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: thumbnailUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.fill,
                  maxWidthDiskCache: cacheSize,
                  maxHeightDiskCache: cacheSize,
                  httpHeaders: const {
                    'User-Agent':
                        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
                  },
                  placeholder: (context, url) => _buildPlaceholder(),
                  errorWidget: (context, url, error) => _buildPlaceholder(),
                )
              : Image.file(
                  File(thumbnailUrl!),
                  width: size,
                  height: size,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(),
                ),
        ),
      );
    }
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorPrimary, colorSecondary],
        ),
      ),
      child: Center(
        child: Text(
          'f',
          style: GoogleFonts.spaceGrotesk(
            fontSize: size * 0.6,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
