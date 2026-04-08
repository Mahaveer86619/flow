import os
from typing import Any, Dict, List, Optional, Union

from dotenv import load_dotenv

load_dotenv()

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

app = FastAPI(title="Flow")


@app.on_event("startup")
def on_startup():
    # Regenerate cookie file from existing auth.json on every container start
    if os.path.exists(AUTH_FILE):
        _write_cookie_file()


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_ytm():
    if os.path.exists(AUTH_FILE):
        return ytmusicapi.YTMusic(AUTH_FILE)
    return ytmusicapi.YTMusic()


def curl_to_headers(curl: str) -> str:
    """Convert a cURL command (Windows or Unix style) to raw request headers."""
    import re

    # Remove line continuations (Unix \ and Windows ^), handling \r and spaces
    curl = re.sub(r"[\^\\]\s*[\r\n]+", " ", curl)
    # Remove escaped quotes
    curl = curl.replace('^"', '"').replace('\\"', '"')

    headers = []

    # Match -H "name: value" or -H 'name: value'
    for m in re.finditer(r'-H\s+([\'"])(.*?)\1', curl):
        headers.append(m.group(2))

    # Match -b "cookie_string" or -b 'cookie_string'
    for m in re.finditer(r'-b\s+([\'"])(.*?)\1', curl):
        headers.append(f"cookie: {m.group(2)}")

    return "\n".join(headers)


# ── Auth ──────────────────────────────────────────────────────────────────────


@app.get("/api/status")
def status():
    return {"authenticated": os.path.exists(AUTH_FILE)}


@app.post("/api/auth")
async def setup_auth(request: Request):
    """
    Accepts either:
      - Raw request headers (Name: Value lines)
      - A full cURL command copied from DevTools (Windows or Unix)
    """
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
        return {"status": "ok", "message": "Authenticated successfully"}
    except Exception as e:
        raise HTTPException(400, f"Auth setup failed: {e}")


@app.delete("/api/auth")
def logout():
    if os.path.exists(AUTH_FILE):
        os.remove(AUTH_FILE)
    return {"status": "ok", "message": "Logged out"}


# ── Feed & Search ──────────────────────────────────────────────────────────────


@app.get("/api/feed")
def get_feed(limit: int = 4):
    try:
        return get_ytm().get_home(limit=limit)
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/api/debug/feed")
def debug_feed(limit: int = 2):
    """
    Returns the raw get_home() response with a summary of item types per shelf.
    Useful for understanding why cards aren't rendering.
    """
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


@app.get("/api/search")
def search(q: str, filter: str = "songs"):
    if not q.strip():
        raise HTTPException(400, "Query is empty")
    try:
        return get_ytm().search(q, filter=filter, limit=20)
    except Exception as e:
        raise HTTPException(500, str(e))


# ── Streaming ─────────────────────────────────────────────────────────────────

COOKIE_FILE = "/data/cookies.txt"


def _write_cookie_file() -> None:
    """Convert the Cookie string in auth.json to a Netscape cookie file for yt-dlp."""
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
        # domain  include_subdomains  path  secure  expiry  name  value
        lines.append(f".youtube.com\tTRUE\t/\tTRUE\t2147483647\t{name}\t{value}\n")

    with open(COOKIE_FILE, "w") as f:
        f.writelines(lines)


def _extract_audio_url(video_id: str) -> str:
    # Do NOT pass cookies to yt-dlp: authenticated sessions force YouTube to demand
    # a GVS PO Token (proof-of-origin) that yt-dlp cannot generate without a full
    # browser JS runtime. Content from the feed is publicly streamable without auth.
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
    """Proxy audio stream so the browser can seek without CORS issues."""
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
        in (
            "content-type",
            "content-length",
            "content-range",
            "accept-ranges",
        )
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


# ── Library ───────────────────────────────────────────────────────────────────


@app.get("/api/library/playlists")
def get_library_playlists(limit: int = 100):
    try:
        return get_ytm().get_library_playlists(limit=limit)
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/api/radio/{video_id}")
def get_radio(video_id: str, limit: int = 25):
    try:
        # get_watch_playlist returns the 'Up Next' queue
        return get_ytm().get_watch_playlist(videoId=video_id, limit=limit)
    except Exception as e:
        raise HTTPException(500, str(e))


# ── Albums ────────────────────────────────────────────────────────────────────


@app.get("/api/albums/{browse_id}")
def get_album(browse_id: str):
    try:
        return get_ytm().get_album(browseId=browse_id)
    except Exception as e:
        raise HTTPException(500, str(e))


# ── Playlists ─────────────────────────────────────────────────────────────────


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


# ── Static frontend (must be last) ────────────────────────────────────────────

app.mount("/", StaticFiles(directory=STATIC_DIR, html=True), name="static")
