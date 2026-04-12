import json
import logging
import os
import tempfile
import urllib.parse
from datetime import timedelta
from typing import List, Optional

import httpx
import ytmusicapi
from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from fastapi.responses import StreamingResponse
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from .config import settings
from .database import get_db
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
    Token,
    User,
    UserCreate,
    UserLogin,
    UserResponse,
    YTCookiesPayload,
)
from .services import auth_service, extract_audio_url, yt_service
from .utils import (
    curl_to_headers,
    normalize_artist,
    normalize_playlist,
    normalize_song,
    write_cookie_file,
)

router = APIRouter()


@router.get("/health")
async def health_check():
    return {"status": "ok"}


logger = logging.getLogger("uvicorn")

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="v1/auth/login")

_shared_client: Optional[httpx.AsyncClient] = None


def get_shared_client():
    global _shared_client
    if _shared_client is None:
        _shared_client = httpx.AsyncClient(
            timeout=httpx.Timeout(120.0, connect=10.0),
            follow_redirects=True,
            limits=httpx.Limits(max_connections=100, max_keepalive_connections=20),
        )
    return _shared_client


async def close_shared_client():
    global _shared_client
    if _shared_client is not None:
        await _shared_client.aclose()
        _shared_client = None


async def get_current_user(
    token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)
):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    user = db.query(User).filter(User.username == username).first()
    if user is None:
        raise credentials_exception
    return user


def _require_yt_auth(user: User):
    """Raise 401 if the user has no YT credentials configured."""
    if not user.yt_auth_json:
        # Check if a global fallback exists (optional, based on services.py logic)
        if not os.path.exists(settings.AUTH_FILE_PATH):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="YT Music not connected. Please connect your account first.",
            )


# --- User Management Endpoints ---


@router.post("/auth/signup", response_model=UserResponse)
async def signup(user_in: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.username == user_in.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")

    hashed_password = auth_service.get_password_hash(user_in.password)
    new_user = User(
        username=user_in.username,
        email=user_in.email,
        hashed_password=hashed_password,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    response = UserResponse.from_orm(new_user)
    response.has_yt_auth = bool(new_user.yt_auth_json)
    return response


@router.post("/auth/login", response_model=Token)
async def login(
    db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()
):
    user = db.query(User).filter(User.username == form_data.username).first()
    if not user or not auth_service.verify_password(
        form_data.password, user.hashed_password
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth_service.create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


@router.get("/auth/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_user)):
    response = UserResponse.from_orm(current_user)
    response.has_yt_auth = bool(current_user.yt_auth_json)
    return response


# --- Home & Feed Endpoints ---


@router.get("/home", response_model=HomeResponse)
async def get_home(
    request: Request, limit: int = 25, current_user: User = Depends(get_current_user)
):
    try:
        proxy_base = str(request.url_for("proxy_image"))
        return yt_service.get_home_cached(current_user, limit, proxy_base=proxy_base)
    except Exception as e:
        logger.exception(f"Error in get_home: {e}")
        raise HTTPException(500, str(e))


@router.get("/home/quick-access", response_model=List[SongResponse])
async def quick_access(current_user: User = Depends(get_current_user)):
    return (await get_home(current_user=current_user)).quickAccess


@router.get("/home/listening-again", response_model=List[SongResponse])
async def listening_again(current_user: User = Depends(get_current_user)):
    return (await get_home(current_user=current_user)).listeningAgain


@router.get("/home/forgotten-favorites", response_model=List[SongResponse])
async def forgotten_favorites(current_user: User = Depends(get_current_user)):
    return (await get_home(current_user=current_user)).forgottenFavorites


@router.get("/home/music-for-you", response_model=List[SongResponse])
async def music_for_you(current_user: User = Depends(get_current_user)):
    return (await get_home(current_user=current_user)).musicForYou


@router.get("/home/trending-artists", response_model=List[ArtistResponse])
async def trending_artists(current_user: User = Depends(get_current_user)):
    return (await get_home(current_user=current_user)).trendingArtists


@router.delete("/home/cache")
async def clear_home_cache(current_user: User = Depends(get_current_user)):
    yt_service.clear_cache(current_user.id)
    return {"status": "ok", "message": "Your home cache cleared"}


@router.get("/feed", response_model=HomeResponse)
async def get_feed(request: Request):
    try:
        proxy_base = str(request.url_for("proxy_image"))
        return yt_service.get_feed_cached(proxy_base=proxy_base)
    except Exception as e:
        raise HTTPException(500, str(e))


# --- Search Endpoints ---


@router.get("/search/songs", response_model=List[SongResponse])
async def search_songs(
    request: Request,
    q: str,
    limit: int = 20,
    current_user: User = Depends(get_current_user),
):
    if not q.strip():
        raise HTTPException(400, "Query is empty")
    try:
        proxy_base = str(request.url_for("proxy_image"))
        results = yt_service.get_client(current_user).search(
            q, filter="songs", limit=limit
        )
        return [s for item in results if (s := normalize_song(item, proxy_base))]
    except Exception as e:
        raise HTTPException(500, str(e))


@router.get("/search/suggestions")
async def get_search_suggestions(
    q: str, current_user: User = Depends(get_current_user)
):
    try:
        return yt_service.get_client(current_user).get_search_suggestions(q)
    except Exception as e:
        raise HTTPException(500, str(e))


# --- Library & History Endpoints ---


@router.get("/library", response_model=LibraryResponse)
async def get_library(request: Request, current_user: User = Depends(get_current_user)):
    _require_yt_auth(current_user)
    try:
        proxy_base = str(request.url_for("proxy_image"))
        raw = yt_service.get_client(current_user).get_library_playlists(limit=100)
        return LibraryResponse(
            playlists=[normalize_playlist(p, proxy_base) for p in raw]
        )
    except Exception as e:
        raise HTTPException(500, str(e))


@router.get("/history", response_model=List[SongResponse])
async def get_history(request: Request, current_user: User = Depends(get_current_user)):
    _require_yt_auth(current_user)
    try:
        proxy_base = str(request.url_for("proxy_image"))
        raw = yt_service.get_client(current_user).get_history()
        return [s for item in raw if (s := normalize_song(item, proxy_base))]
    except Exception as e:
        raise HTTPException(500, str(e))


# --- Browsing & Content Endpoints ---


@router.get("/playlists/{playlist_id}/tracks", response_model=List[SongResponse])
async def get_playlist_tracks(
    request: Request,
    playlist_id: str,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
):
    try:
        proxy_base = str(request.url_for("proxy_image"))
        actual_limit = None if limit <= 0 else limit
        data = yt_service.get_client(current_user).get_playlist(
            playlistId=playlist_id, limit=actual_limit
        )
        tracks = data.get("tracks") or []
        return [s for item in tracks if (s := normalize_song(item, proxy_base))]
    except Exception as e:
        raise HTTPException(500, str(e))


@router.get("/radio/{video_id}")
async def get_radio(
    request: Request,
    video_id: str,
    limit: int = 25,
    current_user: User = Depends(get_current_user),
):
    try:
        proxy_base = str(request.url_for("proxy_image"))
        data = yt_service.get_client(current_user).get_watch_playlist(
            videoId=video_id, limit=limit
        )
        tracks = data.get("tracks") or []
        return [s for item in tracks if (s := normalize_song(item, proxy_base))]
    except Exception as e:
        raise HTTPException(500, str(e))


@router.get("/albums/{browse_id}")
async def get_album(browse_id: str, current_user: User = Depends(get_current_user)):
    try:
        return yt_service.get_client(current_user).get_album(browseId=browse_id)
    except Exception as e:
        raise HTTPException(500, str(e))


@router.get("/artists/{channel_id}")
async def get_artist(channel_id: str, current_user: User = Depends(get_current_user)):
    try:
        return yt_service.get_client(current_user).get_artist(channelId=channel_id)
    except Exception as e:
        raise HTTPException(500, str(e))


@router.get("/songs/lyrics/{video_id}")
async def get_lyrics(video_id: str, current_user: User = Depends(get_current_user)):
    try:
        client = yt_service.get_client(current_user)
        watch = client.get_watch_playlist(videoId=video_id)
        lyrics_id = watch.get("lyrics")
        if not lyrics_id:
            return {"lyrics": None}
        return client.get_lyrics(lyrics_id)
    except Exception as e:
        raise HTTPException(500, str(e))


@router.get("/songs/batch", response_model=List[SongResponse])
async def get_songs_batch(
    request: Request, ids: str, current_user: User = Depends(get_current_user)
):
    """Fetch multiple songs by a comma-separated list of IDs."""
    if not ids.strip():
        return []
    video_ids = [vid.strip() for vid in ids.split(",") if vid.strip()]
    try:
        proxy_base = str(request.url_for("proxy_image"))
        client = yt_service.get_client(current_user)
        results = []
        for vid in video_ids:
            try:
                # get_song returns a dict with basic info
                data = client.get_song(vid)
                if data and "videoDetails" in data:
                    # Map YT Music videoDetails to our SongResponse
                    details = data["videoDetails"]
                    raw_thumb = (
                        details.get("thumbnail", {})
                        .get("thumbnails", [{}])[-1]
                        .get("url")
                    )
                    results.append(
                        SongResponse(
                            id=details["videoId"],
                            title=details["title"],
                            artist=details["author"],
                            album="",  # Not always in videoDetails
                            durationMs=int(details["lengthSeconds"]) * 1000,
                            thumbnailUrl=fix_thumbnail_url(raw_thumb, proxy_base),
                        )
                    )
            except Exception as e:
                logger.warning(f"Failed to fetch batch song {vid}: {e}")
                continue
        return results
    except Exception as e:
        raise HTTPException(500, str(e))


# --- Playlist Management Endpoints ---


@router.post("/playlists")
async def create_playlist(
    req: CreatePlaylistRequest, current_user: User = Depends(get_current_user)
):
    _require_yt_auth(current_user)
    try:
        res = yt_service.get_client(current_user).create_playlist(
            title=req.title,
            description=req.description,
            privacy_status=req.privacy_status,
            video_ids=req.video_ids,
            source_playlist=req.source_playlist,
        )
        return {"id": res}
    except Exception as e:
        raise HTTPException(500, str(e))


@router.patch("/playlists/{playlist_id}")
async def edit_playlist(
    playlist_id: str,
    req: EditPlaylistRequest,
    current_user: User = Depends(get_current_user),
):
    _require_yt_auth(current_user)
    try:
        res = yt_service.get_client(current_user).edit_playlist(
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


@router.delete("/playlists/{playlist_id}")
async def delete_playlist(
    playlist_id: str, current_user: User = Depends(get_current_user)
):
    _require_yt_auth(current_user)
    try:
        res = yt_service.get_client(current_user).delete_playlist(
            playlistId=playlist_id
        )
        return {"status": res}
    except Exception as e:
        raise HTTPException(500, str(e))


@router.post("/playlists/{playlist_id}/items")
async def add_playlist_items(
    playlist_id: str,
    req: AddPlaylistItemsRequest,
    current_user: User = Depends(get_current_user),
):
    _require_yt_auth(current_user)
    try:
        res = yt_service.get_client(current_user).add_playlist_items(
            playlistId=playlist_id,
            videoIds=req.videoIds,
            source_playlist=req.source_playlist,
            duplicates=req.duplicates,
        )
        return {"status": res}
    except Exception as e:
        raise HTTPException(500, str(e))


@router.delete("/playlists/{playlist_id}/items")
async def remove_playlist_items(
    playlist_id: str,
    req: RemovePlaylistItemsRequest,
    current_user: User = Depends(get_current_user),
):
    _require_yt_auth(current_user)
    try:
        res = yt_service.get_client(current_user).remove_playlist_items(
            playlistId=playlist_id, videos=req.videos
        )
        return {"status": res}
    except Exception as e:
        raise HTTPException(500, str(e))


# --- YT Music Connection Management (Per User) ---


@router.get("/yt-status")
async def yt_status(current_user: User = Depends(get_current_user)):
    return {"connected": bool(current_user.yt_auth_json)}


@router.post("/yt-auth")
async def setup_yt_auth(
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
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
        # We use a temporary file to let ytmusicapi parse and validate the headers
        with tempfile.NamedTemporaryFile(
            mode="w+", suffix=".json", delete=False
        ) as tmp:
            tmp_path = tmp.name

        try:
            ytmusicapi.setup(tmp_path, headers_raw=headers_raw)
            with open(tmp_path, "r") as f:
                auth_data = json.load(f)

            # Update user in DB
            current_user.yt_auth_json = json.dumps(auth_data)
            db.add(current_user)
            db.commit()

            yt_service.clear_cache(current_user.id)
            return {"status": "ok", "message": "YouTube Music connected successfully"}
        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

    except Exception as e:
        raise HTTPException(400, f"Auth setup failed: {e}")


@router.post("/yt-auth/cookies")
async def setup_yt_auth_cookies(
    payload: YTCookiesPayload,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    cookie_str = "; ".join(f"{k}={v}" for k, v in payload.cookies.items())
    headers_raw = f"Cookie: {cookie_str}\nX-Goog-AuthUser: 0\n"
    try:
        with tempfile.NamedTemporaryFile(
            mode="w+", suffix=".json", delete=False
        ) as tmp:
            tmp_path = tmp.name
        try:
            ytmusicapi.setup(tmp_path, headers_raw=headers_raw)
            with open(tmp_path, "r") as f:
                auth_data = json.load(f)
            current_user.yt_auth_json = json.dumps(auth_data)
            db.add(current_user)
            db.commit()
            yt_service.clear_cache(current_user.id)
            return {"status": "ok", "message": "YouTube Music connected successfully"}
        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
    except Exception as e:
        raise HTTPException(400, f"Auth setup failed: {e}")


@router.delete("/yt-auth")
async def yt_logout(
    current_user: User = Depends(get_current_user), db: Session = Depends(get_db)
):
    current_user.yt_auth_json = None
    db.add(current_user)
    db.commit()
    yt_service.clear_cache(current_user.id)
    return {"status": "ok", "message": "YouTube Music disconnected"}


# --- Streaming & Proxy ---


@router.get("/prefetch/{video_id}")
async def prefetch_audio(video_id: str, current_user: User = Depends(get_current_user)):
    """
    Proactively trigger extraction for a video_id to warm up the cache.
    """
    logger.info(f"Prefetch request for {video_id}")
    # Run extraction in the background (extract_audio_url has its own locking)
    asyncio.create_task(extract_audio_url(video_id, user=current_user))
    return {"status": "ok", "video_id": video_id}


@router.get("/stream/{video_id}")
async def stream_audio(
    video_id: str, request: Request, current_user: User = Depends(get_current_user)
):
    logger.info(f"Streaming request for {video_id} from {request.client.host}")
    try:
        audio_url = await extract_audio_url(video_id, user=current_user)
    except Exception as e:
        logger.error(f"Extraction failed for {video_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Extraction failed: {e}",
        )

    upstream_headers = {}
    if "range" in request.headers:
        upstream_headers["range"] = request.headers["range"]
        logger.info(f"Range request: {request.headers['range']} for {video_id}")

    # We'll use a standard Chrome User-Agent to match the impersonation used by yt-dlp
    upstream_headers.update(
        {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
            "Referer": "https://www.youtube.com/",
            "Connection": "keep-alive",
        }
    )

    client = get_shared_client()
    try:
        # We use a stream context to ensure the connection is closed
        request_to_upstream = httpx.Request("GET", audio_url, headers=upstream_headers)
        upstream = await client.send(request_to_upstream, stream=True)

        logger.info(
            f"Upstream response for {video_id}: status={upstream.status_code} "
            f"content-type={upstream.headers.get('content-type')} "
            f"content-length={upstream.headers.get('content-length')} "
            f"range={upstream.headers.get('content-range')}"
        )

        if upstream.status_code >= 400:
            logger.error(f"Upstream returned {upstream.status_code} for {video_id}")
            # If forbidden or not found, try to clear cache so next request triggers re-extraction
            if upstream.status_code in (403, 410):
                from .services import _url_cache

                if video_id in _url_cache:
                    del _url_cache[video_id]

        passthrough = {
            k: v
            for k, v in upstream.headers.items()
            if k.lower()
            in (
                "content-type",
                "content-range",
                "accept-ranges",
                "etag",
                "last-modified",
            )
        }
        # Only pass content-length if we are serving a range or if we are sure it won't confuse the client
        if "content-length" in upstream.headers and "range" in request.headers:
            passthrough["content-length"] = upstream.headers["content-length"]

        if "accept-ranges" not in passthrough:
            passthrough["accept-ranges"] = "bytes"

        # Determine media type more robustly
        content_type = upstream.headers.get("content-type")
        if not content_type or content_type == "application/octet-stream":
            if ".googlevideo.com" in audio_url:
                if "mime=audio%2Fmp4" in audio_url or "mime=audio/mp4" in audio_url:
                    content_type = "audio/mp4"
                elif "mime=audio%2Fwebm" in audio_url or "mime=audio/webm" in audio_url:
                    content_type = "audio/webm"
                else:
                    content_type = "audio/webm"
            else:
                content_type = "audio/mpeg"

        logger.info(
            f"Serving stream for {video_id} as {content_type} with headers: {passthrough}"
        )

        async def _iter():
            logger.info(f"Starting to yield chunks for {video_id}")
            total_sent = 0
            try:
                # Use a smaller chunk size (64KB) to start playback faster
                async for chunk in upstream.aiter_bytes(65536):
                    if total_sent == 0:
                        logger.info(f"First chunk yielded for {video_id}")
                    total_sent += len(chunk)
                    yield chunk
                logger.info(
                    f"Finished streaming {video_id}: sent {total_sent} bytes total"
                )
            except Exception as e:
                # Client probably disconnected
                logger.warning(
                    f"Streaming interrupted for {video_id} after {total_sent} bytes: {e}"
                )
            finally:
                await upstream.aclose()

        return StreamingResponse(
            _iter(),
            status_code=upstream.status_code,
            headers=passthrough,
            media_type=content_type,
        )
    except Exception as e:
        import traceback

        logger.error(
            f"Upstream connection failed for {video_id}: {e}\n{traceback.format_exc()}"
        )
        raise HTTPException(status_code=502, detail=f"Upstream error: {e}")


@router.get("/proxy-image")
async def proxy_image(url: str):
    try:
        decoded_url = urllib.parse.unquote(url)
        client = get_shared_client()
        resp = await client.get(decoded_url)
        return Response(
            content=resp.content,
            media_type=resp.headers.get("Content-Type", "image/jpeg"),
        )
    except Exception as e:
        raise HTTPException(500, f"Image proxy failed: {e}")
