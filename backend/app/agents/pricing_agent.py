import json
import time
import uuid
from typing import List, Tuple
from pathlib import Path
from datetime import datetime, timedelta
import structlog
from app.models import Intent, ProviderCandidate, PriceLineItem, PriceQuote
from app.utils.llm_client import get_client, safe_generate

log = structlog.get_logger()

_PROMPT_PATH = Path(__file__).parent.parent / "prompts" / "pricing.md"
_PROMPT = _PROMPT_PATH.read_text(encoding="utf-8") if _PROMPT_PATH.exists() else ""

COMPLEXITY_HOURS = {"basic": 1.0, "intermediate": 1.5, "complex": 2.5}
COMPLEXITY_MULTIPLIER = {"basic": 1.0, "intermediate": 1.25, "complex": 1.6}
URGENCY_SURCHARGE = {"emergency": 500, "high": 200, "normal": 0, "flexible": -100}

def _compute_line_items(intent: Intent, provider: ProviderCandidate, market_demand: float, is_first_booking: bool) -> Tuple[List[PriceLineItem], int]:
    items = []
    items.append(PriceLineItem(label_english="Visit fee", label_urdu="Visit fee", amount_pkr=provider.base_visit_fee_pkr, kind="base"))
    
    extra_km = max(0, provider.distance_km - 3.0)
    distance_fee = int(extra_km * 50)
    if distance_fee > 0:
        items.append(PriceLineItem(label_english=f"Distance ({extra_km:.1f} km)", label_urdu=f"Distance ({extra_km:.1f} km)", amount_pkr=distance_fee, kind="base"))
        
    hours = COMPLEXITY_HOURS[intent.job_complexity]
    service_fee = int(provider.rate_per_hour_pkr * hours)
    items.append(PriceLineItem(label_english=f"Service time (~{hours}h)", label_urdu=f"Service time (~{hours} ghante)", amount_pkr=service_fee, kind="base"))
    
    subtotal_pre = sum(i.amount_pkr for i in items)
    
    multiplier = COMPLEXITY_MULTIPLIER[intent.job_complexity]
    if multiplier > 1.0:
        adjustment = int(subtotal_pre * (multiplier - 1.0))
        items.append(PriceLineItem(label_english=f"Complexity ({intent.job_complexity})", label_urdu=f"Complexity ({intent.job_complexity})", amount_pkr=adjustment, kind="multiplier"))
        
    surcharge = URGENCY_SURCHARGE[intent.urgency]
    if surcharge != 0:
        items.append(PriceLineItem(label_english=f"Urgency ({intent.urgency})", label_urdu=f"Urgency ({intent.urgency})", amount_pkr=surcharge, kind="addon"))
        
    surge_pct = 0.20 if market_demand > 0.7 else (0.10 if market_demand > 0.5 else 0.0)
    if surge_pct > 0:
        running = sum(i.amount_pkr for i in items)
        surge_amount = int(running * surge_pct)
        items.append(PriceLineItem(label_english=f"Demand surge (+{int(surge_pct*100)}%)", label_urdu=f"Demand surge (+{int(surge_pct*100)}%)", amount_pkr=surge_amount, kind="surge"))
        
    if is_first_booking:
        running = sum(i.amount_pkr for i in items)
        discount = max(-200, min(-50, -int(running * 0.05)))
        items.append(PriceLineItem(label_english="Welcome discount", label_urdu="Welcome discount", amount_pkr=discount, kind="discount"))
        
    total = sum(i.amount_pkr for i in items)
    total_rounded = round(total / 10) * 10
    return items, total_rounded

async def run(intent: Intent, provider: ProviderCandidate, market_demand: float = 0.65, is_first_booking: bool = True) -> PriceQuote:
    log.info("agent_start", agent="pricing")
    t0 = time.monotonic()
    
    line_items, total = _compute_line_items(intent, provider, market_demand, is_first_booking)
    range_low = int(total * 0.9)
    range_high = int(total * 1.15)
    if range_high - range_low < 250:
        range_high = range_low + 250

    # Deterministic defaults — valid even if LLM fails
    explanation_en = f"Your estimate is PKR {range_low:,}–{range_high:,}. Includes visit fee, service time, and adjustments shown below."
    explanation_ur = f"Aapka estimate PKR {range_low:,}–{range_high:,} hai. Visit fee, service time, aur neeche di gayi tafseelat shamil hain."
    fairness = f"Provider receives PKR {int(total * 0.85):,} after platform fee."
    
    client = get_client()
    if client:
        payload = {
            "intent": intent.model_dump(),
            "provider": provider.model_dump(),
            "market_demand": market_demand,
            "is_first_booking": is_first_booking,
            "line_items": [i.model_dump() for i in line_items],
            "estimated_total_pkr": total,
            "estimated_range_pkr": [range_low, range_high],
        }
        raw = await safe_generate(
            client=client,
            model="gemini-2.0-flash",
            contents=json.dumps(payload, ensure_ascii=False),
            config={
                "system_instruction": _PROMPT,
                "temperature": 0.1,
                "response_mime_type": "application/json",
            },
            agent_name="pricing",
        )
        if raw:
            try:
                data = json.loads(raw)
                explanation_en = data.get("explanation_english", explanation_en)
                explanation_ur = data.get("explanation_urdu", explanation_ur)
                fairness = data.get("fairness_note", fairness)
            except Exception:
                log.warning("pricing_json_parse_failure", raw_preview=raw[:200])
        else:
            log.warning("pricing_llm_fallback", reason="all_retries_exhausted")
    else:
        log.warning("pricing_agent_mock_mode", reason="no_api_key")

    quote = PriceQuote(
        quote_id=f"QT-{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}",
        line_items=line_items,
        subtotal_pkr=sum(i.amount_pkr for i in line_items),
        estimated_total_pkr=total,
        estimated_range_pkr=(range_low, range_high),
        explanation_english=explanation_en,
        explanation_urdu=explanation_ur,
        fairness_note=fairness,
        expires_at=(datetime.now() + timedelta(minutes=15)).isoformat() + "+05:00",
    )
    
    log.info("agent_end", agent="pricing", duration_ms=int((time.monotonic()-t0)*1000), estimated_total_pkr=total)
    return quote
