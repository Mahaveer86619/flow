import asyncio
import json
import logging
import os
import time
import traceback
from datetime import datetime, timedelta
from typing import Dict, List, Optional

import yt_dlp
import ytmusicapi
from anyio.to_thread import run_sync
from jose import JWTError, jwt

# from passlib.context import CryptContext
from sqlalchemy.orm import Session

from .config import settings
from .models import ArtistResponse, HomeResponse, SongResponse, User
from .utils import (
    is_artist_item,
    normalize_artist,
    normalize_playlist,
    normalize_song,
    write_cookie_file,
)

logger = logging.getLogger("flow.services")

# Password hashing — bcrypt disabled for now (passlib/bcrypt version mismatch)
# pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AuthService:
    @staticmethod
    def verify_password(plain_password, hashed_password):
        # return pwd_context.verify(plain_password, hashed_password)
        return plain_password == hashed_password

    @staticmethod
    def get_password_hash(password):
        # return pwd_context.hash(password)
        return password

    @staticmethod
    def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=15)
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(
            to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM
        )
        return encoded_jwt


class YTMusicService:
    def __init__(self):
        # We no longer rely on a global settings.AUTH_FILE_PATH for all requests
        self.home_cache = {}
        self.home_cache_ttl = 300
        self._shelf_map = [
            (["quick pick", "top pick", "start radio"], "quickPicks"),
            (["listen again", "listening again", "continue"], "listeningAgain"),
            (["fresh find", "new release", "latest", "just out"], "freshFinds"),
            (["picked for you", "for you", "mixed", "your", "personalized", "discover"], "pickedForYou"),
            (["forgotten", "throwback", "rediscover", "missed"], "forgottenFavorites"),
            (["album", "mpreb"], "albumsForYou"),
            (["mood", "genre", "vibe", "energy", "workout", "focus", "relax"], "moodsAndGenres"),
            (["top chart", "trending", "popular", "global", "hits"], "trending"),
            (["similar to", "related to", "based on", "recommended"], "similarTo"),
        ]

    def get_client(self, user: Optional[User] = None):
        if user and user.yt_auth_json:
            try:
                logger.debug(f"Creating authenticated client for user: {user.username}")
                auth_data = json.loads(user.yt_auth_json)
                return ytmusicapi.YTMusic(auth=auth_data)
            except Exception as e:
                logger.error(f"Failed to parse YT auth for user {user.username}: {e}")
                # Fallback to unauthenticated if parse fails

        # Check if a global auth file still exists (for backward compatibility or shared dev)
        if os.path.exists(settings.AUTH_FILE_PATH):
            logger.debug(
                f"Creating authenticated client from global file: {settings.AUTH_FILE_PATH}"
            )
            return ytmusicapi.YTMusic(settings.AUTH_FILE_PATH)

        logger.debug("Creating unauthenticated YTMusic client")
        return ytmusicapi.YTMusic()

    def _classify_shelf(self, title: str) -> Optional[str]:
        t = title.lower()
        for keywords, section in self._shelf_map:
            if any(k in t for k in keywords):
                return section
        return None

    def _get_trending_songs(
        self, ytm, proxy_base: Optional[str] = None
    ) -> List[SongResponse]:
        try:
            charts = ytm.get_charts(country="ZZ")
            songs_chart = charts.get("songs") or {}
            items = songs_chart.get("items") or []
            if not items:
                trending_chart = charts.get("trending") or {}
                items = trending_chart.get("items") or []
            return [s for item in items[:20] if (s := normalize_song(item, proxy_base))]
        except Exception:
            return []

    def build_home_data(
        self,
        user: Optional[User] = None,
        limit: int = 25,
        proxy_base: Optional[str] = None,
    ) -> HomeResponse:
        logger.info(f"Building home data for user: {user.username if user else 'anon'}")
        try:
            ytm = self.get_client(user)
            raw_shelves = ytm.get_home(limit=limit)
            logger.debug(f"Fetched {len(raw_shelves)} raw shelves from YTMusic")
        except Exception as e:
            logger.error(
                f"ytmusicapi.get_home failed for user {user.username if user else 'anon'}: {e}"
            )
            return HomeResponse(shelves=[], trending=[])

        shelves = []
        seen_ids = set()

        for raw_shelf in raw_shelves:
            if not isinstance(raw_shelf, dict):
                continue
            title = raw_shelf.get("title") or "Recommended"
            contents = raw_shelf.get("contents") or []

            items = []
            for item in contents:
                if not isinstance(item, dict):
                    continue
                # Deduplicate songs specifically
                video_id = item.get("videoId")
                if video_id:
                    if video_id in seen_ids:
                        continue
                    seen_ids.add(video_id)
                    try:
                        song = normalize_song(item, proxy_base)
                        if song:
                            items.append({"type": "song", "data": song.model_dump()})
                    except Exception as e:
                        logger.warning(f"Failed to normalize song {video_id}: {e}")
                elif is_artist_item(item):
                    try:
                        artist = normalize_artist(item, proxy_base)
                        if artist:
                            items.append(
                                {"type": "artist", "data": artist.model_dump()}
                            )
                    except Exception as e:
                        logger.warning(f"Failed to normalize artist: {e}")
                elif "playlistId" in item or "browseId" in item:
                    # Could be playlist or album
                    is_album = str(item.get("browseId", "")).startswith("MPREb")
                    try:
                        playlist = normalize_playlist(item, proxy_base)
                        if playlist:
                            items.append(
                                {
                                    "type": "album" if is_album else "playlist",
                                    "data": playlist.model_dump(),
                                }
                            )
                    except Exception as e:
                        logger.warning(f"Failed to normalize playlist/album: {e}")

            if items:
                section = self._classify_shelf(title) or "musicForYou"
                shelves.append({"title": title, "section": section, "items": items})

        trending = self._get_trending_songs(ytm, proxy_base)

        profile_url = f"https://api.dicebear.com/7.x/avataaars/svg?seed={user.username if user else 'anon'}"
        if proxy_base:
            # Proxy doesn't handle SVG well, but let's keep it direct for now or use a JPG source
            profile_url = (
                f"https://i.pravatar.cc/150?u={user.username if user else 'anon'}"
            )

        return HomeResponse(shelves=shelves, trending=trending, profileUrl=profile_url)

    def get_home_cached(
        self,
        user: Optional[User] = None,
        limit: int = 5,
        proxy_base: Optional[str] = None,
    ) -> HomeResponse:
        now = time.monotonic()
        # Per-user cache key
        user_id = user.id if user else "anon"
        cache_key = f"home_{user_id}"

        if (
            self.home_cache.get(cache_key)
            and self.home_cache[cache_key].get("ts", 0) + self.home_cache_ttl > now
        ):
            return self.home_cache[cache_key]["data"]

        data = self.build_home_data(user, limit, proxy_base)
        self.home_cache[cache_key] = {"ts": now, "data": data}
        return data

    def build_feed_data(self, proxy_base: Optional[str] = None) -> HomeResponse:
        ytm = ytmusicapi.YTMusic()
        trending = self._get_trending_songs(ytm, proxy_base)
        shelves = []

        music_for_you_items = []
        try:
            raw_shelves = ytm.get_home(limit=3)
            seen = set()
            for shelf in raw_shelves:
                for item in shelf.get("contents") or []:
                    song = normalize_song(item, proxy_base)
                    if song and song.id not in seen:
                        seen.add(song.id)
                        music_for_you_items.append(
                            {"type": "song", "data": song.model_dump()}
                        )
                        if len(music_for_you_items) >= 20:
                            break
                if len(music_for_you_items) >= 20:
                    break
        except Exception:
            pass

        if music_for_you_items:
            shelves.append(
                {
                    "title": "Music For You",
                    "section": "musicForYou",
                    "items": music_for_you_items,
                }
            )

        return HomeResponse(
            shelves=shelves,
            trending=trending,
        )

    def get_feed_cached(self, proxy_base: Optional[str] = None) -> HomeResponse:
        now = time.monotonic()
        cached = self.home_cache.get("feed")
        if cached and cached.get("ts", 0) + self.home_cache_ttl > now:
            return cached["data"]
        data = self.build_feed_data(proxy_base)
        self.home_cache["feed"] = {"ts": now, "data": data}
        return data

    def clear_cache(self, user_id: Optional[int] = None):
        if user_id:
            cache_key = f"home_{user_id}"
            if cache_key in self.home_cache:
                del self.home_cache[cache_key]
        else:
            self.home_cache.clear()


# Global cache for extracted audio URLs to avoid slow yt-dlp calls on every request.
# Format: {video_id: (url, expiry_timestamp)}
_url_cache = {}
_extraction_locks: Dict[str, asyncio.Lock] = {}

try:
    import curl_cffi  # noqa: F401
    from yt_dlp.networking.impersonate import ImpersonateTarget

    # yt-dlp 2025.01.15+ expects an ImpersonateTarget object when using
    # the programmatic API. Passing a string like "chrome" causes an empty
    # AssertionError because it's not pre-parsed as it is in the CLI.
    _IMPERSONATE_TARGET: Optional[ImpersonateTarget] = ImpersonateTarget.from_str(
        "chrome"
    )
    logger.info("curl-cffi available — browser impersonation enabled (chrome)")
except (ImportError, AttributeError):
    _IMPERSONATE_TARGET = None
    logger.warning(
        "curl-cffi not installed or old yt-dlp — browser impersonation disabled. "
        "Rebuild the Docker image: docker compose build --no-cache flow-api"
    )


async def extract_audio_url(video_id: str, user: Optional[User] = None) -> str:
    now = time.monotonic()
    if video_id in _url_cache:
        url, expiry = _url_cache[video_id]
        if now < expiry:
            logger.debug(f"Cache hit for {video_id}")
            return url

    logger.info(f"Cache miss for {video_id}, extracting...")
    # Use a lock to prevent concurrent extractions for the same video_id
    if video_id not in _extraction_locks:
        _extraction_locks[video_id] = asyncio.Lock()

    async with _extraction_locks[video_id]:
        # Double-check cache inside the lock
        if video_id in _url_cache:
            url, expiry = _url_cache[video_id]
            if now < expiry:
                logger.debug(f"Cache hit for {video_id} (inside lock)")
                return url

        return await run_sync(_extract_sync, video_id, user)


def _extract_sync(video_id: str, user: Optional[User] = None) -> str:
    now = time.monotonic()

    # 0. Fast path: (Disabled for now - ytmusicapi get_song() URLs often return 403
    #    because they lack proper 'n' parameter deciphering handled by yt-dlp).
    # if user and user.yt_auth_json:
    #     try:
    #         ytm = yt_service.get_client(user)
    #         song = ytm.get_song(video_id)
    #         streaming = song.get("streamingData") or {}
    #         candidates = (streaming.get("adaptiveFormats") or []) + (
    #             streaming.get("formats") or []
    #         )
    #         audio = [
    #             f
    #             for f in candidates
    #             if f.get("mimeType", "").startswith("audio/")
    #             and f.get("url")  # skip ciphered (signatureCipher) entries
    #         ]
    #         if audio:
    #             audio.sort(key=lambda f: f.get("averageBitrate", 0), reverse=True)
    #             url = audio[0]["url"]
    #             _url_cache[video_id] = (url, now + 1800)  # 30 min — stream URLs expire
    #             logger.info(
    #                 f"Got stream URL via ytmusicapi for {video_id}: "
    #                 f"mime={audio[0].get('mimeType')} bitrate={audio[0].get('averageBitrate')}"
    #             )
    #             return url
    #         else:
    #             logger.debug(
    #                 f"ytmusicapi get_song returned {len(candidates)} formats but none "
    #                 f"with a direct URL for {video_id} — falling back to yt-dlp"
    #             )
    #     except Exception as e:
    #         logger.debug(f"ytmusicapi fast path failed for {video_id}: {e}")

    # 1. Build cookie paths — user-specific first, then global, then unauthenticated
    cookie_paths: List[Optional[str]] = []
    if user and user.yt_auth_json:
        data_dir = os.path.dirname(settings.COOKIES_FILE_PATH)
        temp_cookie_path = os.path.join(data_dir, f"cookies_{user.id}.txt")
        if write_cookie_file(user.yt_auth_json, temp_cookie_path):
            cookie_paths.append(temp_cookie_path)
    if os.path.exists(settings.COOKIES_FILE_PATH):
        cookie_paths.append(settings.COOKIES_FILE_PATH)
    cookie_paths.append(None)

    logger.info(
        f"_extract_sync {video_id}: trying {len(cookie_paths)} cookie path(s): "
        + ", ".join(repr(cp) for cp in cookie_paths)
    )

    imp = _IMPERSONATE_TARGET
    strategies = [
        {
            "name": f"ios{'+imp' if imp else ''}",
            "player_clients": ["ios"],
            "format": "bestaudio[ext=m4a]/bestaudio/best",
            "impersonate": imp,
        },
        {
            "name": f"web{'+imp' if imp else ''}",
            "player_clients": ["web"],
            "format": "bestaudio[ext=m4a]/bestaudio/best",
            "impersonate": imp,
        },
        {
            "name": f"android_vr{'+imp' if imp else ''}",
            "player_clients": ["android_vr"],
            "format": "bestaudio/best",
            "impersonate": imp,
        },
    ]

    yt_url = f"https://www.youtube.com/watch?v={video_id}"

    for strategy in strategies:
        logger.debug(f"Trying extraction strategy: {strategy['name']} for {video_id}")
        for cp in cookie_paths:
            logger.debug(f"Using cookie path: {cp} for strategy {strategy['name']}")
            ydl_opts: dict = {
                "quiet": True,
                "no_warnings": True,
                "nocheckcertificate": True,
                "noplaylist": True,
                "format": strategy["format"],
                "cookiefile": cp,
                "js_runtimes": {
                    "node": {}
                },  # required for signature solving in yt-dlp 2025.01.15+
                "extractor_args": {
                    "youtube": {
                        "player_client": strategy["player_clients"],
                    }
                },
            }
            if strategy.get("impersonate"):
                ydl_opts["impersonate"] = strategy["impersonate"]

            try:
                with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                    info = ydl.extract_info(yt_url, download=False)
                if not info:
                    continue

                # When a format string is set, yt-dlp sets info['url'] to the
                # direct URL of the selected stream.
                final_url = info.get("url")
                if not final_url:
                    # Fallback: scan formats list manually
                    audio_only = [
                        f
                        for f in (info.get("formats") or [])
                        if f.get("vcodec") == "none"
                        and f.get("acodec") not in (None, "none")
                        and f.get("url")
                    ]
                    audio_only.sort(
                        key=lambda f: float(f.get("abr") or f.get("tbr") or 0),
                        reverse=True,
                    )
                    final_url = audio_only[0]["url"] if audio_only else None

                if not final_url:
                    logger.warning(
                        f"Strategy {strategy['name']} (cookies={'yes' if cp else 'no'}) "
                        f"got info but no URL for {video_id} "
                        f"(ext={info.get('ext')} formats={len(info.get('formats') or [])})"
                    )
                    continue

                _url_cache[video_id] = (final_url, now + 3600)
                logger.info(
                    f"Extracted URL ({strategy['name']}, cookies={'yes' if cp else 'no'}) "
                    f"for {video_id}: ext={info.get('ext')} abr={info.get('abr')}kbps"
                )
                return final_url

            except Exception as e:
                logger.warning(
                    f"Strategy {strategy['name']} (cookies={'yes' if cp else 'no'}) "
                    f"failed for {video_id}: {e}"
                )
                continue

    raise Exception(f"Extraction failed for {video_id} after all strategies")


yt_service = YTMusicService()
auth_service = AuthService()
