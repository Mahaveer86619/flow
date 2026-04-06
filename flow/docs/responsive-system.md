# Responsive System

## Overview

Flow has two distinct layout shells selected by screen width. The selection happens once at startup (in `_RootShell`) and re-evaluates live if the window is resized.

## Breakpoints

**File:** `lib/core/responsive/breakpoints.dart`

```
Mobile   width < 700 px
Tablet   700 px ≤ width < 1100 px   (same shell as mobile)
Desktop  width ≥ 1100 px
```

All three constants are in one place — change them there and every layout decision updates automatically.

```dart
// Check anywhere in the widget tree:
final width = MediaQuery.sizeOf(context).width;
if (Breakpoints.isDesktop(width)) { ... }
```

## ResponsiveLayout widget

**File:** `lib/core/responsive/responsive_layout.dart`

A widget that calls one of three builders based on the current width:

```dart
ResponsiveLayout(
  mobile:  (_) => const MainScreen(),
  // tablet: omit to fall back to mobile
  desktop: (_) => const DesktopShell(),
)
```

Used in `_RootShell` (at the bottom of `splash_screen.dart`) — the first real screen after the splash animation.

## Mobile shell (`MainScreen`)

**File:** `lib/screens/main_screen.dart`

```
Scaffold
  AppBar  ─── "flow" title | notifications | history | settings
  Body    ─── IndexedStack (Home / Search / Library)
           └─ MiniPlayer   (shown when song is loaded)
  BottomNavigationBar
```

- `MiniPlayer` sits above the `BottomNavigationBar` inside the `Body` column
- Tapping `MiniPlayer` pushes `PlayerScreen` as a full-screen route
- Notifications, history, and settings open as `showModalBottomSheet` panels

## Desktop shell (`DesktopShell`)

**File:** `lib/screens/desktop_shell.dart`

```
Scaffold
  Row
    NavigationRail (72 px)
      leading  : app logo "f"
      body     : Home / Search / Library destinations
      trailing : notification + settings icons (pinned to bottom)
    VerticalDivider
    Column (Expanded)
      _DesktopTopBar (56 px)  : "flow" title + recently played
      IndexedStack             : Home / Search / Library
    VerticalDivider
    _PlayerSidebar (340 px)
      PlayerPanel
```

- No `MiniPlayer`, no `BottomNavigationBar`
- History and settings open as `AlertDialog` (more appropriate for desktop)
- Player sidebar is always rendered; shows `_EmptyPlayerPanel` when nothing plays

### Sidebar width

Change one constant in `_PlayerSidebar`:
```dart
static const double _panelWidth = 340; // adjust here
```

## How song taps work across layouts

`SongCard` (and other tappable song widgets) check the current width before navigating:

```dart
void _handleTap(BuildContext context) {
  context.read<PlayerCubit>().playQueue(queue, startIndex: index);

  if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const PlayerScreen(),
    ));
  }
  // On desktop: cubit emits new state → PlayerPanel rebuilds automatically
}
```

This pattern is replicated in: `SongCard`, `_QuickAccessTile`, `_MusicForYouGrid`, `_ResultTile`.

## Tablet behaviour

Tablets (700–1099 px) use the mobile shell. The content has more horizontal breathing room naturally because `CustomScrollView` and `ListView` expand to fill width, but the navigation and player experience are identical to mobile.

To add a distinct tablet layout later:
1. Create a `TabletShell` (e.g. a 2-pane split without the full player sidebar)
2. Pass it as the `tablet` builder in `ResponsiveLayout`

## Adding a new breakpoint

1. Add the constant to `Breakpoints`
2. Add a builder param to `ResponsiveLayout`
3. Create the new shell widget
4. Pass it in `_RootShell`
