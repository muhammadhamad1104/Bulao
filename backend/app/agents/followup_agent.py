import json
import time
from pathlib import Path
from typing import Literal, List, Dict, Optional
import structlog
from app.models import Booking, ProviderCandidate, FollowupResult
from google.genai import Client
from app.config import settings

log = structlog.get_logger()

_PROMPT_PATH = Path(__file__).parent.parent / "prompts" / "followup.md"
_SYSTEM_PROMPT = _PROMPT_PATH.read_text(encoding="utf-8") if _PROMPT_PATH.exists() else ""

def get_client():
    if settings.GEMINI_API_KEY and settings.GEMINI_API_KEY != "fake":
        return Client(api_key=settings.GEMINI_API_KEY)
    return None

async def run(
    mode: Literal["reminder", "checkin", "dispute"],
    booking: Booking,
    provider: ProviderCandidate,
    user_complaint: Optional[str] = None,
    service_checklist: Optional[List[Dict]] = None,
    rating: Optional[int] = None
) -> FollowupResult:
    """
    Handle reminders, check-ins, or disputes.
    """
    log.info("agent_start", agent="followup", mode=mode, booking_id=booking.booking_id)
    t0 = time.monotonic()

    if mode in ("reminder", "checkin"):
        return await _run_reminder_or_checkin(mode, booking, provider)
    else:
        return await _run_dispute(booking, provider, user_complaint, service_checklist, rating)

async def _run_reminder_or_checkin(mode: str, booking: Booking, provider: ProviderCandidate) -> FollowupResult:
    payload = {
        "mode": mode,
        "booking": {
            "booking_id": booking.booking_id,
            "service_type": booking.service_type,
            "scheduled_time": booking.scheduled_time
        },
        "provider": {
            "name": provider.name
        }
    }
    
    msg_en = ""
    msg_ur = ""
    cta = "none"
    
    client = get_client()
    if client:
        try:
            response = client.models.generate_content(
                model='gemini-2.0-flash',
                contents=json.dumps(payload, ensure_ascii=False),
                config={
                    'system_instruction': _SYSTEM_PROMPT,
                    'temperature': 0.1,
                    'response_mime_type': 'application/json'
                }
            )
            data = json.loads(response.text)
            msg_en = data.get("english", "")
            msg_ur = data.get("urdu", "")
            cta = data.get("cta", "none")
        except Exception as e:
            log.error("followup_llm_failure", error=str(e))
            
    if not msg_en:
        msg_en = f"This is a {mode} for your booking {booking.booking_id}."
    if not msg_ur:
        msg_ur = f"Aapki booking {booking.booking_id} ke liye yeh ek {mode} hai."

    return FollowupResult(
        mode=mode, # type: ignore
        english=msg_en,
        urdu=msg_ur,
        cta=cta # type: ignore
    )

async def _run_dispute(booking: Booking, provider: ProviderCandidate, user_complaint: str, service_checklist: List[Dict], rating: int) -> FollowupResult:
    # Deterministic classification rules
    auto_classification = "other"
    auto_resolution = "escalate_to_human"
    auto_refund = 0
    
    if rating == 1:
        auto_classification = "quality_complaint"
        auto_resolution = "full_refund"
        auto_refund = booking.accepted_quote.estimated_total_pkr
    elif rating == 2:
        auto_classification = "quality_complaint"
        auto_resolution = "partial_refund"
        auto_refund = int(booking.accepted_quote.estimated_total_pkr * 0.5)
        
    if service_checklist:
        no_count = sum(1 for item in service_checklist if item.get("status") == "no")
        if no_count >= len(service_checklist) * 0.5:
            auto_classification = "no_show" if "show" in user_complaint.lower() else "quality_complaint"
            
    payload = {
        "mode": "dispute",
        "booking": booking.model_dump(),
        "provider": provider.model_dump(),
        "user_complaint": user_complaint,
        "service_checklist": service_checklist,
        "rating": rating,
        "auto_suggestion": {
            "classification": auto_classification,
            "resolution": auto_resolution,
            "refund_pkr": auto_refund
        }
    }
    
    msg_en = ""
    msg_ur = ""
    
    client = get_client()
    if client:
        try:
            response = client.models.generate_content(
                model='gemini-2.0-flash',
                contents=json.dumps(payload, ensure_ascii=False),
                config={
                    'system_instruction': _SYSTEM_PROMPT,
                    'temperature': 0.1,
                    'response_mime_type': 'application/json'
                }
            )
            data = json.loads(response.text)
            msg_en = data.get("english", "")
            msg_ur = data.get("urdu", "")
            auto_classification = data.get("classification", auto_classification)
            auto_resolution = data.get("resolution", auto_resolution)
            auto_refund = data.get("refund_pkr", auto_refund)
        except Exception as e:
            log.error("dispute_llm_failure", error=str(e))

    if not msg_en:
        msg_en = f"We are sorry for the issue. Resolution: {auto_resolution}. Refund: PKR {auto_refund}."
    if not msg_ur:
        msg_ur = f"Humein afsos hai. Resolution: {auto_resolution}. Refund: PKR {auto_refund}."

    return FollowupResult(
        mode="dispute",
        english=msg_en,
        urdu=msg_ur,
        classification=auto_classification,
        resolution=auto_resolution,
        refund_pkr=auto_refund,
        escalate_to_human=(auto_resolution == "escalate_to_human")
    )
