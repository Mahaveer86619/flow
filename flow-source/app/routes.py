import os
import urllib.parse
from typing import List, Optional

import httpx
import ytmusicapi
from fastapi import APIRouter, HTTPException, Request, Response
from fastapi.responses import StreamingResponse

from .config import settings
from .models import (
    AddPlaylistItemsRequest,
    ArtistResponse,
    CreatePlaylistRequest,
    EditPlaylistRequest,
    HomeResponse,
    LibraryResponse,
    PlaylistResponse,
    RemovePlaylistItemsRequest,
    SongResponse,
)
from .services import extract_audio_url, yt_service
from .utils import (
    curl_to_headers,
    normalize_artist,
    normalize_playlist,
    normalize_song,
    write_cookie_file,
)

router = APIRouter()


def _require_auth():
    """Raise 401 if the server has no auth.json configured."""
    if not os.path.exists(settings.AUTH_FILE_PATH):
        raise HTTPException(
            status_code=401,
            detail="Not authenticated — connect your YouTube Music account first.",
        )


# --- Home Endpoints ---


@router.get("/v1/home", response_model=HomeResponse)
async def get_home(limit: int = 5):
    try:
        return yt_service.get_home_cached(limit)
    except Exception as e:
        raise HTTPException(500, str(e))


@router.get("/v1/home/quick-access", response_model=List[SongResponse])
async def quick_access():
    return (await get_home()).quickAccess


@router.get("/v1/home/listening-again", response_model=List[SongResponse])
async def listening_again():
    return (await get_home()).listeningAgain


@router.get("/v1/home/forgotten-favorites", response_model=List[SongResponse])
async def forgotten_favorites():
    return (await get_home()).forgottenFavorites


@router.get("/v1/home/music-for-you", response_model=List[SongResponse])
async def music_for_you():
    return (await get_home()).musicForYou


@router.get("/v1/home/trending-artists", response_model=List[ArtistResponse])
async def trending_artists():
    return (await get_home()).trendingArtists


@router.delete("/v1/home/cache")
async def clear_home_cache():
    yt_service.clear_cache()
    return {"status": "ok", "message": "Home cache cleared"}


@router.get("/v1/feed", response_model=HomeResponse)
async def get_feed():
    """Unauthenticated home feed — returns trending / chart data only.
    Safe to call without authentication; never raises 401."""
    try:
        return yt_service.get_feed_cached()
    except Exception as e:
        raise HTTPException(500, str(e))


# --- Search Endpoints ---


@router.get("/v1/search/songs", response_model=List[SongResponse])
async def search_songs(q: str, limit: int = 20):
    if not q.strip():
        raise HTTPException(400, "Query is empty")
    try:
        results = yt_service.get_client().search(q, filter="songs", limit=limit)
        return [s for item in results if (s := normalize_song(item))]
    except Exception as e:
        raise HTTPException(500, str(e))


# --- Library & Playlists Endpoints ---


@router.get("/v1/library", response_model=LibraryResponse)
async def get_library():
    _require_auth()
    try:
        raw = yt_service.get_client().get_library_playlists(limit=100)
        return LibraryResponse(playlists=[normalize_playlist(p) for p in raw])
    except Exception as e:
        raise HTTPException(500, str(e))


@router.get("/v1/playlists/{playlist_id}/tracks", response_model=List[SongResponse])
async def get_playlist_tracks(playlist_id: str, limit: int = 100):
    try:
        actual_limit = None if limit <= 0 else limit
        data = yt_service.get_client().get_playlist(
            playlistId=playlist_id, limit=actual_limit
        )
        tracks = data.get("tracks") or []
        return [s for item in tracks if (s := normalize_song(item))]
    except Exception as e:
        raise HTTPException(500, str(e))


@router.get("/radio/{video_id}")
async def get_radio(video_id: str, limit: int = 25):
    try:
        return yt_service.get_client().get_watch_playlist(videoId=video_id, limit=limit)
    except Exception as e:
        raise HTTPException(500, str(e))


@router.get("/albums/{browse_id}")
async def get_album(browse_id: str):
    try:
        return yt_service.get_client().get_album(browseId=browse_id)
    except Exception as e:
        raise HTTPException(500, str(e))


@router.get("/feed")
async def get_feed(limit: int = 4):
    """Raw ytmusicapi home shelves."""
    try:
        return yt_service.get_client().get_home(limit=limit)
    except Exception as e:
        raise HTTPException(500, str(e))


@router.post("/v1/playlists")
async def create_playlist(req: CreatePlaylistRequest):
    try:
        res = yt_service.get_client().create_playlist(
            title=req.title,
            description=req.description,
            privacy_status=req.privacy_status,
            video_ids=req.video_ids,
            source_playlist=req.source_playlist,
        )
        return {"id": res}
    except Exception as e:
        raise HTTPException(500, str(e))


@router.patch("/v1/playlists/{playlist_id}")
async def edit_playlist(playlist_id: str, req: EditPlaylistRequest):
    try:
        res = yt_service.get_client().edit_playlist(
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


@router.delete("/v1/playlists/{playlist_id}")
async def delete_playlist(playlist_id: str):
    try:
        res = yt_service.get_client().delete_playlist(playlistId=playlist_id)
        return {"status": res}
    except Exception as e:
        raise HTTPException(500, str(e))


@router.post("/v1/playlists/{playlist_id}/items")
async def add_playlist_items(playlist_id: str, req: AddPlaylistItemsRequest):
    try:
        res = yt_service.get_client().add_playlist_items(
            playlistId=playlist_id,
            videoIds=req.videoIds,
            source_playlist=req.source_playlist,
            duplicates=req.duplicates,
        )
        return {"status": res}
    except Exception as e:
        raise HTTPException(500, str(e))


@router.delete("/v1/playlists/{playlist_id}/items")
async def remove_playlist_items(playlist_id: str, req: RemovePlaylistItemsRequest):
    try:
        res = yt_service.get_client().remove_playlist_items(
            playlistId=playlist_id, videos=req.videos
        )
        return {"status": res}
    except Exception as e:
        raise HTTPException(500, str(e))


# --- Auth Endpoints ---


@router.get("/status")
async def status():
    return {"authenticated": os.path.exists(settings.AUTH_FILE_PATH)}


@router.post("/auth")
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
        ytmusicapi.setup(settings.AUTH_FILE_PATH, headers_raw=headers_raw)
        write_cookie_file(settings.AUTH_FILE_PATH, settings.COOKIES_FILE_PATH)
        yt_service.clear_cache()
        return {"status": "ok", "message": "Authenticated successfully"}
    except Exception as e:
        raise HTTPException(400, f"Auth setup failed: {e}")


@router.delete("/auth")
async def logout():
    if os.path.exists(settings.AUTH_FILE_PATH):
        os.remove(settings.AUTH_FILE_PATH)
    yt_service.clear_cache()
    return {"status": "ok", "message": "Logged out"}


# --- Streaming & Proxy ---


@router.get("/stream/{video_id}")
async def stream_audio(video_id: str, request: Request):
    try:
        audio_url = extract_audio_url(video_id)
    except Exception as e:
        raise HTTPException(500, f"Extraction failed: {e}")

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


@router.get("/proxy-image")
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
