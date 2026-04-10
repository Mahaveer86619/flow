from typing import Any, Dict, List, Optional, Union

from pydantic import BaseModel, EmailStr
from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from .database import Base

# --- Database Models (SQLAlchemy) ---


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)

    # Store YT Music auth as a JSON string
    yt_auth_json = Column(Text, nullable=True)


# --- Pydantic Models ---


class UserBase(BaseModel):
    username: str
    email: EmailStr


class UserCreate(UserBase):
    password: str


class UserLogin(BaseModel):
    username: str
    password: str


class UserResponse(UserBase):
    id: int
    is_active: bool
    has_yt_auth: bool = False

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    username: Optional[str] = None


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


class YTCookiesPayload(BaseModel):
    cookies: Dict[str, str]
