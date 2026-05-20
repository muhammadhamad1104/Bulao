import math
from fastapi import APIRouter, HTTPException
from datetime import datetime, timedelta
import structlog

log = structlog.get_logger()
router = APIRouter(tags=["Lifecycle"])

# In-memory booking state store (Firestore in production)
# Key: booking_id → {status, start_time, provider_lat, provider_lng, user_lat, user_lng, eta_minutes}
_BOOKING_STATE: dict = {}


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    R = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lng2 - lng1)
    a = math.sin(dp / 2)**2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2)**2
    return 2 * R * math.asin(math.sqrt(a))


def _calculate_eta(provider_lat: float, provider_lng: float,
                   user_lat: float, user_lng: float) -> int:
    """Haversine + 25 km/h city speed + 5-min overhead."""
    dist_km = _haversine_km(provider_lat, provider_lng, user_lat, user_lng)
    return max(5, int((dist_km / 25.0) * 60) + 5)


def _static_map_url(provider_lat: float, provider_lng: float,
                    user_lat: float, user_lng: float) -> str:
    """OpenStreetMap-based static map URL (no API key required)."""
    # Use a simple iframe-free OSM tile approach the app can display as an image
    # Format: center between the two points
    center_lat = (provider_lat + user_lat) / 2
    center_lng = (provider_lng + user_lng) / 2
    return (
        f"https://staticmap.openstreetmap.de/staticmap.php?"
        f"center={center_lat},{center_lng}&zoom=13&size=600x300"
        f"&markers={provider_lat},{provider_lng},red-pushpin"
        f"|{user_lat},{user_lng},blue-pushpin"
    )


@router.get("/booking/{booking_id}/lifecycle")
async def get_lifecycle(booking_id: str):
    """
    Poll booking lifecycle status. Returns real status, ETA minutes, and static map URL.
    App should poll this every 15 seconds while the tracking screen is open.
    """
    state = _BOOKING_STATE.get(booking_id)

    if not state:
        # Default confirmed state for bookings not yet in memory
        return {
            "booking_id": booking_id,
            "status": "confirmed",
            "eta_minutes": None,
            "static_map_url": None,
            "lifecycle": {
                "confirmed_at": datetime.now().isoformat(),
                "en_route_at": None,
                "arrived_at": None,
                "completed_at": None,
            },
            "message": "Waiting for provider to dispatch."
        }

    status = state["status"]
    eta_minutes = state.get("eta_minutes")
    static_map_url = state.get("static_map_url")

    # Recalculate ETA if en_route and coordinates are available
    if status == "en_route" and all(k in state for k in ["provider_lat", "provider_lng", "user_lat", "user_lng"]):
        dispatched_at = state.get("dispatched_at")
        if dispatched_at:
            elapsed_min = (datetime.now() - dispatched_at).total_seconds() / 60
            original_eta = state.get("original_eta_minutes", eta_minutes or 20)
            eta_minutes = max(0, original_eta - int(elapsed_min))
            if eta_minutes == 0:
                state["status"] = "arrived"
                state["arrived_at"] = datetime.now()
                status = "arrived"

    return {
        "booking_id": booking_id,
        "status": status,
        "eta_minutes": eta_minutes,
        "static_map_url": static_map_url,
        "lifecycle": {
            "confirmed_at": state.get("confirmed_at", datetime.now()).isoformat() if isinstance(state.get("confirmed_at"), datetime) else state.get("confirmed_at"),
            "en_route_at": state.get("en_route_at").isoformat() if isinstance(state.get("en_route_at"), datetime) else state.get("en_route_at"),
            "arrived_at": state.get("arrived_at").isoformat() if isinstance(state.get("arrived_at"), datetime) else state.get("arrived_at"),
            "completed_at": state.get("completed_at").isoformat() if isinstance(state.get("completed_at"), datetime) else state.get("completed_at"),
        }
    }


@router.post("/lifecycle/dispatch")
async def dispatch_provider(payload: dict):
    """
    Provider taps 'I'm on my way' → marks booking as en_route and calculates ETA.

    Body: {
        booking_id, provider_lat, provider_lng, user_lat, user_lng,
        token (optional security token)
    }
    """
    booking_id = payload.get("booking_id")
    if not booking_id:
        raise HTTPException(status_code=400, detail="booking_id required")

    provider_lat = payload.get("provider_lat")
    provider_lng = payload.get("provider_lng")
    user_lat = payload.get("user_lat")
    user_lng = payload.get("user_lng")

    eta_minutes = None
    static_map_url = None

    if all(v is not None for v in [provider_lat, provider_lng, user_lat, user_lng]):
        eta_minutes = _calculate_eta(provider_lat, provider_lng, user_lat, user_lng)
        static_map_url = _static_map_url(provider_lat, provider_lng, user_lat, user_lng)

    now = datetime.now()
    _BOOKING_STATE[booking_id] = {
        "status": "en_route",
        "confirmed_at": _BOOKING_STATE.get(booking_id, {}).get("confirmed_at", now),
        "en_route_at": now,
        "dispatched_at": now,
        "arrived_at": None,
        "completed_at": None,
        "provider_lat": provider_lat,
        "provider_lng": provider_lng,
        "user_lat": user_lat,
        "user_lng": user_lng,
        "eta_minutes": eta_minutes,
        "original_eta_minutes": eta_minutes,
        "static_map_url": static_map_url,
    }

    log.info("provider_dispatched", booking_id=booking_id,
             eta_minutes=eta_minutes, provider_lat=provider_lat, provider_lng=provider_lng)

    return {
        "status": "en_route",
        "booking_id": booking_id,
        "eta_minutes": eta_minutes,
        "static_map_url": static_map_url,
        "message": f"Provider is on their way! ETA: ~{eta_minutes} minutes." if eta_minutes else "Provider dispatched."
    }


@router.post("/lifecycle")
async def update_lifecycle(payload: dict):
    """
    General lifecycle update (arrived, in_progress, completed, cancelled).
    Body: {booking_id, new_status}
    """
    booking_id = payload.get("booking_id")
    new_status = payload.get("new_status")

    if not booking_id or not new_status:
        raise HTTPException(status_code=400, detail="booking_id and new_status required")

    valid_statuses = ["confirmed", "en_route", "arrived", "in_progress", "completed", "cancelled"]
    if new_status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of: {valid_statuses}")

    now = datetime.now()
    if booking_id not in _BOOKING_STATE:
        _BOOKING_STATE[booking_id] = {"confirmed_at": now}

    _BOOKING_STATE[booking_id]["status"] = new_status
    _BOOKING_STATE[booking_id][f"{new_status}_at"] = now

    log.info("lifecycle_update", booking_id=booking_id, new_status=new_status)
    return {"status": "ok", "booking_id": booking_id, "new_status": new_status}

