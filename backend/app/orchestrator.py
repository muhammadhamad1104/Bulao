from typing import Dict, Any
from app.models import OrchestrateRequest, OrchestrateResponse, PriceQuote
from app.agents import intent_agent, discovery_agent, ranking_agent, pricing_agent
from app.db import cache_manager
from datetime import datetime, timedelta
import structlog

log = structlog.get_logger()

async def run_pipeline(req: OrchestrateRequest) -> Dict[str, Any]:
    # 1. Intent Agent
    intent = await intent_agent.run(req.text)
    
    # Only reject if the user is not asking for a valid supported service
    valid_services = ["plumber","electrician","ac_technician","geyser_technician","carpenter","painter","beautician","tutor","appliance_repair","gas_leak_specialist"]
    if not intent.service_type or intent.service_type not in valid_services:
        return {
            "intent": intent,
            "needs_clarification": True,
            "clarification_question": intent.clarification_question or "Aap ko kis kism ki service chahiye? (What type of service do you need?)"
        }

    # Resolve the target coordinates (GPS takes priority over query text)
    target_lat = req.user_location[0] if req.user_location else None
    target_lng = req.user_location[1] if req.user_location else None

    # 2. Discovery Agent — ALWAYS real-time, no caching
    # Discovery hits the live Overpass API with the user's actual GPS coordinates.
    # Results are user-specific and time-sensitive (availability slots, distance, etc.)
    discovery = await discovery_agent.run(intent, req.user_location)

    if discovery.no_match_reason or len(discovery.candidates) == 0:
        return {
            "intent": intent,
            "discovery": discovery,
            "user_message_urdu": "Maaf kijiye, abhi is waqt koi available nahi hai.",
            "user_message_english": discovery.no_match_reason or "No providers found in your area."
        }

    # 3. Ranking Agent — check 5-minute geo-bucket cache to avoid duplicate LLM calls
    # If another user in the same ~2km area already triggered a ranking call in the last
    # 5 minutes for the same service, we reuse those scores instead of calling the LLM again.
    ranking = cache_manager.get_cached_ranking(intent.service_type, target_lat, target_lng)

    if not ranking:
        ranking = await ranking_agent.run(intent, discovery.candidates)
        # Save ranking result keyed to this geographic cell for 5 minutes
        cache_manager.save_ranking(intent.service_type, target_lat, target_lng, ranking)

    # Find recommended provider from the fresh discovery pool
    recommended_provider = next((c for c in discovery.candidates if c.id == ranking.recommended_id), None)
    if not recommended_provider and discovery.candidates:
        recommended_provider = discovery.candidates[0]
        ranking.recommended_id = recommended_provider.id

    # 4. Pricing Agent — always fresh, calculated per provider per user
    if recommended_provider:
        pricing = await pricing_agent.run(intent, recommended_provider, market_demand=0.65, is_first_booking=True)
    else:
        pricing = PriceQuote(quote_id="QT-empty", line_items=[], subtotal_pkr=0, estimated_total_pkr=0, estimated_range_pkr=(0,0), explanation_english="", explanation_urdu="", fairness_note="", expires_at="")

    response = OrchestrateResponse(
        intent=intent,
        discovery=discovery,
        ranking=ranking,
        pricing=pricing,
        booking_preview={
            "provider_id": recommended_provider.id if recommended_provider else "",
            "scheduled_time": recommended_provider.next_slot if recommended_provider else "",
            "expected_total_pkr": pricing.estimated_total_pkr
        },
        followup_planned={
            "reminder_at": (datetime.now() + timedelta(hours=2)).isoformat() + "+05:00",
            "checkin_at": (datetime.now() + timedelta(hours=24)).isoformat() + "+05:00"
        }
    )
    return response.model_dump()
