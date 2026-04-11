// ─────────────────────────────────────────────────────────────────────────────
// SectionHeader — reusable title + optional "See all" row.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/responsive/breakpoints.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final isSmall = Breakpoints.isMobile(MediaQuery.sizeOf(context).width);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: isSmall ? 20.0 : 24.0,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
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
    );
  }
}
