# flow

A cross-platform music streaming app built with Flutter, targeting Android and desktop (Windows/Linux/macOS).

---

## Architecture — MVVM

The project follows the **Model–View–ViewModel** pattern using Flutter's `provider` package for dependency injection and reactive state management.

```
┌──────────┐   notifyListeners   ┌──────────────┐     fetches     ┌────────────┐
│   View   │ ◀─────────────────  │  ViewModel   │ ──────────────▶ │ Repository │
│ (Widget) │ ─────────────────▶  │ (ChangeNtfr) │ ◀────────────── │ (abstract) │
└──────────┘   calls methods     └──────────────┘   data models   └────────────┘
```

| Layer | Responsibility | Location |
|---|---|---|
| **Model** | Plain data classes (no logic) | `lib/models/` |
| **Repository** | Data access contract + implementations | `lib/repositories/` |
| **ViewModel** | Business logic, state, commands | `lib/viewmodels/` |
| **View** | Flutter widgets — render state, forward events | `lib/screens/`, `lib/widgets/` |

### Key rules
- Views only call ViewModel methods or read ViewModel properties — no business logic in widgets.
- ViewModels depend on Repositories, never on Flutter widgets or `BuildContext`.
- The Repository is an abstract interface; swap `MockSongRepository` for a real API implementation without touching any ViewModel or View.

---

## Project structure

```
lib/
├── main.dart                          # App entry, MultiProvider setup, theme
│
├── models/
│   └── song.dart                      # Song, Playlist data classes
│
├── repositories/
│   ├── song_repository.dart           # Abstract interface
│   └── mock_song_repository.dart      # In-memory implementation (swap for real API)
│
├── viewmodels/
│   ├── player_viewmodel.dart          # Playback state: song, queue, progress, liked, volume
│   ├── home_viewmodel.dart            # Home screen data: greeting, featured, song rows
│   ├── search_viewmodel.dart          # Search query state and filtered results
│   └── library_viewmodel.dart        # Library filter tab and playlist list
│
├── screens/
│   ├── splash_screen.dart             # Animated splash → MainScreen
│   ├── main_screen.dart               # AppBar + bottom nav shell + bottom sheets
│   ├── home_screen.dart               # Home tab (pure View)
│   ├── search_screen.dart             # Search tab (holds TextEditingController as UI state)
│   ├── library_screen.dart            # Library tab (pure View)
│   └── player_screen.dart             # Full-screen music player
│
└── widgets/
    ├── squiggly_progress_bar.dart     # Animated sine-wave seek bar (CustomPainter)
    └── mini_player.dart               # Persistent mini player above bottom nav
```

---

## Features

- **Splash screen** — "flow" logo with fade + scale animation, tagline subtitle
- **Bottom navigation** — Home · Search · Library with Material 3 NavigationBar
- **AppBar actions** — Notifications, Recently Played, Settings (modal bottom sheets)
- **Home** — Time-aware greeting, quick-access grid, featured card, horizontal song rows
- **Search** — Live filtering across title / artist / album; genre category grid
- **Library** — Animated filter chips, Liked Songs count, playlist list
- **Player** — Full-screen with per-song gradient background, playback controls, volume
- **Squiggly progress bar** — Animated sine wave; played half in primary color; tap/drag to seek
- **Mini player** — Shown above the nav bar when a song is playing; thin progress line at base

---

## Design

| Token | Value |
|---|---|
| Seed color | `#7C3AED` (vivid violet) |
| Design system | Material 3 (`useMaterial3: true`) |
| Default theme | Dark |
| Logo / heading font | Space Grotesk ExtraBold |
| Body font | Outfit |

---

## Getting started

### Prerequisites

- Flutter SDK ≥ 3.27 (project uses Flutter 3.41.6 stable)
- Android SDK for Android target
- Windows Developer Mode enabled for Windows desktop target (required for symlinks)

### Run

```bash
flutter pub get
flutter run                  # picks connected device / emulator
flutter run -d windows       # Windows desktop
flutter run -d linux         # Linux desktop
```

### Replacing the mock data source

1. Implement `SongRepository` in a new class:
   ```dart
   class ApiSongRepository implements SongRepository {
     @override
     List<Song> getSongs() { /* fetch from API */ }
     // ...
   }
   ```
2. In `lib/main.dart`, replace `MockSongRepository()` with your implementation:
   ```dart
   final SongRepository songRepo = ApiSongRepository();
   ```
3. No ViewModel or View code needs to change.
