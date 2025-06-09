import os
import logging

# Create logs directory if it doesn't exist
os.makedirs("logs", exist_ok=True)

def setup_logger(name: str) -> logging.Logger:
    """
    Configure and return a logger with the given name.
    
    Args:
        name: The name for the logger
        
    Returns:
        A configured logger instance
    """
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)
    
    # Set format
    formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
    
    # Add console handler
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    # Add file handler
    file_handler = logging.FileHandler("logs/app.log")
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)
    
    return logger 