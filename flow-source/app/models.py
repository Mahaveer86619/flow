from typing import Any, Dict, List, Optional, Union

from pydantic import BaseModel


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


class CreatePlaylistRequest(BaseModel):
    title: str
    description: str
    privacy_status: str = "PRIVATE"
    video_ids: Optional[List[str]] = None
    source_playlist: Optional[str] = None


class EditPlaylistRequest(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    privacyStatus: Optional[str] = None
    moveItem: Optional[Union[str, tuple[str, str]]] = None
    addPlaylistId: Optional[str] = None
    addToTop: Optional[bool] = None


class AddPlaylistItemsRequest(BaseModel):
    videoIds: Optional[List[str]] = None
    source_playlist: Optional[str] = None
    duplicates: bool = False


class RemovePlaylistItemsRequest(BaseModel):
    videos: List[Dict[str, Any]]
