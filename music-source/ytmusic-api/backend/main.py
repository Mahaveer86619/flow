import os
import re
import time
from typing import Any, Dict, List, Optional, Union

import httpx
import yt_dlp
import ytmusicapi
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

AUTH_FILE = "/data/auth.json"
STATIC_DIR = "/app/static"

os.makedirs("/data", exist_ok=True)

app = FastAPI(title="Flow Music API", version="1.0.0")


@app.on_event("startup")
def on_startup():
    if os.path.exists(AUTH_FILE):
        _write_cookie_file()


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── YTMusic client ─────────────────────────────────────────────────────────────


def get_ytm():
    if os.path.exists(AUTH_FILE):
        return ytmusicapi.YTMusic(AUTH_FILE)
    return ytmusicapi.YTMusic()


# ── Pydantic response models ───────────────────────────────────────────────────
#
# These define the exact JSON shapes the Flutter app depends on.
# Any field added here must also be handled in the Flutter models.


class SongResponse(BaseModel):
    id: str
    title: str
    artist: str
    album: str
    durationMs: int
    thumbnailUrl: Optional[str] = None


class ArtistResponse(BaseModel):
    name: str
    thumbnailUrl: Optional[str] = None


class PlaylistResponse(BaseModel):
    id: str
    name: str
    description: str
    thumbnailUrl: Optional[str] = None
    trackCount: int


class HomeResponse(BaseModel):
    quickAccess: List[SongResponse]
    listeningAgain: List[SongResponse]
    forgottenFavorites: List[SongResponse]
    musicForYou: List[SongResponse]
    trendingArtists: List[ArtistResponse]
    trending: List[SongResponse] = []


class LibraryResponse(BaseModel):
    playlists: List[PlaylistResponse]


# ── Normalisation helpers ──────────────────────────────────────────────────────


def _fix_thumbnail_url(url: Optional[str]) -> Optional[str]:
    """Normalise a YouTube/Google thumbnail URL to a consistent 500×500 size."""
    if not url:
        return None
    # lh3.googleusercontent.com URLs end with =wNNN-hNNN-... size params.
    # Request 1000 px so full-screen art stays crisp on high-density screens.
    url = re.sub(r"=w\d+-h\d+(-[^?&]*)?$", "=w1000-h1000-l90-rj", url)
    return url


def _normalize_song(item: dict) -> Optional[SongResponse]:
    video_id = item.get("videoId")
    if not video_id:
        return None

    artists = item.get("artists") or []
    artist_name = ", ".join(a["name"] for a in artists if a.get("name")) or "Unknown"

    album = item.get("album") or {}
    album_name = album.get("name", "") if isinstance(album, dict) else ""

    thumbnails = item.get("thumbnails") or []
    raw_url = thumbnails[-1]["url"] if thumbnails else None

    duration_seconds = item.get("duration_seconds") or 0

    return SongResponse(
        id=video_id,
        title=item.get("title") or "Unknown",
        artist=artist_name,
        album=album_name,
        durationMs=int(duration_seconds) * 1000,
        thumbnailUrl=_fix_thumbnail_url(raw_url),
    )


def _is_artist_item(item: dict) -> bool:
    return (
        item.get("resultType") == "artist"
        or item.get("type") == "artist"
        or bool(item.get("subscribers"))
        or (not item.get("videoId") and str(item.get("browseId", "")).startswith("UC"))
    )


def _normalize_artist(item: dict) -> Optional[ArtistResponse]:
    name = item.get("artist") or item.get("title") or item.get("name")
    if not name:
        return None
    thumbnails = item.get("thumbnails") or []
    raw_url = thumbnails[-1]["url"] if thumbnails else None
    return ArtistResponse(name=name, thumbnailUrl=_fix_thumbnail_url(raw_url))


def _normalize_playlist(item: dict) -> PlaylistResponse:
    thumbnails = item.get("thumbnails") or []
    raw_url = thumbnails[-1]["url"] if thumbnails else None

    count_str: str = str(item.get("count") or "")
    description = f"{count_str} songs" if count_str else item.get("description", "")
    track_count = 0
    parts = count_str.split()
    if parts and parts[0].isdigit():
        track_count = int(parts[0])

    return PlaylistResponse(
        id=item.get("playlistId") or item.get("id", ""),
        name=item.get("title") or item.get("name") or "Unknown",
        description=description,
        thumbnailUrl=_fix_thumbnail_url(raw_url),
        trackCount=track_count,
    )


# ── Home data builder + TTL cache ──────────────────────────────────────────────

_SHELF_MAP: list[tuple[list[str], str]] = [
    (["quick pick", "top pick"],                         "quickAccess"),
    (["listen again", "listening again", "continue"],    "listeningAgain"),
    (["forgotten", "throwback", "rediscover", "missed"], "forgottenFavorites"),
    (["for you", "recommended", "mixed", "new release",
      "top chart", "trending", "chart", "popular"],      "musicForYou"),
]

_HOME_CACHE_TTL = 300  # seconds
_home_cache: dict = {}


def _classify_shelf(title: str) -> Optional[str]:
    t = title.lower()
    for keywords, section in _SHELF_MAP:
        if any(k in t for k in keywords):
            return section
    return None


def _get_trending_songs(ytm) -> List[SongResponse]:
    """Fetch worldwide chart songs as a supplementary trending section."""
    try:
        charts = ytm.get_charts(country="ZZ")  # ZZ = worldwide
        # Prefer the "songs" chart; fall back to "trending"
        items: list = []
        songs_chart = charts.get("songs") or {}
        items = songs_chart.get("items") or []
        if not items:
            trending_chart = charts.get("trending") or {}
            items = trending_chart.get("items") or []
        return [s for item in items[:20] if (s := _normalize_song(item))]
    except Exception:
        return []


def _build_home_data(limit: int = 15) -> HomeResponse:
    ytm = get_ytm()
    shelves = ytm.get_home(limit=limit)

    sections: dict[str, list] = {
        "quickAccess": [],
        "listeningAgain": [],
        "forgottenFavorites": [],
        "musicForYou": [],
        "trendingArtists": [],
    }
    seen_ids: set[str] = set()
    overflow: list[list] = []

    for shelf in shelves:
        title = shelf.get("title") or ""
        contents = shelf.get("contents") or []
        section = _classify_shelf(title)

        artists_in_shelf: list = []
        songs_in_shelf: list = []

        for item in contents:
            if _is_artist_item(item):
                artist = _normalize_artist(item)
                if artist:
                    artists_in_shelf.append(artist)
            else:
                song = _normalize_song(item)
                if song and song.id not in seen_ids:
                    seen_ids.add(song.id)
                    songs_in_shelf.append(song)

        sections["trendingArtists"].extend(artists_in_shelf)

        if songs_in_shelf:
            if section:
                sections[section].extend(songs_in_shelf)
            else:
                overflow.append(songs_in_shelf)

    fill_priority = ["listeningAgain", "forgottenFavorites", "musicForYou", "quickAccess"]
    for songs in overflow:
        target = min(fill_priority, key=lambda k: len(sections[k]))
        sections[target].extend(songs)

    if not sections["quickAccess"]:
        source = sections["listeningAgain"] or sections["musicForYou"]
        sections["quickAccess"] = source[:8]

    sections["quickAccess"]        = sections["quickAccess"][:8]
    sections["listeningAgain"]     = sections["listeningAgain"][:15]
    sections["forgottenFavorites"] = sections["forgottenFavorites"][:15]
    sections["musicForYou"]        = sections["musicForYou"][:20]
    sections["trendingArtists"]    = sections["trendingArtists"][:10]

    # Supplement with worldwide charts (doesn't count against home-feed dedup)
    trending = _get_trending_songs(ytm)

    return HomeResponse(**sections, trending=trending)


def _get_home_cached(limit: int = 5) -> HomeResponse:
    now = time.monotonic()
    if _home_cache.get("ts", 0) + _HOME_CACHE_TTL > now:
        return _home_cache["data"]
    data = _build_home_data(limit)
    _home_cache["ts"] = now
    _home_cache["data"] = data
    return data


# ── /api/v1 endpoints — primary app endpoints ─────────────────────────────────
#
# Routes are defined directly on `app` (not via APIRouter) to avoid the
# known Starlette interaction where StaticFiles mounted at "/" intercepts
# paths registered through sub-routers before they can be matched.


@app.get("/api/v1/home", response_model=HomeResponse)
def v1_get_home(limit: int = 5):
    """
    Full home screen data in one call.

    Sections:
      quickAccess        — recent / top picks (≤ 8 songs)
      listeningAgain     — continue listening  (≤ 10 songs)
      forgottenFavorites — throwbacks          (≤ 10 songs)
      musicForYou        — recommendations     (≤ 20 songs)
      trendingArtists    — artist cards        (≤ 10 artists)

    Cached server-side for 5 minutes.
    """
    try:
        return _get_home_cached(limit)
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/api/v1/home/quick-access", response_model=List[SongResponse])
def v1_quick_access():
    """Quick-access / top-picks section only."""
    try:
        return _get_home_cached().quickAccess
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/api/v1/home/listening-again", response_model=List[SongResponse])
def v1_listening_again():
    """Listening-again / continue section only."""
    try:
        return _get_home_cached().listeningAgain
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/api/v1/home/forgotten-favorites", response_model=List[SongResponse])
def v1_forgotten_favorites():
    """Forgotten-favorites / throwback section only."""
    try:
        return _get_home_cached().forgottenFavorites
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/api/v1/home/music-for-you", response_model=List[SongResponse])
def v1_music_for_you():
    """Music-for-you / recommendations section only."""
    try:
        return _get_home_cached().musicForYou
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/api/v1/home/trending-artists", response_model=List[ArtistResponse])
def v1_trending_artists():
    """Trending artists section only."""
    try:
        return _get_home_cached().trendingArtists
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/api/v1/search/songs", response_model=List[SongResponse])
def v1_search_songs(q: str, limit: int = 20):
    """Normalised song search results."""
    if not q.strip():
        raise HTTPException(400, "Query is empty")
    try:
        results = get_ytm().search(q, filter="songs", limit=limit)
        return [s for item in results if (s := _normalize_song(item))]
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/api/v1/library", response_model=LibraryResponse)
def v1_get_library():
    """
    Library data — playlist metadata only.
    Tracks are fetched on demand via GET /api/v1/playlists/{id}/tracks.
    """
    try:
        raw = get_ytm().get_library_playlists(limit=100)
        return LibraryResponse(playlists=[_normalize_playlist(p) for p in raw])
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/api/v1/playlists/{playlist_id}/tracks", response_model=List[SongResponse])
def v1_get_playlist_tracks(playlist_id: str, limit: int = 100):
    """Normalised track list for a playlist."""
    try:
        actual_limit = None if limit <= 0 else limit
        data = get_ytm().get_playlist(playlistId=playlist_id, limit=actual_limit)
        tracks = data.get("tracks") or []
        return [s for item in tracks if (s := _normalize_song(item))]
    except Exception as e:
        raise HTTPException(500, str(e))


@app.delete("/api/v1/home/cache")
def v1_clear_home_cache():
    """Force-expire the home data cache (useful after auth change)."""
    _home_cache.clear()
    return {"status": "ok", "message": "Home cache cleared"}


# ── Auth endpoints ─────────────────────────────────────────────────────────────


def curl_to_headers(curl: str) -> str:
    curl = re.sub(r"[\^\\]\s*[\r\n]+", " ", curl)
    curl = curl.replace('^"', '"').replace('\\"', '"')
    headers = []
    for m in re.finditer(r'-H\s+([\'"])(.*?)\1', curl):
        headers.append(m.group(2))
    for m in re.finditer(r'-b\s+([\'"])(.*?)\1', curl):
        headers.append(f"cookie: {m.group(2)}")
    return "\n".join(headers)


@app.get("/api/status")
def status():
    return {"authenticated": os.path.exists(AUTH_FILE)}


@app.post("/api/auth")
async def setup_auth(request: Request):
    body = (await request.body()).decode("utf-8").strip()
    if not body:
        raise HTTPException(400, "Body is empty")

    headers_raw = curl_to_headers(body) if body.lstrip().startswith("curl") else body

    if "cookie" not in headers_raw.lower():
        raise HTTPException(
            400,
            "No cookie header found — make sure to include the full headers or cURL command",
        )

    try:
        ytmusicapi.setup(AUTH_FILE, headers_raw=headers_raw)
        _write_cookie_file()
        _home_cache.clear()  # invalidate cached home data after re-auth
        return {"status": "ok", "message": "Authenticated successfully"}
    except Exception as e:
        raise HTTPException(400, f"Auth setup failed: {e}")


@app.delete("/api/auth")
def logout():
    if os.path.exists(AUTH_FILE):
        os.remove(AUTH_FILE)
    _home_cache.clear()
    return {"status": "ok", "message": "Logged out"}


# ── Streaming ──────────────────────────────────────────────────────────────────

COOKIE_FILE = "/data/cookies.txt"


def _write_cookie_file() -> None:
    import json

    if not os.path.exists(AUTH_FILE):
        return
    with open(AUTH_FILE) as f:
        data = json.load(f)
    cookie_str = data.get("Cookie") or data.get("cookie") or ""
    if not cookie_str:
        return

    lines = ["# Netscape HTTP Cookie File\n"]
    for pair in cookie_str.split(";"):
        pair = pair.strip()
        if "=" not in pair:
            continue
        name, _, value = pair.partition("=")
        name = name.strip()
        value = value.strip()
        lines.append(f".youtube.com\tTRUE\t/\tTRUE\t2147483647\t{name}\t{value}\n")

    with open(COOKIE_FILE, "w") as f:
        f.writelines(lines)


def _extract_audio_url(video_id: str) -> str:
    ydl_opts = {
        "format": "bestaudio/best",
        "quiet": True,
        "no_warnings": True,
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(
            f"https://music.youtube.com/watch?v={video_id}",
            download=False,
        )
        return info["url"]


@app.get("/api/stream/{video_id}")
async def stream_audio(video_id: str, request: Request):
    """Proxy audio stream so the app can seek without CORS issues."""
    try:
        audio_url = _extract_audio_url(video_id)
    except Exception as e:
        raise HTTPException(500, f"yt-dlp extraction failed: {e}")

    upstream_headers = {}
    if "range" in request.headers:
        upstream_headers["range"] = request.headers["range"]

    client = httpx.AsyncClient(timeout=60)
    upstream = await client.send(
        httpx.Request("GET", audio_url, headers=upstream_headers),
        stream=True,
    )

    passthrough = {
        k: v
        for k, v in upstream.headers.items()
        if k.lower()
        in ("content-type", "content-length", "content-range", "accept-ranges")
    }
    passthrough.setdefault("accept-ranges", "bytes")

    async def _iter():
        try:
            async for chunk in upstream.aiter_bytes(65536):
                yield chunk
        finally:
            await upstream.aclose()
            await client.aclose()

    return StreamingResponse(
        _iter(),
        status_code=upstream.status_code,
        headers=passthrough,
        media_type=upstream.headers.get("content-type", "audio/webm"),
    )


import urllib.parse

from fastapi.responses import Response


@app.get("/api/proxy-image")
async def proxy_image(url: str):
    """Proxy a thumbnail URL — use only when CORS blocks direct image loading."""
    try:
        decoded_url = urllib.parse.unquote(url)
        async with httpx.AsyncClient() as client:
            resp = await client.get(decoded_url)
            return Response(
                content=resp.content,
                media_type=resp.headers.get("Content-Type", "image/jpeg"),
            )
    except Exception as e:
        raise HTTPException(500, f"Image proxy failed: {e}")


# ── Playlist CRUD (unversioned — used by web frontend) ─────────────────────────


@app.get("/api/playlists/{playlist_id}")
def get_playlist(playlist_id: str, limit: int = 100):
    try:
        actual_limit = None if limit <= 0 else limit
        return get_ytm().get_playlist(playlistId=playlist_id, limit=actual_limit)
    except Exception as e:
        raise HTTPException(500, str(e))


class CreatePlaylistRequest(BaseModel):
    title: str
    description: str
    privacy_status: str = "PRIVATE"
    video_ids: Optional[List[str]] = None
    source_playlist: Optional[str] = None


@app.post("/api/playlists")
def create_playlist(req: CreatePlaylistRequest):
    try:
        res = get_ytm().create_playlist(
            title=req.title,
            description=req.description,
            privacy_status=req.privacy_status,
            video_ids=req.video_ids,
            source_playlist=req.source_playlist,
        )
        return {"id": res}
    except Exception as e:
        raise HTTPException(500, str(e))


class EditPlaylistRequest(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    privacyStatus: Optional[str] = None
    moveItem: Optional[Union[str, tuple[str, str]]] = None
    addPlaylistId: Optional[str] = None
    addToTop: Optional[bool] = None


@app.patch("/api/playlists/{playlist_id}")
def edit_playlist(playlist_id: str, req: EditPlaylistRequest):
    try:
        res = get_ytm().edit_playlist(
            playlistId=playlist_id,
            title=req.title,
            description=req.description,
            privacyStatus=req.privacyStatus,
            moveItem=req.moveItem,
            addPlaylistId=req.addPlaylistId,
            addToTop=req.addToTop,
        )
        return {"status": res}
    except Exception as e:
        raise HTTPException(500, str(e))


@app.delete("/api/playlists/{playlist_id}")
def delete_playlist(playlist_id: str):
    try:
        res = get_ytm().delete_playlist(playlistId=playlist_id)
        return {"status": res}
    except Exception as e:
        raise HTTPException(500, str(e))


class AddPlaylistItemsRequest(BaseModel):
    videoIds: Optional[List[str]] = None
    source_playlist: Optional[str] = None
    duplicates: bool = False


@app.post("/api/playlists/{playlist_id}/items")
def add_playlist_items(playlist_id: str, req: AddPlaylistItemsRequest):
    try:
        res = get_ytm().add_playlist_items(
            playlistId=playlist_id,
            videoIds=req.videoIds,
            source_playlist=req.source_playlist,
            duplicates=req.duplicates,
        )
        return {"status": res}
    except Exception as e:
        raise HTTPException(500, str(e))


class RemovePlaylistItemsRequest(BaseModel):
    videos: List[Dict[str, Any]]


@app.delete("/api/playlists/{playlist_id}/items")
def remove_playlist_items(playlist_id: str, req: RemovePlaylistItemsRequest):
    try:
        res = get_ytm().remove_playlist_items(playlistId=playlist_id, videos=req.videos)
        return {"status": res}
    except Exception as e:
        raise HTTPException(500, str(e))


# ── Legacy aliases (web frontend compatibility) ────────────────────────────────


@app.get("/api/feed")
def get_feed(limit: int = 4):
    """Raw ytmusicapi home shelves. Kept for web-frontend compatibility."""
    try:
        return get_ytm().get_home(limit=limit)
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/api/library/playlists")
def get_library_playlists(limit: int = 100):
    """Normalised playlists. Kept for web-frontend compatibility."""
    try:
        raw = get_ytm().get_library_playlists(limit=limit)
        return [_normalize_playlist(p) for p in raw]
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/api/search/songs")
def search_songs_legacy(q: str, limit: int = 20):
    """Kept for web-frontend compatibility. Prefer /api/v1/search/songs."""
    if not q.strip():
        raise HTTPException(400, "Query is empty")
    try:
        results = get_ytm().search(q, filter="songs", limit=limit)
        return [s for item in results if (s := _normalize_song(item))]
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/api/songs/search")
def search_songs_legacy2(q: str, limit: int = 20):
    """Alias. Kept for web-frontend compatibility."""
    return search_songs_legacy(q=q, limit=limit)


# ── Debug / raw endpoints (development use) ────────────────────────────────────


@app.get("/api/debug/feed")
def debug_feed(limit: int = 2):
    """Raw get_home() with per-shelf type summary. Dev only."""
    try:
        shelves = get_ytm().get_home(limit=limit)
    except Exception as e:
        raise HTTPException(500, str(e))

    summary = []
    for shelf in shelves:
        items = shelf.get("contents", [])
        type_counts: dict = {}
        for item in items:
            t = (
                item.get("resultType")
                or item.get("type")
                or ("song" if item.get("videoId") else "no-videoId")
            )
            type_counts[t] = type_counts.get(t, 0) + 1
        summary.append(
            {
                "shelf": shelf.get("title"),
                "item_count": len(items),
                "types": type_counts,
                "first_item_keys": list(items[0].keys()) if items else [],
            }
        )

    return {"shelves": len(shelves), "summary": summary, "raw": shelves}


@app.get("/api/radio/{video_id}")
def get_radio(video_id: str, limit: int = 25):
    try:
        return get_ytm().get_watch_playlist(videoId=video_id, limit=limit)
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/api/albums/{browse_id}")
def get_album(browse_id: str):
    try:
        return get_ytm().get_album(browseId=browse_id)
    except Exception as e:
        raise HTTPException(500, str(e))


# ── Static frontend (must be last) ────────────────────────────────────────────

app.mount("/", StaticFiles(directory=STATIC_DIR, html=True), name="static")
