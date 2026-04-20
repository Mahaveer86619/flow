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
            ),
          if (icon != null && profileUrl == null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                icon,
                size: 20,
                color: colorScheme.primary.withAlpha(180),
              ),
            ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profileName != null)
                  Text(
                    profileName!,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withAlpha(140),
                    ),
                  )
                else if (subtitle != null)
                  Text(
                    subtitle!.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface.withAlpha(100),
                      letterSpacing: 1.0,
                    ),
                  ),
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: isSmall ? 20.0 : 24.0,
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
