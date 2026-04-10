import json
import os
import re
from typing import List, Optional

from .config import settings
from .models import ArtistResponse, PlaylistResponse, SongResponse


def fix_thumbnail_url(url: Optional[str]) -> Optional[str]:
    """Normalise a YouTube/Google thumbnail URL to a consistent size."""
    if not url:
        return None
    # Request 1000 px so full-screen art stays crisp
    url = re.sub(r"=w\d+-h\d+(-[^?&]*)?$", "=w1000-h1000-l90-rj", url)
    return url


def normalize_song(item: dict) -> Optional[SongResponse]:
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
        thumbnailUrl=fix_thumbnail_url(raw_url),
    )


def is_artist_item(item: dict) -> bool:
    return (
        item.get("resultType") == "artist"
        or item.get("type") == "artist"
        or bool(item.get("subscribers"))
        or (not item.get("videoId") and str(item.get("browseId", "")).startswith("UC"))
    )


def normalize_artist(item: dict) -> Optional[ArtistResponse]:
    name = item.get("artist") or item.get("title") or item.get("name")
    if not name:
        return None
    thumbnails = item.get("thumbnails") or []
    raw_url = thumbnails[-1]["url"] if thumbnails else None
    return ArtistResponse(name=name, thumbnailUrl=fix_thumbnail_url(raw_url))


def normalize_playlist(item: dict) -> PlaylistResponse:
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
        thumbnailUrl=fix_thumbnail_url(raw_url),
        trackCount=track_count,
    )


def write_cookie_file(auth_file: str, cookie_file: str) -> None:
    if not os.path.exists(auth_file):
        return
    try:
        with open(auth_file) as f:
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

        os.makedirs(os.path.dirname(cookie_file), exist_ok=True)
        with open(cookie_file, "w") as f:
            f.writelines(lines)
    except Exception:
        # Silently fail for now, should probably log
        pass


def curl_to_headers(curl: str) -> str:
    curl = re.sub(r"[\^\\]\s*[\r\n]+", " ", curl)
    curl = curl.replace('^"', '"').replace('\\"', '"')
    headers = []
    for m in re.finditer(r'-H\s+([\'"])(.*?)\1', curl):
        headers.append(m.group(2))
    for m in re.finditer(r'-b\s+([\'"])(.*?)\1', curl):
        headers.append(f"cookie: {m.group(2)}")
    return "\n".join(headers)
