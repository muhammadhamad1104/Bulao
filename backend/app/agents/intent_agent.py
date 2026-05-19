import json
import time
from pathlib import Path
from pydantic import ValidationError
import structlog
from app.models import Intent
from app.utils.llm_client import safe_generate
from app.config import settings

log = structlog.get_logger()

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

def _fallback_intent(user_text: str, reason: str, confidence: float = 0.3) -> Intent:
    """Best-effort keyword-based fallback when the LLM fails."""
    keywords = {
        "plumber": ["plumber", "pani", "leak", "nal", "pipe", "tank", "motor", "sink", "drain", "water", "nalkaa"],
        "electrician": ["electrician", "electrical", "electric", "engineer", "bijli", "light", "wiring",
                        "switch", "fan", "board", "current", "power", "short", "voltage", "circuit",
                        "socket", "plug", "fuse", "meter", "transformer", "electrical engineer"],
        "ac_technician": ["ac", "air condition", "air conditioning", "inverter ac", "split ac",
                          "window ac", "cooling", "gas charge", "chiller", "garam ho raha"],
        "geyser_technician": ["geyser", "heater", "garam pani", "hot water", "water heater"],
        "carpenter": ["carpenter", "lakdi", "wood", "furniture", "door", "cabinet", "lock", "bench", "table", "barhain"],
        "painter": ["paint", "rang", "color", "wall", "interior", "exterior", "texture", "painting"],
        "beautician": ["beautician", "makeup", "bridal", "mehndi", "facial", "threading", "waxing", "salon", "beauty"],
        "tutor": ["tutor", "teacher", "math", "physics", "o levels", "a levels", "matric", "academy", "home tuition", "padhai"],
        "appliance_repair": ["fridge", "washing machine", "oven", "microwave", "tv", "refrigerator", "machine", "repair"],
        "gas_leak_specialist": ["gas leak", "gas smell", "cylinder", "regulator", "stove", "chulha", "gas"],
    }
    text_lower = user_text.lower()
    # Try to match a service — default to None so we can detect complete failure
    service = None
    for svc, kws in keywords.items():
        if any(kw in text_lower for kw in kws):
            service = svc
            break
    # If no keyword matched at all, default to plumber but keep confidence very low
    if service is None:
        service = "plumber"
        confidence = 0.2

    is_complex = any(x in text_lower for x in ["inverter", "bridal", "pcb", "rewiring", "structural", "expert", "specialist", "heavy", "exterior", "complex"])
    is_basic = any(x in text_lower for x in ["leak", "tap", "unclog", "bulb", "basic", "chota", "halki", "minor"])
    complexity = "complex" if is_complex else "basic" if is_basic else "intermediate"
    
    return Intent(
        service_type=service,
        location=None,
        city="Islamabad",
        time_window="now" if any(x in text_lower for x in ["abhi", "foran", "urgent", "emergency", "jaldi"]) else "flexible",
        urgency="emergency" if any(x in text_lower for x in ["leak", "short", "fire", "emergency", "foran"]) else "normal",
        job_complexity=complexity,
        gender_preference="female" if any(x in text_lower for x in ["female", "bridal", "makeup", "beautician"]) else "any",
        confidence=confidence,
        clarification_question="Aap kis ilaake mein hain? (jaise G-13, F-10)" if confidence < 0.7 else None,
        raw_notes=f"fallback:{reason}"
    )
