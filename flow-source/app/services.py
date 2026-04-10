import os
import time
from typing import Dict, List, Optional

import yt_dlp
import ytmusicapi

from .config import settings
from .models import ArtistResponse, HomeResponse, SongResponse
from .utils import is_artist_item, normalize_artist, normalize_song


class YTMusicService:
    def __init__(self):
        self.auth_file = settings.AUTH_FILE_PATH
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

    def get_client(self):
        if os.path.exists(self.auth_file):
            return ytmusicapi.YTMusic(self.auth_file)
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

    def build_home_data(self, limit: int = 5) -> HomeResponse:
        ytm = self.get_client()
        shelves = ytm.get_home(limit=limit)

        sections: Dict[str, List] = {
            "quickAccess": [],
            "listeningAgain": [],
            "forgottenFavorites": [],
            "musicForYou": [],
            "trendingArtists": [],
        }
        seen_ids = set()
        overflow = []

        for shelf in shelves:
            title = shelf.get("title") or ""
            contents = shelf.get("contents") or []
            section = self._classify_shelf(title)

            artists_in_shelf = []
            songs_in_shelf = []

            for item in contents:
                if is_artist_item(item):
                    artist = normalize_artist(item)
                    if artist:
                        artists_in_shelf.append(artist)
                else:
                    song = normalize_song(item)
                    if song and song.id not in seen_ids:
                        seen_ids.add(song.id)
                        songs_in_shelf.append(song)

            sections["trendingArtists"].extend(artists_in_shelf)

            if songs_in_shelf:
                if section:
                    sections[section].extend(songs_in_shelf)
                else:
                    overflow.append(songs_in_shelf)

        fill_priority = [
            "listeningAgain",
            "forgottenFavorites",
            "musicForYou",
            "quickAccess",
        ]
        for songs in overflow:
            target = min(fill_priority, key=lambda k: len(sections[k]))
            sections[target].extend(songs)

        if not sections["quickAccess"]:
            source = sections["listeningAgain"] or sections["musicForYou"]
            sections["quickAccess"] = source[:8]

        sections["quickAccess"] = sections["quickAccess"][:8]
        sections["listeningAgain"] = sections["listeningAgain"][:15]
        sections["forgottenFavorites"] = sections["forgottenFavorites"][:15]
        sections["musicForYou"] = sections["musicForYou"][:20]
        sections["trendingArtists"] = sections["trendingArtists"][:10]

        trending = self._get_trending_songs(ytm)

        return HomeResponse(**sections, trending=trending)

    def get_home_cached(self, limit: int = 5) -> HomeResponse:
        now = time.monotonic()
        if self.home_cache.get("ts", 0) + self.home_cache_ttl > now:
            return self.home_cache["data"]

        data = self.build_home_data(limit)
        self.home_cache["ts"] = now
        self.home_cache["data"] = data
        return data

    def build_feed_data(self) -> HomeResponse:
        """Unauthenticated feed — returns only global trending/chart songs.
        Works without auth.json; never raises PermissionError."""
        ytm = ytmusicapi.YTMusic()  # always anonymous
        trending = self._get_trending_songs(ytm)
        # Fall back to a shallow home fetch for musicForYou if trending is empty
        music_for_you: List[SongResponse] = []
        if not trending:
            try:
                shelves = ytm.get_home(limit=3)
                seen: set = set()
                for shelf in shelves:
                    for item in (shelf.get("contents") or []):
                        song = normalize_song(item)
                        if song and song.id not in seen:
                            seen.add(song.id)
                            music_for_you.append(song)
                            if len(music_for_you) >= 20:
                                break
                    if len(music_for_you) >= 20:
                        break
            except Exception:
                pass

        return HomeResponse(
            quickAccess=[],
            listeningAgain=[],
            forgottenFavorites=[],
            musicForYou=music_for_you,
            trendingArtists=[],
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

    def clear_cache(self):
        self.home_cache.clear()


def extract_audio_url(video_id: str) -> str:
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


yt_service = YTMusicService()
