import os
import logging

# Create logs directory if it doesn't exist
os.makedirs("logs", exist_ok=True)

# Cache for created loggers to avoid duplicates
_loggers = {}


def setup_logger(name: str) -> logging.Logger:
    """
    Configure and return a logger with the given name.
    Uses a cache to ensure each logger name only gets one instance.

    Args:
        name: The name for the logger

    Returns:
        A configured logger instance
    """
    # Return cached logger if already exists
    if name in _loggers:
        return _loggers[name]

    logger = logging.getLogger(name)

    # Clear any existing handlers to start fresh
    logger.handlers.clear()

    # Prevent propagation to root logger to avoid duplicates
    logger.propagate = False

    logger.setLevel(logging.INFO)

    # Set format
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s")

    # Add console handler
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    # Add file handler
    file_handler = logging.FileHandler("logs/app.log")
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    # Cache the logger
    _loggers[name] = logger

    return logger
