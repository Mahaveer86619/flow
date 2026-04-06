# Project Structure

## Full file tree

```
flow/
├── CLAUDE.md                          # AI development context (read first)
├── README.md
├── pubspec.yaml                       # Flutter deps: flutter_bloc, google_fonts
├── analysis_options.yaml
│
├── docs/                              # ← you are here
│   ├── project-structure.md          # this file
│   ├── architecture.md               # system design, startup flow, DI
│   ├── state-management.md           # Cubit API reference
│   ├── responsive-system.md          # breakpoints, shell selection
│   ├── ui-components.md              # widget catalog + replacement guides
│   ├── data-layer.md                 # models, repository pattern, data flow
│   └── extension-guide.md           # how to add audio, API, auth, etc.
│
├── lib/
│   ├── main.dart                      # Entry point, DI setup, theme
│   ├── player_controller.dart         # LEGACY — unused, ignore
│   │
│   ├── core/
│   │   └── responsive/
│   │       ├── breakpoints.dart       # Mobile/tablet/desktop thresholds
│   │       └── responsive_layout.dart # Widget that picks a builder by width
│   │
│   ├── models/
│   │   └── song.dart                  # Song, Playlist value objects
│   │
│   ├── repositories/
│   │   ├── song_repository.dart       # Abstract interface (never import concrete)
│   │   └── mock_song_repository.dart  # 8 songs, 4 playlists, 10 categories
│   │
│   ├── data/
│   │   └── mock_data.dart             # Raw constants used only by MockSongRepository
│   │
│   ├── cubits/
│   │   ├── player_cubit.dart          # PlayerState + PlayerCubit (playback, queue, likes)
│   │   ├── home_cubit.dart            # HomeState + HomeCubit (feed sections)
│   │   ├── search_cubit.dart          # SearchState + SearchCubit (query, history)
│   │   └── library_cubit.dart         # LibraryState + LibraryCubit (playlists, filter)
│   │
│   ├── screens/
│   │   ├── splash_screen.dart         # Animated intro + _RootShell (layout selector)
│   │   ├── main_screen.dart           # Mobile shell: bottom nav + MiniPlayer
│   │   ├── desktop_shell.dart         # Desktop shell: rail + content + player sidebar
│   │   ├── home_screen.dart           # Scrollable feed (5 sections)
│   │   ├── search_screen.dart         # Search bar + categories / results / history
│   │   ├── library_screen.dart        # Playlists + liked songs
│   │   └── player_screen.dart         # Mobile full-screen player (wraps PlayerPanel)
│   │
│   ├── widgets/
│   │   ├── player_panel.dart          # Full player UI — shared by mobile + desktop
│   │   ├── album_art_widget.dart      # Vinyl-style artwork placeholder
│   │   ├── song_card.dart             # Portrait card for horizontal song lists
│   │   ├── artist_card.dart           # Square artist card with initials
│   │   ├── section_header.dart        # Title + "See all" row
│   │   ├── mini_player.dart           # Compact bottom player (mobile only)
│   │   └── squiggly_progress_bar.dart # Animated sine-wave seek bar
│   │
│   └── viewmodels/                    # LEGACY — unused ChangeNotifier files
│       ├── home_viewmodel.dart
│       ├── library_viewmodel.dart
│       ├── player_viewmodel.dart
│       └── search_viewmodel.dart
│
├── android/                           # Android project files
│   └── app/src/main/AndroidManifest.xml
│
├── ios/                               # iOS project files
│
└── test/
    └── widget_test.dart               # Default Flutter test stub
```

## Dependency graph

```
main.dart
  ├── SongRepository (abstract)
  │     └── MockSongRepository ← swap here for real API
  │
  ├── PlayerCubit (no repo dependency — manages audio queue + state)
  ├── HomeCubit   → SongRepository
  ├── SearchCubit → SongRepository
  └── LibraryCubit → SongRepository

screens/splash_screen.dart
  └── _RootShell
        └── ResponsiveLayout (core/responsive)
              ├── mobile  → MainScreen
              └── desktop → DesktopShell

screens/main_screen.dart (mobile)
  ├── IndexedStack: HomeScreen | SearchScreen | LibraryScreen
  ├── MiniPlayer
  └── BottomNavigationBar

screens/desktop_shell.dart (desktop)
  ├── _DesktopNavRail
  ├── IndexedStack: HomeScreen | SearchScreen | LibraryScreen
  └── _PlayerSidebar → PlayerPanel

widgets/player_panel.dart
  ├── AlbumArtWidget
  └── SquigglyProgressBar

widgets/song_card.dart
  └── PlayerScreen (navigation, mobile only)

screens/player_screen.dart (mobile only)
  └── PlayerPanel
```

## Key constants

| Constant | Location | Value |
|----------|----------|-------|
| Desktop breakpoint | `Breakpoints.desktop` | 1100 px |
| Tablet breakpoint | `Breakpoints.tablet` | 700 px |
| Player sidebar width | `_PlayerSidebar._panelWidth` | 340 px |
| Theme seed color | `FlowApp._buildTheme` | `0xFF7C3AED` |
| Progress tick rate | `PlayerCubit._startTimer` | 500 ms |
| Recent search max | `SearchCubit.addRecentSearch` | 8 items |
| Recently played max | `PlayerCubit._playSong` | 20 items |

## Package versions

```yaml
flutter_bloc: ^8.1.6   # Cubit + BlocProvider
google_fonts: ^6.2.1   # Outfit + Space Grotesk
cupertino_icons: ^1.0.8
```

Flutter SDK: `^3.11.4` (Dart sound null safety required)

## Platform targets

| Platform | Status |
|----------|--------|
| Android | Configured (`AndroidManifest.xml` present) |
| iOS | Configured (Runner xcodeproj present) |
| Windows desktop | Works (Flutter desktop support) |
| macOS / Linux | Untested, but no platform-specific code |
| Web | Should work, not tested |
