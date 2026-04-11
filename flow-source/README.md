# Flow Music API (Backend)

Production-ready YouTube Music API server for the Flow app, built with FastAPI and PostgreSQL.

## Features

- **Standardized Endpoints:** Clean `/v1` routes for home feed, search, and library management.
- **User Management:** JWT-based authentication with signup and login endpoints.
- **Per-User Integration:** Each user can link their own YouTube Music account; credentials are stored securely in the database.
- **Streaming:** Proxied audio streaming using `yt-dlp` and `httpx` with range-request support.
- **Caching:** Server-side caching for personalized home shelves to optimize performance.
- **Image Proxy:** Built-in proxy to bypass CORS/referer issues for album art thumbnails.
- **Playlist Management:** Complete CRUD operations for YouTube Music playlists.
- **Infrastructure:** Containerized setup with Docker and Docker Compose.

## Setup

### 1. Prerequisites
- Python 3.12+
- PostgreSQL (or use the provided Docker setup)
- ffmpeg (required by `yt-dlp`)

### 2. Installation
```bash
# Clone the repository and navigate to flow-source
pip install -r requirements.txt
```

### 3. Configuration
Copy the `.env.example` (if provided) or create a `.env` file with the following:
```env
DEBUG=True
FLAVOR=local
DATABASE_URL=postgresql://flow_user:password@localhost:5432/flow_music
SECRET_KEY=your-secret-key-here
```

### 4. Database Initialization
```bash
python manage.py create
python manage.py seed   # Optional: seeds initial roles and an admin user
```

### 5. Running the Server
```bash
python run.py
```
The server will start at `http://localhost:8000`.

## API Documentation

For a comprehensive list of endpoints, request bodies, and authentication headers, refer to the included Postman collection:
`Flow_v1_Postman_Collection.json`

### Core Endpoints Preview
- **Auth:** `POST /v1/auth/signup`, `POST /v1/auth/login`
- **Home:** `GET /v1/home` (Personalized shelves)
- **Search:** `GET /v1/search/songs?q=query`
- **Library:** `GET /v1/library`
- **Streaming:** `GET /v1/stream/{video_id}`
- **Account Linking:** `POST /v1/yt-auth` (Submit browser headers or cURL)

## Data Storage
- `data/`: Temporary storage for user-specific cookies and session data.
- `static/`: Served static files (if any).
