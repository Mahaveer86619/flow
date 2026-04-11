import json
import os
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional

import yt_dlp
import ytmusicapi
from jose import JWTError, jwt

# from passlib.context import CryptContext
from sqlalchemy.orm import Session

from .config import settings
from .models import ArtistResponse, HomeResponse, SongResponse, User
from .utils import is_artist_item, normalize_artist, normalize_song, write_cookie_file

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
            (["quick pick", "top pick"], "quickAccess"),
            (["listen again", "listening again", "continue"], "listeningAgain"),
            (["forgotten", "throwback", "rediscover", "missed"], "forgottenFavorites"),
            (
                [
                    "for you",
                    "recommended",
                    "mixed",
                    "new release",
                    "top chart",
                    "trending",
                    "chart",
                    "popular",
                ],
                "musicForYou",
            ),
        ]

    def get_client(self, user: Optional[User] = None):
        if user and user.yt_auth_json:
            try:
                auth_data = json.loads(user.yt_auth_json)
                return ytmusicapi.YTMusic(auth=auth_data)
            except Exception:
                # Fallback to unauthenticated if parse fails
                pass

        # Check if a global auth file still exists (for backward compatibility or shared dev)
        if os.path.exists(settings.AUTH_FILE_PATH):
            return ytmusicapi.YTMusic(settings.AUTH_FILE_PATH)

        return ytmusicapi.YTMusic()

    def _classify_shelf(self, title: str) -> Optional[str]:
        t = title.lower()
        for keywords, section in self._shelf_map:
            if any(k in t for k in keywords):
                return section
        return None

    def _get_trending_songs(self, ytm) -> List[SongResponse]:
        try:
            charts = ytm.get_charts(country="ZZ")
            songs_chart = charts.get("songs") or {}
            items = songs_chart.get("items") or []
            if not items:
                trending_chart = charts.get("trending") or {}
                items = trending_chart.get("items") or []
            return [s for item in items[:20] if (s := normalize_song(item))]
        except Exception:
            return []

    def build_home_data(
        self, user: Optional[User] = None, limit: int = 15
    ) -> HomeResponse:
        ytm = self.get_client(user)
        raw_shelves = ytm.get_home(limit=limit)

        shelves = []
        seen_ids = set()

        for raw_shelf in raw_shelves:
            title = raw_shelf.get("title") or "Recommended"
            contents = raw_shelf.get("contents") or []
            
            items = []
            for item in contents:
                # Deduplicate songs specifically
                video_id = item.get("videoId")
                if video_id:
                    if video_id in seen_ids:
                        continue
                    seen_ids.add(video_id)
                    song = normalize_song(item)
                    if song:
                        items.append({"type": "song", "data": song.model_dump()})
                elif is_artist_item(item):
                    artist = normalize_artist(item)
                    if artist:
                        items.append({"type": "artist", "data": artist.model_dump()})
                elif "playlistId" in item or "browseId" in item:
                    # Could be playlist or album
                    is_album = str(item.get("browseId", "")).startswith("MPREb")
                    playlist = normalize_playlist(item)
                    if playlist:
                        items.append({
                            "type": "album" if is_album else "playlist", 
                            "data": playlist.model_dump()
                        })

            if items:
                shelves.append({
                    "title": title,
                    "items": items
                })

        trending = self._get_trending_songs(ytm)

        return HomeResponse(shelves=shelves, trending=trending)

    def get_home_cached(
        self, user: Optional[User] = None, limit: int = 5
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

        data = self.build_home_data(user, limit)
        self.home_cache[cache_key] = {"ts": now, "data": data}
        return data

    def build_feed_data(self) -> HomeResponse:
        ytm = ytmusicapi.YTMusic()
        trending = self._get_trending_songs(ytm)
        shelves = []
        
        music_for_you_items = []
        try:
            raw_shelves = ytm.get_home(limit=3)
            seen = set()
            for shelf in raw_shelves:
                for item in shelf.get("contents") or []:
                    song = normalize_song(item)
                    if song and song.id not in seen:
                        seen.add(song.id)
                        music_for_you_items.append({"type": "song", "data": song.model_dump()})
                        if len(music_for_you_items) >= 20:
                            break
                if len(music_for_you_items) >= 20:
                    break
        except Exception:
            pass

        if music_for_you_items:
            shelves.append({
                "title": "Music For You",
                "items": music_for_you_items
            })

        return HomeResponse(
            shelves=shelves,
            trending=trending,
        )

    def get_feed_cached(self) -> HomeResponse:
        now = time.monotonic()
        cached = self.home_cache.get("feed")
        if cached and cached.get("ts", 0) + self.home_cache_ttl > now:
            return cached["data"]
        data = self.build_feed_data()
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


def extract_audio_url(video_id: str, user: Optional[User] = None) -> str:
    now = time.monotonic()
    # Cache valid for 1 hour
    if video_id in _url_cache:
        url, expiry = _url_cache[video_id]
        if now < expiry:
            return url

    user_agent = (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"
    )

    base_opts = {
        # Prefer direct HTTP progressive downloads to avoid manifest URLs
        "format": "bestaudio[protocol^=http]/bestaudio/best",
        "quiet": True,
        "no_warnings": True,
        "user_agent": user_agent,
        "nocheckcertificate": True,
        "ignoreerrors": False,
        "logtostderr": False,
    }

    # Highly reliable player client combinations for YT Music
    client_strategies = [
        ["android", "web"],
        ["ios"],
        ["tvhtml5", "web"],
        ["web_creator", "web"],
    ]

    # Strategy: Try with user cookies, then global cookies, then no cookies
    cookie_paths = []
    if user and user.yt_auth_json:
        data_dir = os.path.dirname(settings.COOKIES_FILE_PATH)
        temp_cookie_path = os.path.join(data_dir, f"cookies_{user.id}.txt")
        if write_cookie_file(user.yt_auth_json, temp_cookie_path):
            cookie_paths.append(temp_cookie_path)

    if os.path.exists(settings.COOKIES_FILE_PATH):
        cookie_paths.append(settings.COOKIES_FILE_PATH)

    cookie_paths.append(None)

    last_exception = None

    for cp in cookie_paths:
        for clients in client_strategies:
            ydl_opts = base_opts.copy()
            if cp:
                ydl_opts["cookiefile"] = cp

            ydl_opts["extractor_args"] = {
                "youtube": {
                    "player_client": clients,
                    # We skip manifests because our proxy logic only handles direct streams
                    "skip": ["webpage", "hls", "dash"],
                }
            }

            try:
                with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                    info = ydl.extract_info(
                        f"https://music.youtube.com/watch?v={video_id}",
                        download=False,
                    )
                    # Some clients might return a list of formats; we want the chosen one
                    if "url" in info:
                        final_url = info["url"]
                        _url_cache[video_id] = (final_url, now + 3600)
                        return final_url
            except Exception as e:
                last_exception = e
                # Log specific error for debugging if needed
                if "format is not available" in str(e).lower():
                    continue
                if "cookies" in str(e).lower() or "Netscape" in str(e):
                    # Current cookie file is bad, skip other strategies for this cp
                    break
                continue

    # Final emergency fallback: Broadest possible search on main YouTube URL
    for cp in cookie_paths:
        ydl_opts = base_opts.copy()
        ydl_opts["format"] = "bestaudio/best"  # Less restrictive
        if cp:
            ydl_opts["cookiefile"] = cp

        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                # Using the standard watch URL often has different availability
                info = ydl.extract_info(
                    f"https://www.youtube.com/watch?v={video_id}",
                    download=False,
                )
                if "url" in info:
                    final_url = info["url"]
                    _url_cache[video_id] = (final_url, now + 3600)
                    return final_url
        except Exception as e:
            last_exception = e
            continue
    if last_exception:
        raise last_exception
    raise Exception("Extraction failed with no results")


yt_service = YTMusicService()
auth_service = AuthService()
