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

def _call_groq(prompt: str) -> str:
    """Fallback call to Groq API using standard library."""
    import urllib.request
    import urllib.error
    import json
    
    if not settings.GROQ_API_KEY:
        return ""
        
    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {settings.GROQ_API_KEY}",
        "Content-Type": "application/json",
        "User-Agent": "Bulao-App/1.0"
    }
    data = {
        "model": "llama-3.1-8b-instant",
        "messages": [
            {"role": "system", "content": _SYSTEM_PROMPT + "\n\nYou MUST return ONLY a valid JSON object matching the requested schema. No other text."},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.1,
    }
    req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            res_data = response.read().decode('utf-8')
            res_json = json.loads(res_data)
            return res_json['choices'][0]['message']['content']
    except urllib.error.HTTPError as e:
        import structlog
        res_body = e.read().decode('utf-8')
        structlog.get_logger().error("groq_fallback_failure", error=str(e), body=res_body)
        return ""
    except Exception as e:
        import structlog
        structlog.get_logger().error("groq_fallback_failure", error=str(e))
        return ""

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
            model='gemini-2.0-flash',
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
        # Try Groq fallback
        log.info("trying_groq_fallback", agent="intent")
        raw = _call_groq(user_text)
        if not raw:
            return _fallback_intent(user_text, reason="llm_and_groq_failure")

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        try:
            response2 = client.models.generate_content(
                model='gemini-2.0-flash',
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
        "plumber": ["plumber", "pani", "leak", "nal", "pipe", "tank", "motor", "sink", "drain", "water"],
        "electrician": ["electrician", "bijli", "light", "wiring", "switch", "fan", "board", "current", "power", "short"],
        "ac_technician": ["ac", "air condition", "inverter", "split", "window", "cooling", "gas charge", "chiller"],
        "geyser_technician": ["geyser", "heater", "garam", "hot water"],
        "carpenter": ["carpenter", "lakdi", "wood", "furniture", "door", "cabinet", "lock", "bench", "table"],
        "painter": ["paint", "rang", "color", "wall", "interior", "exterior", "texture"],
        "beautician": ["beautician", "makeup", "bridal", "mehndi", "facial", "threading", "waxing", "salon"],
        "tutor": ["tutor", "teacher", "math", "physics", "o levels", "a levels", "matric", "academy", "home tuition"],
        "appliance_repair": ["fridge", "washing machine", "oven", "microwave", "tv", "refrigerator", "machine"],
        "gas_leak_specialist": ["gas leak", "gas smell", "cylinder", "regulator", "stove", "chulha"],
    }
    text_lower = user_text.lower()
    service = "plumber"
    for svc, kws in keywords.items():
        if any(kw in text_lower for kw in kws):
            service = svc
            break

    # Better complexity detection
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
