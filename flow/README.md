# Flow App — The Premium Standalone Music Client 💎

Flow App is a high-performance, cross-platform music streaming client built with Flutter. It provides an immersive experience by resolving streams and fetching metadata directly on your device, eliminating the need for a custom backend.

---

## ✨ Features That Shine

- **🎨 Dynamic Material 3 UI:** Automatically extracts colors from album art for a truly personal interface.
- **〰️ Squiggly Progress Bar:** A unique, playful player UI for a more expressive experience.
- **🎼 Full Media Controls:** Support for background playback and system media keys (SMTC on Windows).
- **🚀 Instant Playback:** Optimized for fast starting and seamless track transitions using on-device stream resolution.
- **📱 Responsive Layout:** Perfectly adapted for mobile, tablet, and desktop screens.
- **🔄 Local First:** Playback history, preferences, and downloaded tracks are stored securely on your device.

---

## 🏗️ Technical Stack

- **Flutter & Dart:** For cross-platform high-performance rendering.
- **BLoC & Cubit:** Predictable state management for a smooth UX.
- **just_audio:** A powerful audio engine for background playback and streaming.
- **youtube_explode_dart:** Direct resolution of high-quality YouTube audio streams.
- **Hive:** Blazing-fast local storage for user preferences and playback history.
- **Dio:** For efficient API interaction with YouTube Music's internal endpoints.

---

## 🚀 Getting Started

### 1. Prerequisites

Ensure you have the following installed:
- **Flutter SDK:** (Check your current version with `flutter --version`)
- **Android Studio / Xcode / VS Code:** Configured for Flutter development.

### 2. Configure Your Environment

The app is now standalone, but you can still use a `.env` file for debugging and optional settings.

1.  Navigate to the `flow` directory: `cd flow`
2.  Create a `.env` file (see `.env.example`):
    ```env
    # App Information:
    APP_VERSION=1.0.0

    # Debug Options:
    USE_MOCK=false
    DEBUG=true
    ```

### 3. Build and Run

#### 🖥️ Desktop (Windows / macOS / Linux)
```bash
flutter pub get
flutter run -d windows  # or 'macos', 'linux'
```

#### 📱 Mobile (Android / iOS)
```bash
flutter pub get
flutter run
```

---

## 📖 Technical Documentation

For in-depth details on the standalone architecture, direct source extraction logic, and performance optimizations, see the [Architecture Milestones](./docs/architecture/milestones.md).

---

## 🏗️ Architecture

Flow App follows a strict **Clean Architecture** pattern to ensure maintainability as a standalone entity:

- `lib/core/`: Foundation logic, local storage, logger, and network clients.
- `lib/domain/`: Business logic, pure entities, and repository interfaces.
- `lib/data/`: Data sources (YouTube Music direct scrapers, local storage) and repository implementations.
- `lib/presentation/`: UI layer containing Screens, reusable Widgets, and BLoC/Cubit state management.

---

## 🛡️ Standalone Implementation Details

- **Stream Resolution:** Uses `StreamResolver` to fetch direct `.m4a` or `.webm` links from YouTube, bypassing the need for a proxy server.
- **Metadata:** `YoutubeDataSource` communicates directly with YouTube Music's internal API to provide home feeds, search results, and radio suggestions.
- **Auth:** Authentication is handled by persisting YouTube Music session cookies locally in encrypted storage.
- **Windows SMTC:** Deep integration with `smtc_windows` to provide a native feel on the Windows desktop, including taskbar thumbnails and media key support.

---

## 📈 Future Goals

1.  **Direct YTM Login:** Integrated webview for easier session cookie extraction.
2.  **Spotify Hybrid Mode:** Fetch playlist metadata from Spotify while playing audio from YouTube.
3.  **Local Audio Playback:** Integration of on-device MP3/FLAC files into the Flow library.
4. **Audio EQ:** Built-in equalizer and bass boost settings.

---

## 🛠️ Development & Debugging

For testing and debugging data extraction from YouTube Music:

- **Isolated Tests:** All JSON dumps and debugging scripts are located in the `bin/` directory.
- **Dumps:** `bin/*.json` contains raw responses from YTM API for various queries (Search, Home, etc.).
- **Scripts:** `bin/*.dart` are standalone scripts to test parsing logic without running the full Flutter app.
- **Ignored:** The `bin/` directory is ignored by git to keep the repository clean and avoid committing large data dumps.

---

<p align="center">Pure sound, pure flow. 🎵</p>
