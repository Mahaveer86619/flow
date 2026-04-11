# Flow — Music Ecosystem

Flow is a cross-platform music streaming ecosystem that allows you to stream your YouTube Music library through a beautiful, self-hosted interface. It consists of a high-performance Python backend and a responsive Flutter frontend.

## Project Structure

```
music-app/
├── flow/               # Flutter Frontend (Android, iOS, Windows, macOS, Linux)
└── flow-source/        # Python Backend (FastAPI, PostgreSQL, yt-dlp)
```

---

## Quick Start

### 1. Start the Backend (`flow-source`)
The backend manages user authentication, metadata fetching from YouTube Music, and secure audio streaming.

```bash
cd flow-source
pip install -r requirements.txt
python manage.py create   # Initialize PostgreSQL database
python run.py             # Start server at http://localhost:8000
```
*Note: Refer to [`flow-source/README.md`](./flow-source/README.md) for detailed configuration.*

### 2. Start the App (`flow`)
The app provides an immersive playback experience with dynamic UI elements and seamless library management.

```bash
cd flow
flutter pub get
flutter run
```
*Note: Configure your backend URL in `flow/.env`. Refer to [`flow/README.md`](./flow/README.md) for more details.*

---

## Key Features

- **Cross-Platform:** One codebase for mobile and desktop.
- **Self-Hosted:** You own your data and your server.
- **YouTube Music Integration:** Link your account to access your existing playlists and history.
- **JWT Auth:** Secure user management system.
- **Proxied Streaming:** High-performance audio streaming with range-request support.
- **Polished UI:** Material 3 design, squiggly progress bars, and dynamic color palettes.

---

## Documentation

- **Frontend Details:** [flow/README.md](./flow/README.md)
- **Backend Details:** [flow-source/README.md](./flow-source/README.md)
- **API Reference:** [flow-source/Flow_v1_Postman_Collection.json](./flow-source/Flow_v1_Postman_Collection.json)
