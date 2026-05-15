from fastapi import APIRouter, HTTPException
from app.models import OrchestrateRequest, OrchestrateResponse, PriceQuote
from app.agents import intent_agent, discovery_agent, ranking_agent, pricing_agent, booking_agent
from app.config import settings
from pathlib import Path
import json
from datetime import datetime, timedelta
import structlog

log = structlog.get_logger()
router = APIRouter(tags=["Pipeline"])

@router.post("/orchestrate", response_model=OrchestrateResponse)
async def orchestrate(req: OrchestrateRequest):
    """Run the 6-agent pipeline in sequence."""
    if settings.DEMO_MODE:
        log.info("orchestrate_demo_mode", user_id=req.user_id)
        canned_path = Path(__file__).parent.parent / "data" / "demo_canned_response.json"
        if canned_path.exists():
            return OrchestrateResponse.model_validate(json.loads(canned_path.read_text()))
        
    log.info("orchestrate_request", user_id=req.user_id, text=req.text)
    
    # 1. Intent Agent
    intent = await intent_agent.run(req.text)
    
    # Clarification Path
    if intent.needs_clarification or intent.confidence < 0.7:
        return OrchestrateResponse(
            intent=intent,
            needs_clarification=True,
            clarification_question=intent.clarification_question
        )

    # 2. Discovery Agent
    discovery = await discovery_agent.run(intent, req.user_location)
    
    # No Match Path
    if not discovery.candidates and not discovery.alternates:
        return OrchestrateResponse(
            intent=intent,
            discovery=discovery,
            user_message_urdu="Maaf kijiye, is waqt koi available nahi hai.",
            user_message_english=discovery.no_match_reason or "No providers found."
        )
        
    # 3. Ranking Agent
    ranking = await ranking_agent.run(intent, discovery.candidates)
    recommended_provider = next((c for c in discovery.candidates if c.id == ranking.recommended_id), None)
    if not recommended_provider and discovery.candidates:
        recommended_provider = discovery.candidates[0]

    # 4. Pricing Agent
    pricing = None
    if recommended_provider:
        pricing = await pricing_agent.run(intent, recommended_provider, market_demand=0.6, is_first_booking=True)
    
    if not pricing:
        pricing = PriceQuote(
            quote_id="QT-EMPTY",
            line_items=[],
            subtotal_pkr=0,
            estimated_total_pkr=0,
            estimated_range_pkr=(0, 0),
            explanation_english="No provider available for pricing.",
            explanation_urdu="Pricing ke liye koi provider available nahi hai.",
            fairness_note="",
            expires_at=(datetime.now() + timedelta(minutes=15)).isoformat()
        )
    
    # 5. Booking Agent Preview
    booking_preview = {
        "provider_id": recommended_provider.id if recommended_provider else "",
        "scheduled_time": recommended_provider.next_slot if recommended_provider else "",
        "expected_total_pkr": pricing.estimated_total_pkr
    }

    # 6. Follow-up Planned
    followup_planned = {
        "reminder_at": (datetime.now() + timedelta(minutes=120)).isoformat() + "+05:00",
        "checkin_at": (datetime.now() + timedelta(hours=24)).isoformat() + "+05:00"
    }

    return OrchestrateResponse(
        intent=intent,
        discovery=discovery,
        ranking=ranking,
        pricing=pricing,
        booking_preview=booking_preview,
        followup_planned=followup_planned
    )
