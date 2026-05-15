import json
import time
from pathlib import Path
from pydantic import ValidationError
import structlog
from app.models import Intent
from google.genai import Client
from app.config import settings

log = structlog.get_logger()

_PROMPT_PATH = Path(__file__).parent.parent / "prompts" / "intent.md"
_SYSTEM_PROMPT = _PROMPT_PATH.read_text(encoding="utf-8") if _PROMPT_PATH.exists() else ""

def get_client():
    if settings.GEMINI_API_KEY and settings.GEMINI_API_KEY != "paste-your-key-here" and settings.GEMINI_API_KEY != "fake":
        return Client(api_key=settings.GEMINI_API_KEY)
    return None

async def run(user_text: str) -> Intent:
    """Extract structured Intent from user text. Falls back gracefully on parse failure."""
    log.info("agent_start", agent="intent", input_len=len(user_text))
    t0 = time.monotonic()
    
    client = get_client()
    if not client:
        log.warn("intent_agent_mock_mode", reason="no_api_key")
        # For mock tests without API key
        if "plumber" in user_text.lower():
            if "mere ghar" in user_text.lower():
                return _fallback_intent(user_text, reason="mock", confidence=0.3)
            return Intent(service_type="plumber", time_window="now", urgency="normal", job_complexity="basic", confidence=0.8, city="Islamabad")
        elif "ac" in user_text.lower():
            return Intent(service_type="ac_technician", location="G-13", time_window="tomorrow_morning", urgency="normal", job_complexity="basic", confidence=0.9, city="Islamabad")
        return _fallback_intent(user_text, reason="mock", confidence=0.8)

    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=user_text,
            config={
                'system_instruction': _SYSTEM_PROMPT,
                'temperature': 0.1,
                'response_mime_type': 'application/json'
            }
        )
        raw = response.text
    except Exception as e:
        log.error("agent_llm_failure", agent="intent", error=str(e))
        return _fallback_intent(user_text, reason="llm_failure")

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        try:
            response2 = client.models.generate_content(
                model='gemini-2.5-flash',
                contents=user_text + "\n\nReturn ONLY valid JSON. No markdown.",
                config={
                    'system_instruction': _SYSTEM_PROMPT,
                    'temperature': 0.1,
                    'response_mime_type': 'application/json'
                }
            )
            raw2 = response2.text
            data = json.loads(raw2)
        except Exception:
            log.error("agent_json_parse_failure", agent="intent", raw_preview=raw[:200])
            return _fallback_intent(user_text, reason="json_parse")

    try:
        intent = Intent.model_validate(data)
    except ValidationError as e:
        log.error("agent_schema_violation", agent="intent", errors=e.errors()[:3])
        return _fallback_intent(user_text, reason="schema_violation")

    log.info("agent_end", agent="intent", duration_ms=int((time.monotonic()-t0)*1000), service_type=intent.service_type, confidence=intent.confidence)
    return intent

def _fallback_intent(user_text: str, reason: str, confidence: float = 0.3) -> Intent:
    """Best-effort keyword-based fallback when the LLM fails."""
    keywords = {
        "plumber": ["plumber","pani","leak","nal","pipe","ghouse"],
        "electrician": ["electrician","bijli","light","wiring","switch"],
        "ac_technician": ["ac","air condition","inverter","split","window"],
        "geyser_technician": ["geyser","heater","garam pani"],
        "carpenter": ["carpenter","lakdi","wood","furniture","cupboard"],
        "painter": ["paint","painter","rang","color"],
        "beautician": ["beautician","makeup","bridal","facial","hair"],
        "tutor": ["tutor","teacher","ustaad","math","english"],
        "appliance_repair": ["fridge","washing machine","oven","appliance"],
        "gas_leak_specialist": ["gas leak","gas smell"],
    }
    text_lower = user_text.lower()
    service = "plumber"
    for svc, kws in keywords.items():
        if any(kw in text_lower for kw in kws):
            service = svc
            break

    return Intent(
        service_type=service,
        location=None,
        city="Islamabad",
        time_window="flexible",
        urgency="normal",
        job_complexity="basic",
        gender_preference="any",
        confidence=confidence,
        clarification_question="Aap ne kya kaam karwana hai? Sector ya area ka naam bhi batayein." if confidence < 0.7 else None,
        raw_notes=f"fallback:{reason}"
    )
