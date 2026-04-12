import http.cookiejar
import json
import os
import re
import time
import urllib.parse
from typing import List, Optional

from .config import settings
from .models import ArtistResponse, PlaylistResponse, SongResponse


def fix_thumbnail_url(
    url: Optional[str], proxy_base: Optional[str] = None
) -> Optional[str]:
    """Normalise a YouTube/Google thumbnail URL to a consistent size and optionally wrap in proxy."""
    if not url:
        return None
    # Request 1000 px so full-screen art stays crisp
    url = re.sub(r"=w\d+-h\d+(-[^?&]*)?$", "=w1000-h1000-l90-rj", url)

    if proxy_base:
        return f"{proxy_base}?url={urllib.parse.quote(url)}"
    return url


def normalize_song(
    item: dict, proxy_base: Optional[str] = None
) -> Optional[SongResponse]:
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
        thumbnailUrl=fix_thumbnail_url(raw_url, proxy_base),
    )


def is_artist_item(item: dict) -> bool:
    return (
        item.get("resultType") == "artist"
        or item.get("type") == "artist"
        or bool(item.get("subscribers"))
        or (not item.get("videoId") and str(item.get("browseId", "")).startswith("UC"))
    )


def normalize_artist(
    item: dict, proxy_base: Optional[str] = None
) -> Optional[ArtistResponse]:
    name = item.get("artist") or item.get("title") or item.get("name")
    if not name:
        return None
    thumbnails = item.get("thumbnails") or []
    raw_url = thumbnails[-1]["url"] if thumbnails else None
    return ArtistResponse(
        name=name, thumbnailUrl=fix_thumbnail_url(raw_url, proxy_base)
    )


def normalize_playlist(
    item: dict, proxy_base: Optional[str] = None
) -> PlaylistResponse:
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
        thumbnailUrl=fix_thumbnail_url(raw_url, proxy_base),
        trackCount=track_count,
    )


def write_cookie_file(auth_data: str | dict, cookie_file: str) -> bool:
    """
    Converts ytmusicapi auth JSON or Cookie string into a Netscape cookie file for yt-dlp.
    Returns True if the file was written with at least one cookie.
    """
    import logging as _logging
    _log = _logging.getLogger("uvicorn")
    try:
        data: dict = {}
        if isinstance(auth_data, str):
            if os.path.exists(auth_data):
                with open(auth_data) as f:
                    data = json.load(f)
            else:
                try:
                    data = json.loads(auth_data)
                except Exception:
                    data = {"Cookie": auth_data}
        else:
            data = dict(auth_data)

        # ytmusicapi auth JSON uses "Cookie" header key (case-sensitive)
        cookie_str = (
            data.get("Cookie")
            or data.get("cookie")
            or data.get("headers", {}).get("Cookie")
            or ""
        )
        if not cookie_str:
            _log.warning(
                f"write_cookie_file: no Cookie field found in auth_data "
                f"(keys={list(data.keys())})"
            )
            return False

        dir_path = os.path.dirname(cookie_file)
        if dir_path:
            os.makedirs(dir_path, exist_ok=True)

        expiry = int(time.time()) + 31536000  # 1 year
        count = 0

        with open(cookie_file, "w", encoding="utf-8") as f:
            f.write("# Netscape HTTP Cookie File\n\n")

            for pair in cookie_str.split(";"):
                pair = pair.strip()
                if not pair or "=" not in pair:
                    continue
                name, value = pair.split("=", 1)
                name = name.strip()
                value = value.strip()
                if not name:
                    continue

                # __Host- cookies must be for the exact host (no leading dot)
                if name.startswith("__Host-"):
                    for domain in ["youtube.com", "music.youtube.com", "google.com"]:
                        f.write(f"{domain}\tFALSE\t/\tTRUE\t{expiry}\t{name}\t{value}\n")
                else:
                    for domain in [".youtube.com", ".music.youtube.com", ".google.com"]:
                        f.write(f"{domain}\tTRUE\t/\tTRUE\t{expiry}\t{name}\t{value}\n")
                count += 1

        _log.info(f"write_cookie_file: wrote {count} cookies to {cookie_file}")
        return count > 0

    except Exception as e:
        import logging as _logging2
        _logging2.getLogger("uvicorn").error(f"write_cookie_file failed: {e}")
        return False


def curl_to_headers(curl: str) -> str:
    curl = re.sub(r"[\^\\]\s*[\r\n]+", " ", curl)
    curl = curl.replace('^"', '"').replace('\\"', '"')
    headers = []
    for m in re.finditer(r'-H\s+([\'"])(.*?)\1', curl):
        headers.append(m.group(2))
    for m in re.finditer(r'-b\s+([\'"])(.*?)\1', curl):
        headers.append(f"cookie: {m.group(2)}")
    return "\n".join(headers)
