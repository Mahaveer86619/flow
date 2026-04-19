# Flow — The Ultimate Standalone Music Experience 🎵

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

Flow is a high-performance, **standalone** music streaming client built with Flutter. It brings the premium features of high-end music players to the vast library of YouTube Music, directly on your device. No mandatory backend, no middleman—just you and your music.

---

## ✨ Key Features

- **💎 Premium UI/UX:** Material 3 design with dynamic color extraction, squiggly progress bars, and fluid animations.
- **⚡ Standalone Performance:** Direct on-device stream resolution and metadata fetching. No external server required.
- **🌍 Cross-Platform:** Native performance on Android, iOS, Windows, macOS, and Linux.
- **📂 Smart Caching & Downloads:** Listen offline with high-quality audio caching and dedicated download management.
- **🖥️ Desktop Excellence:** Full integration with System Media Transport Controls (SMTC), media keys, and native taskbar controls.
- **🎨 Visual Soul:** Dynamic theming that adapts to the mood of the current track.

---

## 🏗️ Evolution: Moving Standalone

Originally designed as a client-server ecosystem, Flow has evolved into a **standalone application**. 

- **Legacy Mode:** Used a Python (FastAPI) backend for proxying and metadata.
- **Standalone Mode (Current):** Resolves YouTube streams directly using `youtube_explode_dart` and fetches metadata via optimized on-device scrapers. This ensures maximum privacy, speed, and ease of deployment.

---

## 🚀 Quick Start

Getting started with Flow is now easier than ever.

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.

### 2. Run the App
1.  **Clone the repo:** `git clone https://github.com/your-repo/music-app.git`
2.  **Navigate to the app:** `cd flow`
3.  **Get dependencies:** `flutter pub get`
4.  **Launch:** `flutter run`

*Note: You may need to provide YouTube Music cookies for personalized features (Home feed, Liked songs). See the in-app settings for instructions.*

---

## 📈 Project Status & Roadmap

### ✅ Completed
- [x] Full transition to on-device stream resolution (Fixes 403 proxy issues).
- [x] Direct YouTube Music Home feed & Search integration.
- [x] Local SQLite/Hive caching for playback history and preferences.
- [x] Cross-platform support (Win/Android/Linux/macOS).
- [x] Premium Player UI with "Squiggly" progress bar.

### 🚧 In Progress (Current Goals)
- [ ] **Spotify Integration:** Hybrid search and playlist import from Spotify.
- [ ] **Enhanced Offline Mode:** Full library management for downloaded tracks.
- [ ] **Desktop Mini-player:** A compact, always-on-top player for Windows and macOS.

### 🔮 Future Vision (Final Goal)
- [ ] **P2P Library Sync:** Synchronize your library across devices without a central server.
- [ ] **Collaborative Playlists:** Real-time shared listening sessions using WebRTC.
- [ ] **AI-Powered Discovery:** Local LLM-based music recommendations based on listening habits.

---

## 🤝 Contributing

We love contributions! Whether it's a bug fix, a new feature, or design improvements:

1.  **Fork** the repository.
2.  **Create a branch** (`git checkout -b feature/amazing-feature`).
3.  **Commit** your changes (`git commit -m 'Add amazing feature'`).
4.  **Push** to the branch (`git push origin feature/amazing-feature`).
5.  **Open a Pull Request**.

Please ensure your code adheres to the project's linting rules and includes relevant tests.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">Made with ❤️ for music lovers by music lovers.</p>
