"""Application logging configuration."""

import logging
import os
import sys
from pathlib import Path
from typing import Dict, Any

from app.core.config import BACKEND_DIR


def setup_logging(config) -> logging.Logger:
    """Set up application logging based on configuration."""
    log_level_str = config.LOG_LEVEL
    log_level = getattr(logging, log_level_str.upper(), logging.INFO)

    # Ensure log directory exists
    log_dir = BACKEND_DIR / "logs"
    if not log_dir.exists():
        os.makedirs(log_dir, exist_ok=True)

    log_file = log_dir / "server.log"

    # Get the root logger
    root_logger = logging.getLogger()

    # Clear existing handlers to avoid duplicates if called multiple times
    if root_logger.handlers:
        for handler in root_logger.handlers[:]:
            root_logger.removeHandler(handler)

    # Configure root logger
    logging.basicConfig(
        level=log_level,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler(log_file)
        ]
    )

    # Reduce verbosity of some loggers
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)

    # Create application logger
    logger = logging.getLogger("app")

    # Clear existing handlers to avoid duplicates
    for handler in logger.handlers[:]:
        logger.removeHandler(handler)

    logger.setLevel(log_level)
    logger.info(f"Logging initialized at level {log_level_str}")

    return logger
