from fastapi import APIRouter
import structlog

log = structlog.get_logger()
router = APIRouter(tags=["Feedback"])

@router.post("/rating")
async def rate(payload: dict):
    """
    Submit user rating.
    """
    booking_id = payload.get("booking_id")
    rating = payload.get("rating")
    
    log.info("rating_received", booking_id=booking_id, rating=rating)
    
    return {
        "status": "ok",
        "message_english": "Thank you for your feedback!",
        "message_urdu": "Aapka shukriya!"
    }
