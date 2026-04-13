import logging
import os
import sys

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .config import settings
from .database import Base, engine
from .routes import close_shared_client, router
from .utils import write_cookie_file


def setup_logging():
    log_level = logging.DEBUG if settings.DEBUG else logging.INFO
    logging.basicConfig(
        level=log_level,
        format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
        handlers=[logging.StreamHandler(sys.stdout)],
    )

    # ── Silence High-Volume Noise ─────────────────────────────────────────────
    # These libraries are extremely chatty in DEBUG mode (connection pools, etc)
    logging.getLogger("httpcore").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    
    if not settings.DEBUG:
        logging.getLogger("ytmusicapi").setLevel(logging.WARNING)
        logging.getLogger("uvicorn").setLevel(logging.INFO)

    # ── Custom Filter for Noisy Routes ────────────────────────────────────────
    # Suppress DEBUG logs for proxy-image and prefetch as they flood the console
    class NoisyRouteFilter(logging.Filter):
        def filter(self, record):
            msg = record.getMessage()
            if "/v1/proxy-image" in msg or "/v1/prefetch" in msg:
                return record.levelno > logging.DEBUG
            return True

    logging.getLogger("flow.routes").addFilter(NoisyRouteFilter())


def create_app() -> FastAPI:
    setup_logging()
    logger = logging.getLogger("flow.app")
    logger.info(f"Starting Flow Music API (DEBUG={settings.DEBUG})")

    app = FastAPI(
        title="Flow Music API",
        version="2.0.0",
        description="Production-ready YT Music API for Flow app with User Management",
    )

    # CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Routes - Prefixed with /v1 as requested
    app.include_router(router, prefix="/v1")

    # Static Files
    if os.path.exists(settings.STATIC_DIR):
        app.mount(
            "/", StaticFiles(directory=settings.STATIC_DIR, html=True), name="static"
        )

    @app.on_event("startup")
    async def startup_event():
        logger.info("Application starting up...")

        # Ensure database tables are created
        try:
            Base.metadata.create_all(bind=engine)
            logger.info("Database tables initialized.")
        except Exception as e:
            logger.error(f"Database initialization failed: {e}")

        # Ensure global cookie file is written if the master auth.json exists
        if write_cookie_file(settings.AUTH_FILE_PATH, settings.COOKIES_FILE_PATH):
            logger.info(f"Global cookies initialized at {settings.COOKIES_FILE_PATH}")

        # Cloudflare tunnel exposure is managed by Docker sidecar
        pass

    @app.on_event("shutdown")
    async def shutdown_event():
        logger.info("Application shutting down...")
        await close_shared_client()

    return app


app = create_app()
