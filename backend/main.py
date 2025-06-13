#!/usr/bin/env python3
"""
QLDSV-HTC API - Main application entry point
"""

import os
import sys
import argparse
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Import application components
from app.api.router import api_router
from app.core.config import get_settings
from app.core.logger import setup_logger
from app.db.utils import reset_database

# Setup logger
logger = setup_logger("main")

# Get settings
settings = get_settings()

# Create FastAPI app
app = FastAPI(
    title=settings.PROJECT_NAME,
    description=settings.PROJECT_DESCRIPTION,
    version=settings.PROJECT_VERSION
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router
app.include_router(api_router)


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="QLDSV-HTC Backend")
    parser.add_argument("--reset-db", action="store_true",
                        help="Reset the database before starting the server")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    if args.reset_db:
        try:
            reset_database()
        except Exception as e:
            logger.error(f"Failed to reset database: {e}")
            sys.exit(1)

    # This block won't be reached when running with uvicorn
    # It's here for documentation purposes
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
