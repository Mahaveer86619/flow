// ─────────────────────────────────────────────────────────────────────────────
// Responsive breakpoints for Flow.
//
// All layout decisions reference these constants — changing a threshold here
// automatically updates every widget that uses [Breakpoints].
//
// Layout matrix:
//   Mobile  (<  700 px)  → BottomNavigationBar shell + MiniPlayer overlay
//                           Full-screen PlayerScreen on song tap
//   Tablet  (700–1099)   → Same mobile shell with more horizontal whitespace
//   Desktop (≥ 1100 px)  → NavigationRail + content pane + player sidebar
//
// To change the desktop breakpoint, update [desktop] below.
// ─────────────────────────────────────────────────────────────────────────────

/// Screen-size breakpoints used to switch between the mobile and desktop shells.
class Breakpoints {
  Breakpoints._(); // static-only utility class

  /// Width below which the mobile shell (BottomNav + MiniPlayer) is rendered.
  static const double tablet = 700;

  /// Width at or above which the desktop shell (NavigationRail + player panel)
  /// is rendered.
  static const double desktop = 1100;

  /// Returns true for screens narrower than [tablet].
  static bool isMobile(double width) => width < tablet;

  /// Returns true for tablet-range screens (between [tablet] and [desktop]).
  static bool isTablet(double width) => width >= tablet && width < desktop;

  /// Returns true when the desktop shell should be shown.
  /// On desktop, the player is a permanent right-side panel — [PlayerScreen]
  /// is not pushed as a route.
  static bool isDesktop(double width) => width >= desktop;
}
