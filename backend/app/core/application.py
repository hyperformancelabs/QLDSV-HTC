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
    # Get CORS settings from environment variables or use defaults
    cors_origins = os.environ.get("CORS_ORIGINS", "*")
    origins = [origin.strip() for origin in cors_origins.split(",")]

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
