# Flow (Mobile & Desktop)

A cross-platform music streaming client built with Flutter. It provides a seamless experience for browsing and playing music from YouTube Music, with a focus on high-quality audio and a polished user interface.

## Key Features

- **Personalized Home Feed:** Quick Access, Listening Again, Forgotten Favorites, and curated music for you.
- **Advanced Search:** Real-time search for songs, artists, and albums with history and category browsing.
- **Full Library Management:** Access and manage your YouTube Music playlists directly in the app.
- **Immersive Player:** Features a unique squiggly progress bar, dynamic color palette extraction from album art, and cross-platform playback.
- **Desktop Excellence:** Integrated Windows System Media Transport Controls (SMTC) for media key support and a persistent sidebar layout for larger screens.
- **Cross-Platform:** Responsive layouts for Mobile (Android/iOS) and Desktop (Windows/macOS/Linux).
- **Security:** JWT-based user authentication and secure per-user account linking.

## Tech Stack

- **Framework:** Flutter (Dart SDK ^3.11.4)
- **State Management:** `flutter_bloc` (BLoC + Cubit)
- **Audio Engine:** `just_audio` with background playback support.
- **Storage:** `hive_flutter` for high-performance persistent local data.
- **Networking:** `http` for RESTful communication with the backend.
- **Design:** Material 3 with customized typography (Outfit & Space Grotesk).

## Getting Started

### 1. Prerequisites
- Flutter SDK ≥ 3.11.4
- A running instance of the [Flow Backend](../flow-source/)

### 2. Installation
```bash
cd flow
flutter pub get
```

### 3. Environment Configuration
Create a `flow/.env` file:
```env
# URL of your running backend (e.g., http://localhost:8000)
API_BASE_URL=http://localhost:8000

# Optional: Set to true to use static mock data instead of the API
USE_MOCK=false

# Optional: Enable verbose logging
DEBUG=true
```

### 4. Run the App
```bash
flutter run
```

## Architecture

The app follows a clean architecture pattern with a clear separation of concerns:

- `lib/core/`: Foundation logic including authentication, network monitoring, and local storage.
- `lib/domain/`: Pure business logic, entities, and repository interfaces.
- `lib/data/`: Data source implementations (API/Mock) and model serialization.
- `lib/presentation/`: UI components, screens, and state management (BLoCs/Cubits).

## Backend Integration

The app connects to the Flow API via the following core endpoints:
- **Authentication:** `/v1/auth/*`
- **Browsing:** `/v1/home`, `/v1/feed`
- **Library:** `/v1/library`, `/v1/playlists/*`
- **Playback:** `/v1/stream/{id}` (Audio proxy), `/v1/proxy-image` (Image proxy)

## Supported Platforms
- **Android / iOS:** Full mobile experience with mini-player and full-screen player.
- **Windows:** Supports media keys and system tray integration via SMTC.
- **macOS / Linux / Web:** Fully responsive layout support.
