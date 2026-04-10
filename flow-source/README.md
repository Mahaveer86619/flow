# Flow Music API

Production-ready YT Music API server for the Flow app.

## Features

- **Standardized Endpoints:** Clean `/api/v1` routes for home feed, search, and library.
- **Production-Ready Structure:** Organized code following FastAPI best practices.
- **Configuration:** Environment variables support via `.env`.
- **Caching:** Server-side caching for home feed to improve performance.
- **Streaming:** Proxied audio streaming using `yt-dlp` and `httpx`.
- **Image Proxy:** Handle CORS issues for thumbnails.
- **Playlist Management:** Complete CRUD operations for playlists.

## Setup

1.  **Install Dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

2.  **Configuration:**
    Copy `.env` and adjust the settings if needed.
    ```bash
    cp .env.example .env # If provided, otherwise just edit the generated .env
    ```

3.  **Run the Server:**
    ```bash
    python run.py
    ```

## Endpoints

- **Home:** `GET /api/v1/home`
- **Search:** `GET /api/v1/search/songs?q=query`
- **Library:** `GET /api/v1/library`
- **Stream:** `GET /api/v1/stream/{video_id}`
- **Auth Status:** `GET /api/status`
- **Setup Auth:** `POST /api/auth` (Body: headers or curl command)

## Data Storage

- `data/auth.json`: Stores authentication headers.
- `data/cookies.txt`: Netscape format cookies for `yt-dlp`.
