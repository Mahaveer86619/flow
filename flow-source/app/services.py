import asyncio
import json
import logging
import os
import time
import traceback
from datetime import datetime, timedelta
from typing import Dict, List, Optional

import anyio
import yt_dlp
import ytmusicapi
from anyio.to_thread import run_sync
from jose import JWTError, jwt

# from passlib.context import CryptContext
from sqlalchemy.orm import Session

from .config import settings
from .models import ArtistResponse, HomeResponse, SongResponse, User, UserSongInteraction, UserRecommendation
from .utils import (
    is_artist_item,
    normalize_artist,
    normalize_playlist,
    normalize_song,
    normalize_album_as_song,
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
            (["listen again", "listening again", "continue", "recent"], "listeningAgain"),
            (["fresh find", "new release", "latest", "just out", "new arrival"], "freshFinds"),
            (
                [
                    "picked for you",
                    "for you",
                    "mixed",
                    "your",
                    "personalized",
                    "discover",
                    "mix",
                ],
                "pickedForYou",
            ),
            (["forgotten", "throwback", "rediscover", "missed"], "forgottenFavorites"),
            (["album", "mpreb"], "albumsForYou"),
            (
                ["mood", "genre", "vibe", "energy", "workout", "focus", "relax"],
                "moodsAndGenres",
            ),
            (["top chart", "trending", "popular", "global", "hits"], "trending"),
            (["similar to", "related to", "based on", "recommended", "fans", "might also like"], "similarTo"),
            (["artist spotlight", "from your fav"], "artistSpotlight"),
            (["video"], "musicVideos"),
        ]

    def get_client(self, user: Optional[User] = None):
        if user and user.yt_auth_json:
            import tempfile
            try:
                logger.debug(f"Creating authenticated client for user: {user.username}")
                
                # --- CRITICAL FIX: YTMusic Authentication ---
                # ytmusicapi (as of 1.10+) has a fundamental requirement: if auth is provided as 
                # a dictionary, it expects a very specific structure. If it's provided as a 
                # file path, it automatically delegates to the correct parser (Headers vs OAuth).
                # To support both legacy Header-based JSON and new OAuth JSON (which throws 
                # 'oauth_credentials not provided' if passed as a dict), we MUST write it 
                # to a temporary file first. This ensures 100% reliable initialization.
                with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as tmp:
                    tmp.write(user.yt_auth_json)
                    tmp_path = tmp.name
                
                try:
                    return ytmusicapi.YTMusic(auth=tmp_path)
                finally:
                    if os.path.exists(tmp_path):
                        os.remove(tmp_path)
            except Exception as e:
                logger.error(f"Failed to initialize YT auth for user {user.username}: {e}")
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

    def track_interaction(
        self,
        db: Session,
        user: User,
        song_id: str,
        genres: Optional[List[str]] = None,
    ):
        interaction = (
            db.query(UserSongInteraction)
            .filter(
                UserSongInteraction.user_id == user.id,
                UserSongInteraction.song_id == song_id,
            )
            .first()
        )

        if not interaction:
            interaction = UserSongInteraction(
                user_id=user.id,
                song_id=song_id,
                play_count=1,
                genre_tags=json.dumps(genres) if genres else None,
            )
            db.add(interaction)
        else:
            interaction.play_count += 1
            interaction.last_played_at = datetime.utcnow()
            if genres:
                existing_genres = (
                    json.loads(interaction.genre_tags) if interaction.genre_tags else []
                )
                updated_genres = list(set(existing_genres + genres))
                interaction.genre_tags = json.dumps(updated_genres)

        db.commit()

    def _get_fresh_picks(self, ytm, user: User, proxy_base: Optional[str] = None) -> List[dict]:
        """
        Lightweight recommendation system:
        1. Takes seeds from recent history (last 3 songs).
        2. Takes seeds from liked artists (up to 3).
        3. Fetches related tracks/radio for these seeds.
        4. Mixes with trending new releases.
        """
        try:
            import random
            recommendations = []
            seen_ids = set()

            # 1. Seeds from History
            try:
                history = ytm.get_history()
                history_seeds = [item.get("videoId") for item in history[:3] if item.get("videoId")]
                for video_id in history_seeds:
                    related = ytm.get_song_related(video_id)
                    # get_song_related returns a lot of data, we want tracks
                    # In newer versions it might be in 'tracks' or similar
                    # Often we can use get_watch_playlist for a radio-like experience
                    radio = ytm.get_watch_playlist(videoId=video_id, limit=5)
                    tracks = radio.get("tracks", [])
                    for t in tracks:
                        if t.get("videoId") and t["videoId"] not in seen_ids:
                            song = normalize_song(t, proxy_base)
                            if song:
                                recommendations.append({"type": "song", "data": song.model_dump()})
                                seen_ids.add(t["videoId"])
            except Exception as e:
                logger.warning(f"RecSys: History seeds failed: {e}")

            # 2. Seeds from Liked Artists
            try:
                liked_artists = ytm.get_library_artists(limit=10)
                if liked_artists:
                    random_artists = random.sample(liked_artists, min(len(liked_artists), 3))
                    for artist in random_artists:
                        artist_data = ytm.get_artist(artist['browseId'])
                        songs = artist_data.get("songs", {}).get("results", [])
                        for s in songs[:5]:
                            if s.get("videoId") and s["videoId"] not in seen_ids:
                                song = normalize_song(s, proxy_base)
                                if song:
                                    recommendations.append({"type": "song", "data": song.model_dump()})
                                    seen_ids.add(s["videoId"])
            except Exception as e:
                logger.warning(f"RecSys: Artist seeds failed: {e}")

            # 3. Seeds from Explore (Trending/New)
            try:
                explore = ytm.get_explore()
                new_releases = explore.get("new_releases", [])
                for item in new_releases[:10]:
                    song = normalize_album_as_song(item, proxy_base)
                    if song and song.id not in seen_ids:
                        recommendations.append({"type": "song", "data": song.model_dump()})
                        seen_ids.add(song.id)
            except Exception as e:
                logger.warning(f"RecSys: Explore seeds failed: {e}")

            random.shuffle(recommendations)
            return recommendations[:30] # Return a healthy chunk
        except Exception as e:
            logger.error(f"RecSys: Systemic failure: {e}")
            return []

    def build_home_data(
        self,
        user: Optional[User] = None,
        limit: int = 30,
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
        music_videos = []

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
                            # Check if it's a music video (heuristic: duration or type)
                            # ytmusicapi often identifies videos in specific shelves
                            if "Video" in title or item.get("resultType") == "video":
                                music_videos.append(song)
                            
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

        # --- FRESH PICKS: Lightweight Recommendation System ---
        fresh_picks = self._get_fresh_picks(ytm, user, proxy_base)
        if fresh_picks:
            # Remove any existing freshFinds to replace with our better RecSys
            shelves = [s for s in shelves if s["section"] != "freshFinds"]
            # Insert at top (index 0) or after quick access
            shelves.insert(0, {
                "title": "Fresh picks for you",
                "section": "freshFinds",
                "items": fresh_picks
            })

        # --- Explicitly fetch Quick Picks (from Liked Songs if missing) ---
        if not any(s["section"] == "quickPicks" for s in shelves):
            try:
                liked = ytm.get_liked_songs(limit=24)
                liked_tracks = liked.get("tracks", [])
                quick_pick_items = []
                for item in liked_tracks:
                    song = normalize_song(item, proxy_base)
                    if song:
                        quick_pick_items.append({"type": "song", "data": song.model_dump()})
                if quick_pick_items:
                    shelves.insert(0, {
                        "title": "Quick picks",
                        "section": "quickPicks",
                        "items": quick_pick_items
                    })
            except Exception as e:
                logger.warning(f"Failed to fetch fallback Quick Picks: {e}")

        # --- Explicitly fetch Listen Again (from History if missing) ---
        if not any(s["section"] == "listeningAgain" for s in shelves):
            try:
                history = ytm.get_history()
                listen_again_items = []
                seen_ids = set()
                for item in history:
                    video_id = item.get("videoId")
                    if video_id and video_id not in seen_ids:
                        song = normalize_song(item, proxy_base)
                        if song:
                            listen_again_items.append({"type": "song", "data": song.model_dump()})
                            seen_ids.add(video_id)
                    if len(listen_again_items) >= 20:
                        break
                if listen_again_items:
                    # Insert after Quick Picks
                    idx = 1 if any(s["section"] == "quickPicks" for s in shelves) else 0
                    shelves.insert(idx, {
                        "title": "Listen again",
                        "section": "listeningAgain",
                        "items": listen_again_items
                    })
            except Exception as e:
                logger.warning(f"Failed to fetch fallback Listen Again: {e}")

        # --- Explicitly fetch Music Videos ---
        if not any(s["section"] in ["musicVideos", "videoRecommendations"] for s in shelves):
            try:
                explore = ytm.get_explore()
                trending = explore.get("trending", {})
                trending_items = trending.get("items", [])
                video_items = []
                for item in trending_items:
                    # Trending items might be songs or videos
                    song = normalize_song(item, proxy_base)
                    if song:
                        video_items.append({"type": "song", "data": song.model_dump()})
                if video_items:
                    shelves.append({
                        "title": "Music videos for you",
                        "section": "musicVideos",
                        "items": video_items
                    })
            except Exception as e:
                logger.warning(f"Failed to fetch music videos: {e}")

        # --- Explicitly fetch New Arrivals (New Releases) ---
        if not any(s["section"] == "freshFinds" for s in shelves):
            try:
                explore = ytm.get_explore()
                new_releases = explore.get("new_releases", [])
                new_arrival_items = []
                for item in new_releases[:12]:
                    try:
                        song = normalize_album_as_song(item, proxy_base)
                        if song:
                            new_arrival_items.append({
                                "type": "song",
                                "data": song.model_dump()
                            })
                    except Exception:
                        continue
                if new_arrival_items:
                    shelves.append({
                        "title": "Fresh Finds",
                        "section": "freshFinds",
                        "items": new_arrival_items
                    })
            except Exception as e:
                logger.warning(f"Failed to fetch explicit new releases: {e}")

        # --- Explicitly fetch Popular Artists ---
        if not any(s["section"] == "trendingArtists" for s in shelves):
            try:
                charts = ytm.get_charts(country="ZZ")
                artists = charts.get("artists", [])
                artist_items = []
                for item in artists[:12]:
                    try:
                        artist = normalize_artist(item, proxy_base)
                        if artist:
                            artist_items.append({
                                "type": "artist",
                                "data": artist.model_dump()
                            })
                    except Exception:
                        continue
                if artist_items:
                    shelves.append({
                        "title": "Popular Artists",
                        "section": "trendingArtists",
                        "items": artist_items
                    })
            except Exception as e:
                logger.warning(f"Failed to fetch trending artists: {e}")

        # --- Fetch from Favorite Artists ---
        fav_artists_songs = []
        try:
            # Heuristic: find liked artists from library
            liked_artists = ytm.get_library_artists(limit=5)
            for artist in liked_artists:
                browse_id = artist.get("browseId")
                if browse_id:
                    artist_data = ytm.get_artist(browse_id)
                    # Get some songs from artist
                    for song_item in artist_data.get("songs", {}).get("results", [])[:4]:
                        song = normalize_song(song_item, proxy_base)
                        if song and song.id not in seen_ids:
                            seen_ids.add(song.id)
                            fav_artists_songs.append(song)
        except Exception as e:
            logger.warning(f"Failed to fetch favorite artists songs: {e}")

        trending = self._get_trending_songs(ytm, proxy_base)

        # --- Explicitly add specialty shelves ---
        if music_videos:
            shelves.append({
                "title": "Recommended Music Videos",
                "section": "musicVideos",
                "items": [{"type": "song", "data": s.model_dump()} for s in music_videos[:12]]
            })
        
        if fav_artists_songs:
            shelves.append({
                "title": "From Your Favorite Artists",
                "section": "favArtistsSongs",
                "items": [{"type": "song", "data": s.model_dump()} for s in fav_artists_songs[:12]]
            })

        profile_url = user.yt_avatar_url if user and user.yt_avatar_url else f"https://api.dicebear.com/7.x/avataaars/svg?seed={user.username if user else 'anon'}"
        if not user.yt_avatar_url and proxy_base:
            profile_url = (
                f"https://i.pravatar.cc/150?u={user.username if user else 'anon'}"
            )

        return HomeResponse(
            shelves=shelves, 
            trending=trending, 
            profileUrl=profile_url,
            yt_name=user.yt_name if user else None,
            musicVideos=music_videos,
            favArtistsSongs=fav_artists_songs
        )

    def get_user_profile(self, user: User) -> dict:
        try:
            ytm = self.get_client(user)
            # get_account_info() is not a standard ytmusicapi method in all versions, 
            # but usually available or can be inferred from other calls.
            # In some versions it's get_library_playlists() and checking headers or similar.
            # Let's try to get it via a hack or check official docs.
            # Actually, ytmusicapi 1.11.5 doesn't have a direct get_account_info.
            # But we can get it from the home page or library.
            try:
                # This often contains profile info in the response headers or initial data
                # but ytmusicapi doesn't expose it easily.
                # However, we can try to get it from a specific endpoint if we have OAuth.
                pass
            except:
                pass
            return {"name": user.username, "avatar": None} # Fallback
        except Exception as e:
            logger.error(f"Failed to get user profile: {e}")
            return {}

    def get_home_cached(
        self,
        user: Optional[User] = None,
        limit: int = 25,
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
_failure_cache = {}  # {video_id: expiry_timestamp}
_extraction_locks: Dict[str, asyncio.Lock] = {}

# Keep track of which strategy/cookie combination worked last to try it first next time (Fast Path)
_preferred_strategy_name: Optional[str] = "android_vr"
_preferred_cookie_type: Optional[str] = "global"  # 'user', 'global', or 'none'

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

    # 1. Check Success Cache
    if video_id in _url_cache:
        url, expiry = _url_cache[video_id]
        if now < expiry:
            logger.debug(f"Cache hit for {video_id}")
            return url

    # 2. Check Failure Cache (short-lived)
    if video_id in _failure_cache:
        if now < _failure_cache[video_id]:
            logger.warning(f"Returning cached failure for {video_id} (throttled)")
            raise Exception(
                f"Extraction previously failed for {video_id}, retrying later."
            )

    logger.info(f"Cache miss for {video_id}, extracting...")

    # Use a lock to prevent concurrent extractions for the same video_id
    if video_id not in _extraction_locks:
        _extraction_locks[video_id] = asyncio.Lock()

    async with _extraction_locks[video_id]:
        # Double-check caches inside the lock
        if video_id in _url_cache:
            url, expiry = _url_cache[video_id]
            if now < expiry:
                return url

        # 1. Build cookie paths and identify types
        user_cookie_path = None
        if user and user.yt_auth_json:
            data_dir = os.path.dirname(settings.COOKIES_FILE_PATH)
            user_cookie_path = os.path.join(data_dir, f"cookies_{user.id}.txt")
            if not write_cookie_file(user.yt_auth_json, user_cookie_path):
                user_cookie_path = None

        global_cookie_path = (
            settings.COOKIES_FILE_PATH
            if os.path.exists(settings.COOKIES_FILE_PATH)
            else None
        )

        def get_cp(ctype):
            if ctype == "user":
                return user_cookie_path
            if ctype == "global":
                return global_cookie_path
            return None

        imp = _IMPERSONATE_TARGET
        strategies = [
            {
                "name": "android_vr",
                "player_clients": ["android_vr"],
                "format": "bestaudio/best",
                "impersonate": imp,
            },
            {
                "name": "android",
                "player_clients": ["android"],
                "format": "bestaudio/best",
                "impersonate": imp,
            },
            {
                "name": "ios",
                "player_clients": ["ios"],
                "format": "bestaudio/best",
                "impersonate": imp,
            },
            {
                "name": "web",
                "player_clients": ["web"],
                "format": "bestaudio/best",
                "impersonate": imp,
            },
            {
                "name": "mweb",
                "player_clients": ["mweb"],
                "format": "bestaudio/best",
                "impersonate": imp,
            },
            {
                "name": "tv_embedded",
                "player_clients": ["tv_embedded"],
                "format": "bestaudio/best",
                "impersonate": imp,
            },
        ]

        # 2. Fast Path: Try the globally preferred strategy first
        global _preferred_strategy_name, _preferred_cookie_type
        if _preferred_strategy_name and _preferred_cookie_type:
            strategy = next(
                (s for s in strategies if s["name"] == _preferred_strategy_name),
                strategies[0],
            )
            cp = get_cp(_preferred_cookie_type)
            # Only try if cookie path is available for that type (except for 'none')
            if _preferred_cookie_type == "none" or cp:
                try:
                    logger.debug(
                        f"Fast-path extraction for {video_id} using {_preferred_strategy_name} ({_preferred_cookie_type})"
                    )
                    url = await run_sync(_single_extract_sync, video_id, strategy, cp)
                    if url:
                        return url
                except Exception:
                    logger.debug(
                        f"Fast-path failed for {video_id}, falling back to parallel"
                    )

        # 3. Parallel Path: Try all combinations
        cookie_types = ["user", "global", "none"]
        trials = []
        for strategy in strategies:
            for ctype in cookie_types:
                cp = get_cp(ctype)
                if cp or ctype == "none":
                    # Avoid re-trying the fast-path combination if we already tried it
                    if (
                        strategy["name"] == _preferred_strategy_name
                        and ctype == _preferred_cookie_type
                    ):
                        continue
                    trials.append((strategy, cp, ctype))

        # --- CRITICAL FIX: Low-Latency Parallel Extraction ---
        # We spawn multiple extraction strategies in parallel tasks.
        # Python synchronous threads (running yt-dlp) cannot be forcefully killed.
        # Using anyio.create_task_group() would wait for ALL tasks to finish (even 
        # the slow failing ones), causing 10-20s latency.
        # Instead, we use asyncio.wait(FIRST_COMPLETED) to return the FIRST successful 
        # result immediately to the user, ensuring music starts playing within 1-2s.
        result_container = []
        worker_tasks = []

        async def worker(s, c, ct):
            try:
                url = await run_sync(_single_extract_sync, video_id, s, c)
                if url and not result_container:
                    # Capture the first successful URL safely
                    result_container.append((url, s["name"], ct))
                    return True
            except Exception:
                pass
            return False

        # Create all tasks
        for s, c, ct in trials:
            worker_tasks.append(asyncio.create_task(worker(s, c, ct)))
            # Slight stagger to prioritize user cookies if available
            if ct == "user":
                await asyncio.sleep(0.05)

        # Wait loop: exits as soon as we have a result or all tasks finish.
        while worker_tasks:
            done, pending = await asyncio.wait(
                worker_tasks, return_when=asyncio.FIRST_COMPLETED
            )
            worker_tasks = list(pending)
            
            if result_container:
                # SUCCESS: Cancel remaining tasks. Note: yt-dlp threads already 
                # inside run_sync will finish in background, but won't block the user.
                for task in worker_tasks:
                    task.cancel()
                break
            
            # If all done tasks failed and no result yet, loop again to wait for pending

        if result_container:
            url, sname, ctype = result_container[0]
            _preferred_strategy_name = sname
            _preferred_cookie_type = ctype
            # Keep pending tasks running in background to warm up caches/cookies
            # but return the result to the user immediately.
            return url

        # All failed
        _failure_cache[video_id] = now + 300  # Block retries for 5 mins
        raise Exception(f"Extraction failed for {video_id} after all strategies.")


def _single_extract_sync(
    video_id: str, strategy: dict, cookie_path: Optional[str]
) -> str:
    """Synchronous trial for a single strategy and cookie path."""
    now = time.monotonic()
    yt_url = f"https://www.youtube.com/watch?v={video_id}"

    logger.debug(
        f"Trying extraction strategy: {strategy['name']} (cookies={'yes' if cookie_path else 'no'}) for {video_id}"
    )

    ydl_opts: dict = {
        "quiet": True,
        "no_warnings": True,
        "nocheckcertificate": True,
        "noplaylist": True,
        "format": strategy["format"],
        "cookiefile": cookie_path,
        "http_headers": {
            "Referer": "https://www.youtube.com/",
        },
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
        info = None
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(yt_url, download=False)
        except Exception as fe:
            # If format-specific extraction fails, try one more time with NO format constraint
            # This is slow but better than total failure for this strategy.
            logger.debug(f"Format-specific extraction failed for {strategy['name']}, trying loose fallback: {fe}")
            loose_opts = ydl_opts.copy()
            loose_opts["format"] = None
            with yt_dlp.YoutubeDL(loose_opts) as ydl:
                info = ydl.extract_info(yt_url, download=False)

        if not info:
            raise Exception("No info returned")

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
            raise Exception("No direct URL found in formats")

        _url_cache[video_id] = (final_url, now + 3600)
        logger.info(
            f"Extracted URL ({strategy['name']}, cookies={'yes' if cookie_path else 'no'}) "
            f"for {video_id}: ext={info.get('ext')} abr={info.get('abr')}kbps"
        )
        return final_url

    except Exception as e:
        logger.warning(
            f"Strategy {strategy['name']} (cookies={'yes' if cookie_path else 'no'}) "
            f"failed for {video_id}: {e}"
        )
        raise e


yt_service = YTMusicService()
auth_service = AuthService()
