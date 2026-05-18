from fastapi import APIRouter, HTTPException
from datetime import datetime, timedelta
import structlog

log = structlog.get_logger()
router = APIRouter(tags=["Lifecycle"])

# Temporary in-memory start times for rotating stub
_BOOKING_START_TIMES = {}

@router.get("/booking/{booking_id}/lifecycle")
async def get_lifecycle(booking_id: str):
    """
    Poll lifecycle status. Returns simulated status and ETA based on elapsed time.
    This implements the "Static Tracking + ETA" concept advised by Taha, avoiding the
    need for live location tracking for the hackathon.
    """
    if booking_id not in _BOOKING_START_TIMES:
        _BOOKING_START_TIMES[booking_id] = datetime.now()
    
    start_time = _BOOKING_START_TIMES[booking_id]
    elapsed = (datetime.now() - start_time).total_seconds()
    
    if elapsed < 30:
        status = "confirmed"
        eta = 15
    elif elapsed < 90:
        status = "en_route"
        eta = 8
    elif elapsed < 150:
        status = "arrived"
        eta = 0
    elif elapsed < 300:
        status = "in_progress"
        eta = 0
    else:
        status = "completed"
        eta = 0
        
    # Standard lifecycle object
    lifecycle = {
        "confirmed_at": start_time.isoformat(),
        "en_route_at": (start_time + timedelta(seconds=30)).isoformat() if elapsed >= 30 else None,
        "arrived_at": (start_time + timedelta(seconds=90)).isoformat() if elapsed >= 90 else None,
        "in_progress_at": (start_time + timedelta(seconds=150)).isoformat() if elapsed >= 150 else None,
        "completed_at": (start_time + timedelta(seconds=300)).isoformat() if elapsed >= 300 else None,
    }
    
    return {
        "booking_id": booking_id,
        "status": status,
        "eta_minutes": eta,
        "lifecycle": lifecycle
    }

@router.post("/lifecycle")
async def update_lifecycle(payload: dict):
    """
    Manual lifecycle update (used by mobile/provider app).
    """
    booking_id = payload.get("booking_id")
    new_status = payload.get("new_status")
    
    # In production, this would update Firestore
    log.info("lifecycle_update_request", booking_id=booking_id, status=new_status)
    
    return {"status": "ok", "booking_id": booking_id, "new_status": new_status}
