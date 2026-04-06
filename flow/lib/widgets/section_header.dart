// ─────────────────────────────────────────────────────────────────────────────
// SectionHeader — reusable title + optional "See all" row.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A horizontal row with a bold section [title] on the left and an optional
/// "See all" [TextButton] on the right.
///
/// Pass [onSeeAll] to show the button; omit it to hide it.
///
/// Example:
/// ```dart
/// SectionHeader(
///   title: 'Listening Again',
///   onSeeAll: () => Navigator.push(...),
/// )
/// ```
class SectionHeader extends StatelessWidget {
  final String title;

  /// Called when "See all" is tapped. Pass `null` to hide the button entirely.
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See all',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}
