# Flow App — The Premium Music Client 💎

Flow App is a high-performance, cross-platform music streaming client built with Flutter. It provides an immersive experience with deep integration into your Flow Source backend.

---

## ✨ Features That Shine

- **🎨 Dynamic Material 3 UI:** Automatically extracts colors from album art for a truly personal interface.
- **〰️ Squiggly Progress Bar:** A unique, playful player UI for a more expressive experience.
- **🎼 Full Media Controls:** Support for background playback and system media keys (SMTC on Windows).
- **🚀 Instant Playback:** Optimized for fast starting and seamless track transitions.
- **📱 Responsive Layout:** Perfectly adapted for mobile, tablet, and desktop screens.
- **🔄 Smart Sync:** Seamlessly integrates with your YouTube Music account through your private backend.

---

## 🏗️ Technical Stack

- **Flutter & Dart:** For cross-platform high-performance rendering.
- **BLoC & Cubit:** Predictable state management for a smooth UX.
- **just_audio:** A powerful audio engine for background playback and streaming.
- **Hive:** Blazing-fast local storage for user preferences and playback history.
- **flutter_dotenv:** Flexible environment-based configuration.

---

## 🚀 Getting Started

### 1. Prerequisites

Ensure you have the following installed:
- **Flutter SDK:** (Check your current version with `flutter --version`)
- **A running Flow Source backend:** See the [Backend Guide](../flow-source/)

### 2. Configure Your Environment

The app connects to your private server via a `.env` file.

1.  Navigate to the `flow` directory: `cd flow`
2.  Create a `.env` file and set your backend URL:
    ```env
    # For Local Development (Desktop/Simulator):
    API_BASE_URL=http://localhost:8000

    # For Real Devices (Using the Cloudflare Tunnel):
    # Get this from your 'docker-compose logs -f tunnel'
    API_BASE_URL=https://your-tunnel-url.trycloudflare.com

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

## 🏗️ Architecture

Flow App follows a clean architecture pattern with a clear separation of concerns:

- `lib/core/`: Foundation logic, auth, networking, and storage.
- `lib/domain/`: Business logic, entities, and repository interfaces.
- `lib/data/`: API and Mock data sources, repository implementations.
- `lib/presentation/`: Screens, widgets, and state management (BLoCs/Cubits).

---

## 🛡️ Key Configurations

- **Playback:** Uses `just_audio_background` for background audio support (Android/iOS/macOS).
- **SMTC:** Windows-specific integration for system media controls and media keys.
- **Hive Boxes:** Data is stored securely in encrypted boxes for sensitive user information.

---

<p align="center">Pure sound, pure flow. 🎵</p>
