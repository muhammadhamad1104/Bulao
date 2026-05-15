import json
import time
import uuid
from datetime import datetime
from pathlib import Path
import structlog
from app.models import Intent, ProviderCandidate, PriceQuote, Booking, BookingLifecycle
from app.tools.pdf_receipt import generate_receipt
from google.genai import Client
from app.config import settings

log = structlog.get_logger()

_PROMPT_PATH = Path(__file__).parent.parent / "prompts" / "booking.md"
_SYSTEM_PROMPT = _PROMPT_PATH.read_text(encoding="utf-8") if _PROMPT_PATH.exists() else ""

def get_client():
    if settings.GEMINI_API_KEY and settings.GEMINI_API_KEY != "fake":
        return Client(api_key=settings.GEMINI_API_KEY)
    return None

async def run(intent: Intent, provider: ProviderCandidate, accepted_quote: PriceQuote, user_id: str, user_name: str = None) -> Booking:
    """
    Finalize the booking: generate ID, PDF, lifecycle, and LLM confirmation message.
    """
    log.info("agent_start", agent="booking", user_id=user_id)
    t0 = time.monotonic()
    
    booking_id = f"BUL-{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"
    now_iso = datetime.now().isoformat() + "+05:00"
    
    # 1. Generate Receipt PDF
    try:
        receipt_path = generate_receipt(booking_id, intent, provider, accepted_quote, user_name)
        # In a real app, this would be a GCS URL. For local/demo:
        receipt_url = f"http://localhost:8080/{receipt_path}"
    except Exception as e:
        log.error("receipt_generation_failure", error=str(e))
        receipt_url = None

    # 2. Draft confirmation messages via LLM
    payload = {
        "booking": {
            "booking_id": booking_id,
            "service_type": intent.service_type,
            "location": intent.location,
            "total_pkr": accepted_quote.estimated_total_pkr
        },
        "provider": {
            "name": provider.name,
            "rating": provider.rating
        },
        "user_name": user_name
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
        except Exception as e:
            log.error("llm_message_generation_failure", error=str(e))
    
    # Fallback if LLM fails or no client
    if not msg_en:
        msg_en = f"Hi {user_name or 'there'}, your {intent.service_type.replace('_', ' ')} booking is confirmed. {provider.name} will reach you shortly. ID: {booking_id}"
    if not msg_ur:
        msg_ur = f"Assalam-o-Alaikum {user_name or ''}, aapki {intent.service_type.replace('_', ' ')} booking confirm ho gayi hai. {provider.name} jald hi pohanch jayenge. ID: {booking_id}"

    booking = Booking(
        booking_id=booking_id,
        user_id=user_id,
        provider_id=provider.id,
        service_type=intent.service_type,
        location=intent.location or "Unknown",
        city=intent.city,
        scheduled_time=provider.next_slot,
        status="confirmed",
        lifecycle=BookingLifecycle(confirmed_at=now_iso),
        accepted_quote=accepted_quote,
        intent_snapshot=intent,
        receipt_url=receipt_url,
        confirmation_message_english=msg_en,
        confirmation_message_urdu=msg_ur
    )
    
    log.info("agent_end", agent="booking", duration_ms=int((time.monotonic()-t0)*1000), booking_id=booking_id)
    return booking
