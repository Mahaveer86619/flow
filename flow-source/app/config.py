import os
from typing import Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # API Settings
    DEBUG: bool = True
    FLAVOR: str = "local"
    PORT: int = 8000
    HOST: str = "0.0.0.0"

    # Ngrok Settings
    NGROK_AUTHTOKEN: Optional[str] = None

    # YT Music Auth Settings
    AUTH_FILE_PATH: str = "./data/auth.json"
    COOKIES_FILE_PATH: str = "./data/cookies.txt"

    # Static Files
    STATIC_DIR: str = "./static"
    PROXIED_IMAGE_URL: str = "http://localhost:8000/api/proxy-image"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()

# Ensure directories exist
os.makedirs(os.path.dirname(settings.AUTH_FILE_PATH), exist_ok=True)
os.makedirs(settings.STATIC_DIR, exist_ok=True)
