from fastapi import APIRouter, HTTPException
from app.core.config import get_settings
from app.core.logger import setup_logger
from app.db.utils import reset_database

# Setup router
router = APIRouter()

# Setup logger
logger = setup_logger("api.system")

# Get settings
settings = get_settings()

@router.post("/reset-database")
async def reset_database_endpoint():
    """
    Reset the database endpoint for testing purposes.
    
    Returns:
        dict: Result of database reset operation
    """
    try:
        reset_database()
        return {
            "status": "success",
            "message": "Database reset completed successfully"
        }
    except Exception as e:
        logger.error(f"Database reset via endpoint failed: {e}")
        return {
            "status": "error",
            "message": f"Database reset failed: {str(e)}"
        }

@router.get("/")
async def root():
    """
    Root endpoint returning a welcome message.
    
    Returns:
        dict: Welcome message
    """
    return {"message": "Welcome to QLDSV-HTC API"} 