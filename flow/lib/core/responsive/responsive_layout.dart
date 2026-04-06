// ─────────────────────────────────────────────────────────────────────────────
// ResponsiveLayout — widget that picks a builder based on screen width.
//
// Usage:
//   ResponsiveLayout(
//     mobile:  (_) => const MobileShell(),
//     desktop: (_) => const DesktopShell(),
//   )
//
// The optional [tablet] builder falls back to [mobile] when omitted.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/widgets.dart';
import 'breakpoints.dart';

/// Conditionally renders one of [mobile], [tablet], or [desktop] based on
/// [MediaQuery] width and [Breakpoints] thresholds.
class ResponsiveLayout extends StatelessWidget {
  /// Builder for mobile widths (< [Breakpoints.tablet]).
  final WidgetBuilder mobile;

  /// Optional builder for tablet widths ([Breakpoints.tablet] – [Breakpoints.desktop]).
  /// Falls back to [mobile] when null.
  final WidgetBuilder? tablet;

  /// Builder for desktop widths (≥ [Breakpoints.desktop]).
  final WidgetBuilder desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (Breakpoints.isDesktop(width)) return desktop(context);
    if (tablet != null && Breakpoints.isTablet(width)) return tablet!(context);
    return mobile(context);
  }
}
