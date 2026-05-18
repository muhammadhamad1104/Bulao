from typing import Dict, Any
from app.models import OrchestrateRequest, OrchestrateResponse, PriceQuote
from app.agents import intent_agent, discovery_agent, ranking_agent, pricing_agent
from app.db import cache_manager
from datetime import datetime, timedelta

async def run_pipeline(req: OrchestrateRequest) -> Dict[str, Any]:
    # 1. Intent Agent
    intent = await intent_agent.run(req.text)
    
    # Needs clarification path
    if intent.confidence < 0.7:
        return {
            "intent": intent,
            "needs_clarification": True,
            "clarification_question": intent.clarification_question
        }
        
    # 2. Check Cache First (Saves time and compute)
    cached_discovery, cached_ranking = cache_manager.get_cached_results(
        service_type=intent.service_type, 
        location=intent.location, 
        city=intent.city,
        max_age_hours=48 # Cache valid for 2 days as requested
    )
    
    if cached_discovery and cached_ranking:
        discovery = cached_discovery
        ranking = cached_ranking
    else:
        # 3. Discovery Agent (Live Maps API)
        discovery = await discovery_agent.run(intent, req.user_location)
        
        # No match path
        if discovery.no_match_reason or len(discovery.candidates) == 0:
            return {
                "intent": intent,
                "discovery": discovery,
                "user_message_urdu": "Maaf kijiye, abhi is waqt koi available nahi hai.",
                "user_message_english": discovery.no_match_reason or "No providers found in your area."
            }
            
        # 4. Ranking Agent (Heavy LLM Task)
        ranking = await ranking_agent.run(intent, discovery.candidates)
        
        # Save to Cache
        cache_manager.save_results(
            service_type=intent.service_type,
            location=intent.location,
            city=intent.city,
            discovery=discovery,
            ranking=ranking
        )
    
    # Find recommended provider
    recommended_provider = next((c for c in discovery.candidates if c.id == ranking.recommended_id), None)
    if not recommended_provider and discovery.candidates:
        recommended_provider = discovery.candidates[0]
        ranking.recommended_id = recommended_provider.id
        
    # 5. Pricing Agent
    if recommended_provider:
        pricing = await pricing_agent.run(intent, recommended_provider, market_demand=0.65, is_first_booking=True)
    else:
        # Fallback empty quote (should not be reached if discovery was successful)
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
