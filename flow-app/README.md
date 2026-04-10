# Flow

A cross-platform music player built with Flutter. Responsive across mobile, tablet, and desktop with a full-featured player, home feed, search, and library. Backed by the Flow backend (`music-source/ytmusic-api`).

## Features

- **Home feed** — Quick Access grid, Listening Again, Forgotten Favorites, Music For You, Trending Artists
- **Search** — real-time search with 400 ms debounce, results from the backend
- **Library** — user playlists loaded from YouTube Music
- **Player** — full-screen on mobile, persistent sidebar on desktop; real album art
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
- **flutter_bloc ^9.1.1** — BLoC + Cubit state management
- **google_fonts ^6.2.1** — Outfit + Space Grotesk typefaces
- **flutter_dotenv ^5.2.1** — runtime environment config
- **http ^1.2.0** — REST API calls
- Material 3, seed color `#7C3AED` (purple), dark mode

## Getting Started

**Prerequisites:** Flutter SDK ≥ 3.11.4

```bash
cd flow
flutter pub get
flutter run
```

## Environment

Configure `flow/.env` before running:

```env
# URL of the running backend (no trailing slash)
API_BASE_URL=http://localhost:8000

# Set to true to skip the backend and use hard-coded mock data
USE_MOCK=false
```

To run against mock data without a backend:
```
USE_MOCK=true
```

## Backend API Contract

The app consumes the following endpoints from the backend:

### Songs

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/songs/feed` | Flat list of songs from the personalised home feed |
| `GET` | `/api/songs/search?q=<query>` | Song search results |
| `GET` | `/api/stream/<video_id>` | Proxied audio stream (range-request aware) |

**Normalised song shape:**
```json
{
  "id": "videoId",
  "title": "Song Title",
  "artist": "Artist Name",
  "album": "Album Name",
  "durationMs": 222000,
  "thumbnailUrl": "https://..."
}
```

### Playlists

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/library/playlists` | User's playlist metadata |
| `GET` | `/api/playlists/<id>/tracks` | Normalised track list for a playlist |
| `GET` | `/api/playlists/<id>` | Raw playlist detail (ytmusicapi format) |
| `POST` | `/api/playlists` | Create playlist |
| `PATCH` | `/api/playlists/<id>` | Edit playlist |
| `DELETE` | `/api/playlists/<id>` | Delete playlist |

**Normalised playlist shape:**
```json
{
  "id": "PLxxx",
  "name": "Playlist Name",
  "description": "25 songs",
  "thumbnailUrl": "https://...",
  "trackCount": 25
}
```

### Auth & misc

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/status` | Auth check |
| `POST` | `/api/auth` | Authenticate via raw headers or cURL |
| `DELETE` | `/api/auth` | Log out |
| `GET` | `/api/proxy-image?url=` | CORS-safe image proxy |
| `GET` | `/api/albums/<browse_id>` | Album detail |

## Architecture

```
lib/
├── main.dart                         # DI root — wires data source → repo → use cases → BLoC
├── domain/
│   ├── entities/song.dart            # Song, Playlist (pure Dart)
│   ├── repositories/song_repository.dart  # Abstract interface
│   └── usecases/                     # One class per operation
├── data/
│   ├── models/                       # DTOs with fromJson / toEntity()
│   ├── sources/
│   │   ├── song_data_source.dart     # Abstract interface
│   │   ├── api_song_data_source.dart # Hits the real backend  ← swap here
│   │   └── mock_song_data_source.dart
│   └── repositories/song_repository_impl.dart
└── presentation/
    ├── blocs/player/                 # PlayerBloc (events / state)
    ├── cubits/home|search|library/   # Feature cubits
    ├── screens/                      # One folder per screen
    └── widgets/                      # Shared UI components
```

**Swapping the data source:** change `USE_MOCK=true` in `.env` (no code change needed).

## Supported Platforms

Android, iOS, Windows, Linux, macOS, Web
