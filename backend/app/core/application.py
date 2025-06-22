"""FastAPI application factory."""

import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
from starlette.middleware.sessions import SessionMiddleware

from app.api.router import api_router
from app.core import config, logger


def create_app() -> FastAPI:
    """Build and return a configured FastAPI app instance."""

    # Set up logging
    app_logger = logger.setup_logging(config.APP_SETTINGS)

    app = FastAPI(
        title=config.APP_SETTINGS.APP_TITLE,
        description=config.APP_SETTINGS.APP_DESCRIPTION,
        version=config.APP_SETTINGS.APP_VERSION,
    )

    # Configure CORS
    # Get CORS settings from environment variables or use sensible defaults.
    # Using wildcard "*" together with `allow_credentials=True` is **not**
    # allowed by the CORS specification and will cause browsers to block the
    # response.  If no explicit origins are provided we therefore fallback to
    # the default dev front-end address instead of "*".

    cors_origins_env = os.environ.get("CORS_ORIGINS")  # comma-separated list
    if cors_origins_env:
        origins = [o.strip() for o in cors_origins_env.split(",") if o.strip()]
    else:
        # Default to Vite dev server in development mode (single port)
        origins = ["http://localhost:5173"]

    # Warn developers when the configuration is potentially unsafe / invalid
    if "*" in origins:
        app_logger.warning(
            "Wildcard '*' detected in CORS_ORIGINS while allow_credentials=True. "
            "This is disallowed by browsers and will lead to failed requests. "
            "Please specify explicit origins, e.g. 'http://localhost:5173'."
        )
        origins = [o for o in origins if o != "*"]

    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Session middleware for cookie-based sessions
    secret_key = os.getenv("SESSION_SECRET_KEY",
                           config.APP_SETTINGS.PROJECT_NAME)
    app.add_middleware(SessionMiddleware, secret_key=secret_key)

    # Root endpoint only
    @app.get("/")
    async def root():
        return {"message": f"Welcome to {config.APP_SETTINGS.APP_TITLE}"}

    # Include API router with prefix from config
    app.include_router(
        api_router,
        prefix=config.APP_SETTINGS.API_PREFIX
    )

    app_logger.info(
        f"Application created with API prefix: {config.APP_SETTINGS.API_PREFIX}")

    return app
