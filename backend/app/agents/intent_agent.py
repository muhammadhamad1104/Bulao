import json
import time
from pathlib import Path
from pydantic import ValidationError
import structlog
from app.models import Intent
from app.utils.llm_client import safe_generate
from app.config import settings

log = structlog.get_logger()

def get_client():
    """Dummy get_client to prevent AttributeError in old unit tests."""
    return None

_PROMPT_PATH = Path(__file__).parent.parent / "prompts" / "intent.md"
_SYSTEM_PROMPT = _PROMPT_PATH.read_text(encoding="utf-8") if _PROMPT_PATH.exists() else ""

async def run(user_text: str) -> Intent:
    """Extract structured Intent from user text using the bundled local model."""
    log.info("agent_start", agent="intent", input_len=len(user_text))
    t0 = time.monotonic()
    
    # 1. Attempt Local Model Call
    raw = await safe_generate(
        client=None,
        model="local",
        contents=user_text,
        config={
            "system_instruction": _SYSTEM_PROMPT,
            "temperature": 0.1,
            "response_mime_type": "application/json",
        },
        agent_name="intent",
    )

    # 2. If local model fails, fall back to deterministic keywords
    if not raw:
        return _fallback_intent(user_text, reason="local_llm_failure")

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        log.error("agent_json_parse_failure", agent="intent", raw_preview=raw[:200])
        return _fallback_intent(user_text, reason="json_parse")

    try:
        intent = Intent.model_validate(data)
    except ValidationError as e:
        log.error("agent_schema_violation", agent="intent", errors=e.errors()[:3])
        return _fallback_intent(user_text, reason="schema_violation")

    log.info("agent_end", agent="intent", duration_ms=int((time.monotonic()-t0)*1000),
             service_type=intent.service_type, confidence=intent.confidence)
    return intent

def _fallback_intent(user_text: str, reason: str) -> Intent:
    """Best-effort keyword-based fallback when the LLM fails."""
    keywords = {
        "plumber": ["plumber", "pani", "leak", "nal", "pipe", "tank", "motor pump", "sink", "drain", "water", "nalkaa", "tap", "washroom", "bathroom"],
        "electrician": ["electrician", "electrical", "electric", "engineer", "bijli", "light", "wiring",
                        "switch", "fan", "board", "current", "power", "short", "voltage", "circuit",
                        "socket", "plug", "fuse", "meter", "transformer", "electrical engineer", "wiring guy", "bijli wala"],
        "ac_technician": ["ac", "air condition", "air conditioning", "inverter ac", "split ac",
                          "window ac", "cooling", "gas charge", "chiller", "garam ho raha"],
        "geyser_technician": ["geyser", "heater", "garam pani", "hot water", "water heater"],
        "carpenter": ["carpenter", "lakdi", "wood", "furniture", "door", "cabinet", "lock", "bench", "table", "barhain", "woodworker", "furniture maker", "cabinetmaker", "lakdi ka kaam"],
        "painter": ["paint", "rang", "color", "wall", "interior", "exterior", "texture", "painting"],
        "beautician": ["beautician", "makeup", "bridal", "mehndi", "facial", "threading", "waxing", "salon", "beauty"],
        "tutor": ["tutor", "teacher", "math", "physics", "o levels", "a levels", "matric", "academy", "home tuition", "padhai"],
        "appliance_repair": ["mechanic", "mistri", "handyman", "repair", "repairing", "theek", "kharab",
                             "fridge", "washing machine", "oven", "microwave", "tv", "refrigerator",
                             "machine", "motor", "pump", "generator", "geyser repair", "appliance",
                             "mechanic chahie", "mistri chahie", "theeq karna"],
        "gas_leak_specialist": ["gas leak", "gas smell", "cylinder", "regulator", "stove", "chulha", "gas"],
    }

    # Common Islamabad/Pakistan sectors & areas — catches STT errors like "ji 13" → "G-13"
    location_patterns = {
        "G-13": ["g13", "g 13", "ji 13", "gee 13", "g-13"],
        "G-11": ["g11", "g 11", "ji 11", "g-11"],
        "G-10": ["g10", "g 10", "ji 10", "g-10"],
        "G-9":  ["g9",  "g 9",  "ji 9",  "g-9"],
        "F-10": ["f10", "f 10", "f-10"],
        "F-11": ["f11", "f 11", "f-11"],
        "F-7":  ["f7",  "f 7",  "f-7"],
        "F-8":  ["f8",  "f 8",  "f-8"],
        "E-11": ["e11", "e 11", "e-11"],
        "I-8":  ["i8",  "i 8",  "i-8"],
        "I-10": ["i10", "i 10", "i-10"],
        "Bahria Town": ["bahria", "bahria town"],
        "DHA": ["dha"],
        "Gulberg": ["gulberg"],
        "Johar Town": ["johar"],
        "Saddar Rawalpindi": ["rawalpindi", "pindi", "saddar", "shamsabad", "adiala", "satellite town", "murree road", "chandni chowk", "rehmanabad"],
    }

    text_lower = user_text.lower()

    # Match service
    service = None
    for svc, kws in keywords.items():
        if any(kw in text_lower for kw in kws):
            service = svc
            break

    # Match location (including STT error variants)
    location = None
    for loc, variants in location_patterns.items():
        if any(v in text_lower for v in variants):
            location = loc
            break

    # Confidence: high if service detected, medium if location also found
    clarification_question = None
    needs_clarification = False
    specialization_hint = None  # Set below if user says something unrecognized
    if service is None:
        # Don't guess — pass the raw user text to discovery so Google Places
        # can search for whatever the user actually said (e.g. "mechanic")
        service = "appliance_repair"  # Schema needs a valid value; discovery overrides via specialization_hint
        confidence = 0.15
        needs_clarification = False  # Don't stop flow — let Google find it
        # Store stripped user text so discovery_agent uses it as the search query
        specialization_hint = user_text.strip()
    elif location:
        confidence = 0.85  # Service + location known — proceed confidently
    else:
        confidence = 0.55  # Service known, location unknown — trigger location clarification
        needs_clarification = True
        clarification_question = "Aap Islamabad ke kis sector ya area se baat kar rahe hain? (Which sector or area of Islamabad are you located in?)"

    is_complex = any(x in text_lower for x in ["inverter", "bridal", "pcb", "rewiring", "structural", "expert", "specialist", "heavy", "exterior", "complex"])
    is_basic = any(x in text_lower for x in ["leak", "tap", "unclog", "bulb", "basic", "chota", "halki", "minor"])
    complexity = "complex" if is_complex else "basic" if is_basic else "intermediate"

    return Intent(
        service_type=service,
        location=location,
        city="Rawalpindi" if location and "rawalpindi" in (location or "").lower() else "Islamabad",
        time_window="now" if any(x in text_lower for x in ["abhi", "foran", "urgent", "emergency", "jaldi"]) else "flexible" if any(x in text_lower for x in ["flexible", "kabhi bhi", "whenever", "baad mein"]) else "now",
        urgency="emergency" if any(x in text_lower for x in ["leak", "short", "fire", "emergency", "foran"]) else "normal",
        job_complexity=complexity,
        gender_preference="female" if any(x in text_lower for x in ["female", "bridal", "makeup", "beautician"]) else "any",
        confidence=confidence,
        needs_clarification=needs_clarification,
        clarification_question=clarification_question,
        specialization_hint=specialization_hint,
        raw_notes=f"fallback:{reason}"
    )
