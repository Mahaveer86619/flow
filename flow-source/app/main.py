import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .config import settings
from .routes import router
from .utils import write_cookie_file


def create_app() -> FastAPI:
    app = FastAPI(
        title="Flow Music API",
        version="2.0.0",
        description="Production-ready YT Music API for Flow app",
    )

    # CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Routes
    app.include_router(router, prefix="/api")

    # Static Files
    if os.path.exists(settings.STATIC_DIR):
        app.mount(
            "/", StaticFiles(directory=settings.STATIC_DIR, html=True), name="static"
        )

    @app.on_event("startup")
    async def startup_event():
        # Ensure cookie file is written if auth exists
        write_cookie_file(settings.AUTH_FILE_PATH, settings.COOKIES_FILE_PATH)

    return app


app = create_app()
