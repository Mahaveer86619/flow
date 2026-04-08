# Flow — Music App

A cross-platform music streaming app. The Flutter client (`flow/`) fetches personalised content and audio from the self-hosted Python backend (`music-source/ytmusic-api`), which sources everything from YouTube Music.

```
music-app/
├── flow/               # Flutter app (Android, iOS, Windows, Linux, macOS, Web)
└── music-source/
    └── ytmusic-api/    # FastAPI backend — music data + audio proxy
```

---

## Quick Start

### 1. Start the backend

```bash
cd music-source/ytmusic-api
pip install -r requirements.txt
uvicorn backend.main:app --reload --port 8000
```

### 2. Authenticate (optional — enables personalised feed & library)

```bash
# Paste raw request headers or a cURL command copied from YouTube Music DevTools
curl -X POST http://localhost:8000/api/auth \
  -H "Content-Type: text/plain" \
  --data-binary @headers.txt
```

### 3. Run the app

```bash
cd flow
flutter pub get
flutter run
```

Set `API_BASE_URL` in `flow/.env` to your backend address (default `http://localhost:8000`).

---

## Backend — `music-source/ytmusic-api`

FastAPI server wrapping ytmusicapi (data) and yt-dlp (audio streaming).

### Normalised API Endpoints (consumed by the Flutter app)

These endpoints return clean, flat JSON the app parses directly.

#### Songs

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/songs/feed` | Songs from the personalised home feed |
| `GET` | `/api/songs/search?q=` | Song search results |
| `GET` | `/api/stream/{video_id}` | Range-aware audio proxy stream |

**Song object:**
```json
{
  "id": "videoId",
  "title": "Song Title",
  "artist": "Artist Name",
  "album": "Album Name",
  "durationMs": 222000,
  "thumbnailUrl": "https://lh3.googleusercontent.com/..."
}
```

#### Playlists

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/library/playlists` | User's playlist metadata |
| `GET` | `/api/playlists/{id}/tracks` | Normalised track list for a playlist |

**Playlist object:**
```json
{
  "id": "PLxxx",
  "name": "Playlist Name",
  "description": "25 songs",
  "thumbnailUrl": "https://...",
  "trackCount": 25
}
```

### Raw / Management Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/status` | Auth status |
| `POST` | `/api/auth` | Authenticate via headers or cURL |
| `DELETE` | `/api/auth` | Log out |
| `GET` | `/api/feed` | Raw home shelves (ytmusicapi format) |
| `GET` | `/api/search?q=&filter=` | Raw search (ytmusicapi format) |
| `GET` | `/api/proxy-image?url=` | CORS-safe image proxy |
| `GET` | `/api/radio/{video_id}` | Up-next / radio queue |
| `GET` | `/api/albums/{browse_id}` | Album detail |
| `GET` | `/api/playlists/{id}` | Raw playlist detail |
| `POST` | `/api/playlists` | Create playlist |
| `PATCH` | `/api/playlists/{id}` | Edit playlist |
| `DELETE` | `/api/playlists/{id}` | Delete playlist |
| `POST` | `/api/playlists/{id}/items` | Add tracks |
| `DELETE` | `/api/playlists/{id}/items` | Remove tracks |

### Stack

- **FastAPI** + **uvicorn** — HTTP server
- **ytmusicapi 1.11.5** — YouTube Music metadata and library
- **yt-dlp** — audio URL extraction
- **httpx** — async upstream proxying

---

## Flutter App — `flow/`

See [`flow/README.md`](flow/README.md) for full architecture and setup details.

**Environment (`flow/.env`):**
```env
API_BASE_URL=http://localhost:8000
USE_MOCK=false          # true → bypass backend, use hard-coded mock data
```

---

## Roadmap

- [ ] Audio playback integration (connect stream URL to audio plugin)
- [ ] Docker / docker-compose for the backend
- [ ] Playlist track loading in-app (currently tracks fetched separately)
- [ ] Offline caching / download support
- [ ] Lyrics integration
- [ ] Custom Recommendation engine
