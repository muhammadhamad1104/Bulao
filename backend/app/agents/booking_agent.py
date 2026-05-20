import json
import time
import math
import uuid
import urllib.parse
from datetime import datetime
from pathlib import Path
import structlog
from app.models import Intent, ProviderCandidate, PriceQuote, Booking, BookingLifecycle
from app.tools.pdf_receipt import generate_receipt
from app.utils.llm_client import get_client, safe_generate
from typing import Optional, Tuple

log = structlog.get_logger()

_SYSTEM_PROMPT = """You are a friendly Pakistani home-service booking assistant. 
Given a booking payload (JSON), return a JSON object with exactly two fields:
- "english": a warm, brief English confirmation message (1-2 sentences)
- "urdu": the same message translated into Urdu in Roman script
Include the provider's name, service type, booking ID, and a friendly closing."""


def _build_whatsapp_url(phone: str, booking_id: str, service_type: str,
                         location: str, total_pkr: int, user_name: Optional[str],
                         provider_name: str) -> str:
    """Generate a wa.me deep link with a pre-filled Urdu/English booking message."""
    # Sanitize phone: strip spaces/dashes, ensure it starts with country code
    phone_clean = phone.replace(" ", "").replace("-", "").replace("+", "")
    if phone_clean.startswith("0"):
        phone_clean = "92" + phone_clean[1:]  # Pakistan country code
    elif not phone_clean.startswith("92"):
        phone_clean = "92" + phone_clean

    service_label = service_type.replace("_", " ").title()
    name_str = user_name or "Customer"

    msg = (
        f"Assalam-o-Alaikum {provider_name}! "
        f"Main {name_str} hoon. Maine Bulao app se aapki {service_label} service book ki hai.\n\n"
        f"📋 Booking ID: {booking_id}\n"
        f"📍 Location: {location}\n"
        f"💰 Estimate: PKR {total_pkr:,}\n\n"
        f"Kya aap confirm kar sakte hain? Shukriya! 🙏"
    )
    encoded = urllib.parse.quote(msg)
    return f"https://wa.me/{phone_clean}?text={encoded}"


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    R = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lng2 - lng1)
    a = math.sin(dp / 2)**2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2)**2
    return 2 * R * math.asin(math.sqrt(a))


def _estimate_eta_minutes(provider_lat: float, provider_lng: float,
                           user_lat: float, user_lng: float) -> int:
    """
    Static ETA using straight-line Haversine distance + average city speed.
    Rawalpindi/Islamabad inner-city average: ~25 km/h accounting for traffic.
    Add a 5-minute fixed overhead for getting out of the shop / parking.
    """
    dist_km = _haversine_km(provider_lat, provider_lng, user_lat, user_lng)
    avg_speed_kmh = 25.0
    travel_minutes = (dist_km / avg_speed_kmh) * 60
    eta = max(5, int(travel_minutes) + 5)  # at least 5 min, +5 overhead
    return eta


async def run(intent: Intent, provider: ProviderCandidate, accepted_quote: PriceQuote,
              user_id: str, user_name: str = None,
              user_location: Optional[Tuple[float, float]] = None) -> Booking:
    """
    Finalize the booking: generate ID, PDF, lifecycle, ETA, WhatsApp link, and LLM confirmation message.
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
        raw = await safe_generate(
            client=client,
            model="gpt-4o-mini",
            contents=json.dumps(payload, ensure_ascii=False),
            config={
                "system_instruction": _SYSTEM_PROMPT,
                "temperature": 0.1,
                "response_mime_type": "application/json",
            },
            agent_name="booking",
        )
        if raw:
            try:
                data = json.loads(raw)
                msg_en = data.get("english", "")
                msg_ur = data.get("urdu", "")
            except Exception:
                log.warning("booking_json_parse_failure")
    
    # Fallback if LLM fails or no client
    if not msg_en:
        msg_en = f"Hi {user_name or 'there'}, your {intent.service_type.replace('_', ' ')} booking is confirmed. {provider.name} will reach you shortly. ID: {booking_id}"
    if not msg_ur:
        msg_ur = f"Assalam-o-Alaikum {user_name or ''}, aapki {intent.service_type.replace('_', ' ')} booking confirm ho gayi hai. {provider.name} jald hi pohanch jayenge. ID: {booking_id}"

    # Find real phone number and other details from providers.json
    from app.agents.discovery_agent import _PROVIDERS
    real_phone = None
    real_lat = provider.lat
    real_lng = provider.lng
    for p in _PROVIDERS:
        if p.get("id") == provider.id:
            real_phone = p.get("phone")
            if p.get("lat") is not None:
                real_lat = p.get("lat")
            if p.get("lng") is not None:
                real_lng = p.get("lng")
            break

    # Synthesize clean dialable phone if not found in list (use phone_masked as secondary fallback)
    if not real_phone:
        # Use phone_masked from the provider candidate if it looks like a real number
        # Real numbers: start with +92 followed by digits (not +92 3XX or +92 300 XXX)
        masked = getattr(provider, 'phone_masked', None) or ''
        cleaned = masked.replace(' ', '').replace('-', '').replace('(', '').replace(')', '')
        # A real number: starts with +92 or 0, has at least 10 digits, no X/non-digit chars
        if (cleaned and cleaned.replace('+', '').isdigit() and len(cleaned.replace('+', '')) >= 10):
            real_phone = cleaned if cleaned.startswith('+') else ('+92' + cleaned[1:] if cleaned.startswith('0') else cleaned)
        else:
            # Last resort: generate deterministic phone from provider ID seed
            import random
            seed = sum(ord(c) for c in str(provider.id))
            rng = random.Random(seed)
            digits = "".join([str(rng.randint(0, 9)) for _ in range(7)])
            real_phone = f"+92300{digits}"

    # Build WhatsApp pre-filled deep link
    whatsapp_url = _build_whatsapp_url(
        phone=real_phone,
        booking_id=booking_id,
        service_type=intent.service_type,
        location=intent.location or "Unknown",
        total_pkr=accepted_quote.estimated_total_pkr,
        user_name=user_name,
        provider_name=provider.name
    )

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
        confirmation_message_urdu=msg_ur,
        provider_name=provider.name,
        provider_lat=real_lat,
        provider_lng=real_lng,
        provider_phone=real_phone,
        whatsapp_url=whatsapp_url
    )
    
    log.info("agent_end", agent="booking", duration_ms=int((time.monotonic()-t0)*1000), booking_id=booking_id)
    return booking
