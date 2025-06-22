"""Application entry point.

This file is intentionally minimal. All heavy lifting is delegated to
`app.core` modules to keep the bootstrap clean.
"""
import logging
import sys
import uvicorn

from app.core.application import create_app
from app.core.config import APP_SETTINGS, verify_cwd
from app.utils.db_reset import reset_database

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("main")


# Verify working directory before doing anything else
verify_cwd()

# Check if reset-db flag is passed
if "--reset-db" in sys.argv:
    logger.info("Database reset requested via command line argument")
    if reset_database():
        logger.info("Database reset completed successfully")
        # Exit if only resetting database was requested
        if len(sys.argv) == 2:
            sys.exit(0)
    else:
        logger.error("Database reset failed")
        sys.exit(1)


# Create the FastAPI application
app = create_app()


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=APP_SETTINGS.APP_HOST,
        port=APP_SETTINGS.APP_PORT,
        reload=APP_SETTINGS.APP_RELOAD,
    )
