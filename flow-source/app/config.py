import os
from typing import Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # API Settings
    DEBUG: bool = True
    FLAVOR: str = "local"
    PORT: int = 8000
    HOST: str = "0.0.0.0"

    # YT Music Auth Settings
    AUTH_FILE_PATH: str = "./data/auth.json"
    COOKIES_FILE_PATH: str = "./data/cookies.txt"

    # Database Settings
    DATABASE_URL: str = (
        "postgresql://flow_user:R3ally_Str0ng_P4ssw0rd_99@db:5432/flow_music"
    )

    # JWT Settings
    SECRET_KEY: str = "y0ur-sup3r-s3cr3t-k3y-th4t-sh0uld-b3-ch4ng3d"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    # Static Files
    STATIC_DIR: str = "./static"
    PROXIED_IMAGE_URL: str = ""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()

# Ensure directories exist
os.makedirs(os.path.dirname(settings.AUTH_FILE_PATH), exist_ok=True)
os.makedirs(settings.STATIC_DIR, exist_ok=True)
