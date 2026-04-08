# Flow

A cross-platform music player built with Flutter. Responsive across mobile, tablet, and desktop with a full-featured player, home feed, search, and library.

## Features

- **Home feed** — Quick Access grid, Listening Again, Forgotten Favorites, Music For You, Trending Artists
- **Search** — filter by songs, albums, artists
- **Library** — playlists and saved music
- **Player** — full-screen on mobile, persistent sidebar on desktop
- **Queue** — reorderable playback queue
- **Responsive layout** — three distinct shells based on screen width

## Responsive Layout

| Breakpoint | Shell |
|---|---|
| `< 700 px` (mobile) | Bottom navigation bar + mini-player overlay + full-screen player |
| `700–1099 px` (tablet) | Same as mobile with wider content |
| `≥ 1100 px` (desktop) | Navigation rail + content pane + permanent right-side player panel |

## Tech Stack

- **Flutter** (Dart SDK ^3.11.4)
- **flutter_bloc ^9.1.1** — state management via Cubits
- **google_fonts ^6.2.1** — Outfit + Space Grotesk typefaces
- **flutter_dotenv ^5.2.1** — runtime environment config
- Material 3 with a custom purple seed color (`#7C3AED`), dark mode

## Project Structure

```
lib/
├── main.dart                      # App entry point, DI setup
├── models/
│   └── song.dart                  # Song, Playlist models
├── repositories/
│   ├── song_repository.dart       # Abstract interface
│   └── mock_song_repository.dart  # Mock implementation (swap for real API)
├── cubits/                        # BLoC state management
│   ├── player_cubit.dart          # Playback state, queue, progress
│   ├── home_cubit.dart            # Home feed data
│   ├── search_cubit.dart          # Search results
│   └── library_cubit.dart         # Library contents
├── screens/
│   ├── main/                      # Root shell (mobile + desktop)
│   ├── home/                      # Home feed
│   ├── search/                    # Search
│   ├── library/                   # Library
│   ├── player/                    # Full-screen player (mobile)
│   ├── queue/                     # Playback queue
│   ├── playlist/                  # Playlist detail
│   ├── artist/                    # Artist detail
│   ├── list/                      # Generic song list
│   └── splash/                    # Splash screen
├── widgets/
│   ├── mini_player.dart           # Collapsed player bar (mobile)
│   ├── player_panel.dart          # Shared player UI (mobile + desktop sidebar)
│   ├── song_card.dart             # Song tile used across feed sections
│   ├── artist_card.dart           # Artist tile
│   ├── album_art_widget.dart      # Artwork display
│   ├── squiggly_progress_bar.dart # Custom seek bar
│   └── section_header.dart        # "See all" row header
└── core/
    └── responsive/
        ├── breakpoints.dart       # Screen-width thresholds
        └── responsive_layout.dart
```

## Getting Started

**Prerequisites:** Flutter SDK ≥ 3.11.4

```bash
flutter pub get
flutter run
```

To run on a specific platform:
```bash
flutter run -d windows
flutter run -d android
flutter run -d chrome
```

## Connecting to the Backend

The app currently uses `MockSongRepository`. To connect to the live backend, implement `SongRepository` against the `ytmusic-api` server and swap it in `main.dart`:

```dart
// main.dart
RepositoryProvider<SongRepository>(
  create: (_) => ApiSongRepository(baseUrl: 'http://localhost:8000'),
  // was: MockSongRepository()
```

See the root [`README.md`](../README.md) for backend setup.

## Environment

Create a `.env` file in the `flow/` directory (it is bundled as a Flutter asset):

```
API_BASE_URL=http://localhost:8000
```

## Supported Platforms

Android, iOS, Windows, Linux, macOS, Web
