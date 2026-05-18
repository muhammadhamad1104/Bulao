from fastapi import APIRouter
from app.models import FollowupResult
from app.agents import followup_agent
import structlog

log = structlog.get_logger()
router = APIRouter(tags=["Disputes"])

@router.post("/dispute", response_model=FollowupResult)
async def dispute(payload: dict):
    """
    Handle user disputes and quality complaints.
    """
    booking_id = payload.get("booking_id")
    log.info("dispute_request", booking_id=booking_id)
    
    # In Day 4 this will call real followup_agent.run(mode="dispute")
    # For now, return a stub as per Day 2 spec.
    return FollowupResult(
        mode="dispute",
        classification="quality_complaint",
        resolution="partial_refund",
        refund_pkr=1000,
        english="We are sorry for the inconvenience. A partial refund of PKR 1,000 has been initiated.",
        urdu="Hum maafi chahte hain. PKR 1,000 ka partial refund shuru kar diya gaya hai.",
        cta="none",
        escalate_to_human=False
    )
