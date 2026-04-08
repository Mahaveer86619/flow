# Flow — Music App

A cross-platform music streaming app built with Flutter, backed by a self-hosted Python server that sources audio from YouTube Music.

```
music-app/
├── flow/               # Flutter app (Android, iOS, Windows, Linux, macOS, Web)
└── music-source/
    └── ytmusic-api/    # FastAPI backend (in progress)
```

## Overview

**Flow** is the client — a responsive Flutter app with a full music player UI, home feed, search, library, and queue management. It currently runs against mock data while the backend is being built out.

**music-source** is the server layer (work in progress). The goal is a robust, self-hosted backend that streams audio and serves personalised music data from YouTube Music.

---

## Flow (Flutter App)

See [`flow/README.md`](flow/README.md) for setup and architecture details.

**Quick start:**
```bash
cd flow
flutter pub get
flutter run
```

---

## music-source / ytmusic-api (Backend)

A FastAPI server that wraps `ytmusicapi` for data and `yt-dlp` for audio streaming.

### Setup

```bash
cd music-source/ytmusic-api
pip install -r requirements.txt
uvicorn backend.main:app --reload --port 8000
```

### Authentication

The server supports unauthenticated (public) and authenticated (personal library, recommendations) modes. To authenticate, paste your YouTube Music request headers or a cURL command from browser DevTools:

```bash
curl -X POST http://localhost:8000/api/auth \
  -H "Content-Type: text/plain" \
  --data-binary @headers.txt
```

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/status` | Auth status |
| `POST` | `/api/auth` | Set up authentication via raw headers or cURL |
| `DELETE` | `/api/auth` | Log out |
| `GET` | `/api/feed` | Personalised home feed |
| `GET` | `/api/search?q=&filter=` | Search (songs, albums, artists, etc.) |
| `GET` | `/api/stream/{video_id}` | Proxy audio stream with range support |
| `GET` | `/api/proxy-image?url=` | Proxy album art (avoids CORS) |
| `GET` | `/api/library/playlists` | User's library playlists |
| `GET` | `/api/radio/{video_id}` | Up-next / radio queue |
| `GET` | `/api/albums/{browse_id}` | Album details and tracks |
| `GET` | `/api/playlists/{playlist_id}` | Playlist details and tracks |
| `POST` | `/api/playlists` | Create playlist |
| `PATCH` | `/api/playlists/{playlist_id}` | Edit playlist |
| `DELETE` | `/api/playlists/{playlist_id}` | Delete playlist |
| `POST` | `/api/playlists/{playlist_id}/items` | Add tracks to playlist |
| `DELETE` | `/api/playlists/{playlist_id}/items` | Remove tracks from playlist |

### Stack

- **FastAPI** + **uvicorn** — HTTP server
- **ytmusicapi** — YouTube Music metadata and library
- **yt-dlp** — audio URL extraction for streaming
- **httpx** — async upstream proxying

---

## Roadmap

- [ ] Connect Flutter app to live backend (replace `MockSongRepository`)
- [ ] Docker setup for the backend
- [ ] Offline caching / download support
- [ ] Lyrics integration
- [ ] Recommendation engine (`music-source/Hybrid-Music-Recommendation-System`)
