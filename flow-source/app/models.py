from datetime import datetime
from typing import Any, Dict, List, Optional, Union

from pydantic import BaseModel, EmailStr
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, Text
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

    # Store user settings as a JSON string
    settings_json = Column(Text, nullable=True)

    # Relationships
    history = relationship(
        "PlayHistory", back_populates="user", cascade="all, delete-orphan"
    )


class PlayHistory(Base):
    __tablename__ = "play_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    song_id = Column(String, index=True)
    title = Column(String)
    artist = Column(String)
    album = Column(String)
    duration_ms = Column(Integer)
    thumbnail_url = Column(Text, nullable=True)
    played_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="history")


# --- Pydantic Models ---


class UserBase(BaseModel):
    username: str
    email: EmailStr


class UserCreate(UserBase):
    password: str


class UserLogin(BaseModel):
    username: str
    password: str


class UserSettingsUpdate(BaseModel):
    settings: Dict[str, Any]


class UserResponse(UserBase):
    id: int
    is_active: bool
    has_yt_auth: bool = False
    settings: Optional[Dict[str, Any]] = None

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


class HistoryEntryResponse(SongResponse):
    playedAt: datetime


class HistoryResponse(BaseModel):
    today: List[HistoryEntryResponse] = []
    thisWeek: List[HistoryEntryResponse] = []
    thisMonth: List[HistoryEntryResponse] = []
    byMonth: Dict[str, List[HistoryEntryResponse]] = {}  # e.g. "March 2024"


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
    shelves: List[Dict[str, Any]]
    trending: List[SongResponse] = []
    profileUrl: Optional[str] = None
    quickAccess: List[SongResponse] = []
    listeningAgain: List[SongResponse] = []
    freshFinds: List[SongResponse] = []
    forgottenFavorites: List[SongResponse] = []
    musicForYou: List[SongResponse] = []
    trendingArtists: List[ArtistResponse] = []


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
