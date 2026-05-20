from fastapi import APIRouter, HTTPException
from app.models import Booking, PriceQuote, Intent
from app.agents import booking_agent
from app.db import firestore_client
from datetime import datetime
import structlog

log = structlog.get_logger()
router = APIRouter(tags=["Transactions"])

# In-process cache for demo purposes (replaces Redis)
_QUOTE_CACHE = {}

@router.post("/book", response_model=Booking)
async def book(payload: dict):
    """
    Finalize a booking.
    Body: {quote_id, user_id, user_name, intent, provider_id, accepted_quote}
    """
    quote_id = payload.get("quote_id")
    user_id = payload.get("user_id")
    accepted_quote_data = payload.get("accepted_quote")
    intent_data = payload.get("intent")
    
    if not quote_id or not user_id:
        raise HTTPException(status_code=400, detail="Missing required fields")

    # In a real app, we'd verify the quote against _QUOTE_CACHE or DB
    # For now, we'll validate the incoming accepted_quote
    try:
        accepted_quote = PriceQuote.model_validate(accepted_quote_data)
        intent = Intent.model_validate(intent_data)
    except Exception as e:
        log.error("validation_failure", error=str(e))
        raise HTTPException(status_code=422, detail=f"Invalid schema: {str(e)}")

    # Check expiration
    from datetime import timezone
    expires_at = datetime.fromisoformat(accepted_quote.expires_at.replace("Z", "+00:00"))
    if datetime.now(expires_at.tzinfo or timezone.utc) > expires_at:
        raise HTTPException(status_code=409, detail="quote_expired")

    # Run Booking Agent (generates PDF, writes to DB)
    # Note: we need the provider object too. 
    # For the /book endpoint, we'll mock the provider from discovery or ranking if needed.
    # But booking_agent.run expects intent, provider, accepted_quote.
    
    # Let's assume the provider info is in the payload or we fetch it.
    # For simplicity, we'll pass the provider_id and mock a candidate.
    from app.models import ProviderCandidate
    provider_id = payload.get("provider_id", "prov_001")
    provider_data = payload.get("provider")
    if provider_data:
        try:
            provider = ProviderCandidate.model_validate(provider_data)
        except Exception as e:
            log.error("provider_validation_failure", error=str(e))
            raise HTTPException(status_code=422, detail=f"Invalid provider schema: {str(e)}")
    else:
        # Fallback if no provider details provided in request
        provider = ProviderCandidate(
            id=provider_id,
            name="Ali Plumbing Works",
            service_categories=["plumber"],
            distance_km=1.2,
            neighborhood="G-13",
            rating=4.8,
            completed_jobs_in_area=150,
            on_time_score=0.98,
            cancellation_rate=0.02,
            review_recency_days=2,
            risk_score=0.05,
            current_workload=0.4,
            availability_status="available_now",
            next_slot=datetime.now().isoformat(),
            base_visit_fee_pkr=1000,
            rate_per_hour_pkr=800,
            gender="male",
            years_experience=12,
            phone_masked="+92 300 ******",
            lat=33.6844,
            lng=73.0479
        )

    booking = await booking_agent.run(
        intent=intent,
        provider=provider,
        accepted_quote=accepted_quote,
        user_id=user_id,
        user_name=payload.get("user_name")
    )

    # Save to Firestore
    await firestore_client.save_booking(booking.model_dump())
    
    return booking

@router.get("/user/{user_id}/bookings", response_model=list[Booking])
async def get_user_bookings_api(user_id: str):
    """Retrieve all bookings for a user from Firestore."""
    raw_bookings = await firestore_client.get_user_bookings(user_id)
    return [Booking.model_validate(b) for b in raw_bookings]

