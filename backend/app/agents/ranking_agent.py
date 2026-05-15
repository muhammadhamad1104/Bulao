import json
import time
from pathlib import Path
from typing import List
import structlog
from google.genai import Client
from app.config import settings
from app.models import Intent, ProviderCandidate, RankingResult, FactorScores

log = structlog.get_logger()

_PROMPT_PATH = Path(__file__).parent.parent / "prompts" / "ranking.md"
_PROMPT = _PROMPT_PATH.read_text(encoding="utf-8") if _PROMPT_PATH.exists() else ""

URGENCY_WEIGHTS = {
    "emergency": {"distance":0.30,"availability":0.30,"on_time":0.20,"rating":0.15,"specialization":0.03,"risk":0.02},
    "high": {"distance":0.20,"availability":0.25,"on_time":0.20,"rating":0.20,"specialization":0.10,"risk":0.05},
    "normal": {"distance":0.15,"availability":0.10,"on_time":0.20,"rating":0.25,"specialization":0.20,"risk":0.10},
    "flexible": {"distance":0.10,"availability":0.05,"on_time":0.15,"rating":0.30,"specialization":0.30,"risk":0.10},
}

def get_client():
    if settings.GEMINI_API_KEY and settings.GEMINI_API_KEY != "paste-your-key-here" and settings.GEMINI_API_KEY != "fake":
        return Client(api_key=settings.GEMINI_API_KEY)
    return None

def _compute_factor_scores(c: ProviderCandidate, intent: Intent) -> FactorScores:
    distance = max(0.0, 1.0 - (c.distance_km / 8.0))
    availability_map = {"available_now": 1.0, "next_slot_within_2h": 0.8, "next_slot_today": 0.5, "tomorrow_or_later": 0.2}
    availability = availability_map.get(c.availability_status, 0.0)
    rating = c.rating / 5.0
    on_time = c.on_time_score
    if intent.specialization_hint and intent.specialization_hint in c.specializations:
        specialization = 1.0
    elif intent.specialization_hint:
        specialization = 0.3
    else:
        specialization = 0.7
    risk = 1.0 - c.risk_score
    weights = URGENCY_WEIGHTS.get(intent.urgency, URGENCY_WEIGHTS["normal"])
    total = (distance*weights["distance"] + availability*weights["availability"]
             + on_time*weights["on_time"] + rating*weights["rating"]
             + specialization*weights["specialization"] + risk*weights["risk"])
    return FactorScores(distance=round(distance,2), availability=round(availability,2),
                        rating=round(rating,2), on_time=round(on_time,2),
                        specialization=round(specialization,2), risk=round(risk,2),
                        total=round(total,3))

async def run(intent: Intent, candidates: List[ProviderCandidate]) -> RankingResult:
    log.info("agent_start", agent="ranking", n_candidates=len(candidates))
    t0 = time.monotonic()
    
    if not candidates:
        return RankingResult(recommended_id=None, error="no_candidates")
        
    factor_scores = {c.id: _compute_factor_scores(c, intent) for c in candidates}
    sorted_cands = sorted(candidates, key=lambda c: factor_scores[c.id].total, reverse=True)
    top = sorted_cands[0]
    
    client = get_client()
    if not client:
        log.warn("ranking_agent_mock_mode", reason="no_api_key")
        res = RankingResult(
            recommended_id=top.id,
            top_three_ids=[c.id for c in sorted_cands[:3]],
            factor_scores=factor_scores,
            reasoning_english=f"{top.name} ranks highest with {top.rating} rating, {top.distance_km}km away.",
            reasoning_urdu=f"{top.name} sab se behtar hai — {top.rating} rating, sirf {top.distance_km} km door.",
            tradeoffs="",
            confidence="medium"
        )
        return res

    payload = {
        "intent": intent.model_dump(),
        "candidates": [c.model_dump() for c in candidates],
        "factor_scores_precomputed": {cid: fs.model_dump() for cid, fs in factor_scores.items()},
    }
    
    try:
        response = client.models.generate_content(
            model='gemini-2.5-pro',
            contents=json.dumps(payload, ensure_ascii=False),
            config={
                'system_instruction': _PROMPT,
                'temperature': 0.4,
                'response_mime_type': 'application/json'
            }
        )
        data = json.loads(response.text)
    except Exception as e:
        log.error("ranking_llm_failure", error=str(e))
        return RankingResult(
            recommended_id=top.id,
            top_three_ids=[c.id for c in sorted_cands[:3]],
            factor_scores=factor_scores,
            reasoning_english=f"{top.name} ranks highest with {top.rating} rating, {top.distance_km}km away.",
            reasoning_urdu=f"{top.name} sab se behtar hai — {top.rating} rating, sirf {top.distance_km} km door.",
            tradeoffs="",
            confidence="medium",
        )

    result = RankingResult(
        recommended_id=data.get("recommended_id"),
        top_three_ids=data.get("top_three_ids", []),
        factor_scores=factor_scores,
        reasoning_english=data.get("reasoning_english", ""),
        reasoning_urdu=data.get("reasoning_urdu", ""),
        tradeoffs=data.get("tradeoffs", ""),
        confidence=data.get("confidence", "medium"),
    )

    if result.recommended_id not in {c.id for c in candidates}:
        result.recommended_id = top.id

    if sum(ch.isdigit() for ch in result.reasoning_english) < 3:
        log.warn("ranking_reasoning_lacks_specificity", english=result.reasoning_english[:80])
        result.reasoning_english += f" Rating: {top.rating}, Distance: {top.distance_km}km."

    log.info("agent_end", agent="ranking", duration_ms=int((time.monotonic()-t0)*1000), recommended_id=result.recommended_id)
    return result
