from fastapi import APIRouter, Request, HTTPException
from app.db import firestore_client
from app.agents import followup_agent
from datetime import datetime, timedelta
import structlog

log = structlog.get_logger()
router = APIRouter(tags=["Internal"])

@router.post("/followup/trigger")
async def trigger_followups(request: Request):
    """
    Called by Cloud Scheduler every 5-30 minutes.
    Queries Firestore for bookings needing reminders/check-ins.
    """
    # Simple auth check for hackathon (check for OIDC header existence)
    # In production: use google-auth to verify the token
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        log.warn("unauthorized_trigger_attempt")
        # For local demo purposes, we might skip this
        # raise HTTPException(status_code=401)
    
    now = datetime.now().astimezone()
    reminder_window = now + timedelta(minutes=35)
    
    # Query logic (simplified since we're using a mock firestore client if needed)
    # In a real app: db.collection("bookings").where("status", "==", "confirmed")...
    
    log.info("processing_reminders", time=now.isoformat())
    
    # For the demo, we'll return a stub summary
    return {
        "status": "ok",
        "reminders_sent": 0,
        "checkins_sent": 0
    }
