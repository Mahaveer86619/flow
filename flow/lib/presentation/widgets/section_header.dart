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
  final String? profileName;
  final IconData? icon;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.profileUrl,
    this.profileName,
    this.icon,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = Breakpoints.isMobile(MediaQuery.sizeOf(context).width);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 4),
              child: Icon(icon, size: 22, color: colorScheme.primary),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subtitle != null)
                  Text(
                    subtitle!.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface.withAlpha(100),
                      letterSpacing: 1.5,
                    ),
                  ),
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: isSmall ? 22.0 : 28.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          if (onSeeAll != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: onSeeAll,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    'See all',
                    style: GoogleFonts.outfit(
                      color: colorScheme.primary,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
