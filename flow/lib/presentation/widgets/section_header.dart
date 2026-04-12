// ─────────────────────────────────────────────────────────────────────────────
// SectionHeader — reusable title + optional "See all" row.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/responsive/breakpoints.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? profileUrl;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.profileUrl,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = Breakpoints.isMobile(MediaQuery.sizeOf(context).width);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (profileUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(profileUrl!),
                backgroundColor: colorScheme.surfaceContainerHigh,
              ),
            )
          else if (subtitle != null)
            const SizedBox.shrink(), // Space for logic if needed

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(
                    subtitle!.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface.withAlpha(120),
                      letterSpacing: 0.5,
                    ),
                  ),
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: isSmall ? 22.0 : 26.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  'See all',
                  style: GoogleFonts.outfit(
                    color: colorScheme.primary,
                    fontSize: isSmall ? 13.0 : 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
