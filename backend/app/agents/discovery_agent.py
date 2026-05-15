import json
import math
import time
from pathlib import Path
from typing import Optional, Tuple
from datetime import datetime, timedelta
import structlog
from app.models import Intent, ProviderCandidate, DiscoveryResult

log = structlog.get_logger()

_DATA_PATH = Path(__file__).parent.parent / "data" / "providers.json"
_NEIGH_PATH = Path(__file__).parent.parent / "data" / "neighborhoods.json"

try:
    _PROVIDERS = json.loads(_DATA_PATH.read_text())
    _NEIGHBORHOODS = json.loads(_NEIGH_PATH.read_text())
except FileNotFoundError:
    _PROVIDERS = []
    _NEIGHBORHOODS = {}

def haversine_km(lat1, lng1, lat2, lng2):
    R = 6371
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2-lat1)
    dl = math.radians(lng2-lng1)
    a = math.sin(dp/2)**2 + math.cos(p1)*math.cos(p2)*math.sin(dl/2)**2
    return 2 * R * math.asin(math.sqrt(a))

def _parse_slot(slot_str):
    try:
        return datetime.fromisoformat(slot_str.replace('Z', '+00:00'))
    except ValueError:
        return None

async def run(intent: Intent, user_location: Optional[Tuple[float,float]] = None) -> DiscoveryResult:
    log.info("agent_start", agent="discovery")
    t0 = time.monotonic()
    
    alternates = []
    reason = None
    
    # 1. SERVICE FILTER
    filtered = [p for p in _PROVIDERS if intent.service_type in p.get("service_categories", [])]
    
    # 2. GENDER FILTER
    if intent.gender_preference != "any":
        filtered = [p for p in filtered if p.get("gender") == intent.gender_preference]
        
    # 3. COMPLEXITY FILTER
    if intent.job_complexity == "complex":
        temp = []
        for p in filtered:
            if p.get("years_experience", 0) >= 5:
                if intent.specialization_hint and intent.specialization_hint in p.get("specializations", []):
                    temp.append(p)
                elif not intent.specialization_hint:
                    temp.append(p)
        filtered = temp
    elif intent.job_complexity == "intermediate":
        filtered = [p for p in filtered if p.get("years_experience", 0) >= 2]
        
    if not filtered:
        reason = "No available provider matching your needs."
        log.info("agent_end", agent="discovery", duration_ms=int((time.monotonic()-t0)*1000), n_candidates=0, n_alternates=0)
        return DiscoveryResult(candidates=[], alternates=[], no_match_reason=reason)
        
    # 4. LOCATION DISTANCE
    target_lat = None
    target_lng = None
    if user_location:
        target_lat, target_lng = user_location
    elif intent.location and intent.location in _NEIGHBORHOODS:
        target_lat = _NEIGHBORHOODS[intent.location]["lat"]
        target_lng = _NEIGHBORHOODS[intent.location]["lng"]
        
    if target_lat is not None and target_lng is not None:
        for p in filtered:
            p["_distance_km"] = haversine_km(target_lat, target_lng, p.get("lat", 0), p.get("lng", 0))
    else:
        for p in filtered:
            p["_distance_km"] = 5.0 # default if no location
            
    # 5. TIME-WINDOW FILTER
    now = datetime.now()
    if intent.time_window == "now":
        target_start = now
        target_end = now + timedelta(minutes=60)
    elif "today" in intent.time_window.lower() and "morning" in intent.time_window.lower():
        target_start = now.replace(hour=8, minute=0, second=0)
        target_end = now.replace(hour=12, minute=0, second=0)
    elif "tomorrow" in intent.time_window.lower() and "morning" in intent.time_window.lower():
        target_start = (now + timedelta(days=1)).replace(hour=8, minute=0, second=0)
        target_end = (now + timedelta(days=1)).replace(hour=12, minute=0, second=0)
    elif "tomorrow" in intent.time_window.lower():
        target_start = (now + timedelta(days=1)).replace(hour=0, minute=0, second=0)
        target_end = (now + timedelta(days=2)).replace(hour=0, minute=0, second=0)
    else:
        # Flexible
        target_start = now
        target_end = now + timedelta(days=7)
        
    time_filtered = []
    for p in filtered:
        matched_slot = None
        avail_status = "tomorrow_or_later"
        next_slot = None
        
        for slot_str in p.get("available_slots", []):
            slot = _parse_slot(slot_str)
            if not slot:
                continue
            
            # Simple timezone offset matching for comparison
            slot_local = slot.replace(tzinfo=None)
            
            if not next_slot or slot_local < next_slot:
                next_slot = slot_local
                
            if target_start - timedelta(minutes=30) <= slot_local <= target_end + timedelta(minutes=30):
                if not matched_slot or slot_local < matched_slot:
                    matched_slot = slot_local
                    
        if next_slot:
            hours_diff = (next_slot - now).total_seconds() / 3600.0
            if hours_diff <= 1:
                avail_status = "available_now"
            elif hours_diff <= 2:
                avail_status = "next_slot_within_2h"
            elif next_slot.date() == now.date():
                avail_status = "next_slot_today"
        
        if matched_slot or intent.time_window == "flexible":
            p["_avail_status"] = avail_status
            p["_next_slot"] = matched_slot.isoformat() + "+05:00" if matched_slot else (next_slot.isoformat() + "+05:00" if next_slot else "")
            time_filtered.append(p)
            
    # 6. SCHEDULING INTELLIGENCE
    if len(time_filtered) < 3:
        # Get top 5 by rating ignoring time window
        sorted_by_rating = sorted([p for p in filtered if p not in time_filtered], key=lambda x: x.get("rating", 0), reverse=True)
        for p in sorted_by_rating[:5]:
            slots = p.get("available_slots", [])
            if not slots:
                continue
            ns = _parse_slot(slots[0])
            p["_avail_status"] = "tomorrow_or_later"
            if ns:
                hd = (ns.replace(tzinfo=None) - now).total_seconds() / 3600.0
                if hd <= 1:
                    p["_avail_status"] = "available_now"
                elif hd <= 2:
                    p["_avail_status"] = "next_slot_within_2h"
                elif ns.date() == now.date():
                    p["_avail_status"] = "next_slot_today"
                
            p["_next_slot"] = slots[0]
            p["_alternate_reason"] = f"Earliest available is {slots[0]} instead of requested time"
            alternates.append(p)
            
    if not time_filtered and not alternates:
        reason = "Nobody is free in your time window; consider flexible timing."
        log.info("agent_end", agent="discovery", duration_ms=int((time.monotonic()-t0)*1000), n_candidates=0, n_alternates=0)
        return DiscoveryResult(candidates=[], alternates=[], no_match_reason=reason)
        
    # 7. PRE-RANK SCORE
    def pre_rank(p):
        a_weight = {"available_now":1.0, "next_slot_within_2h":0.8, "next_slot_today":0.5, "tomorrow_or_later":0.2}.get(p.get("_avail_status", "tomorrow_or_later"), 0.2)
        r = p.get("rating", 0) / 5.0
        risk = 1.0 - p.get("risk_score", 0)
        wl = 1.0 - p.get("current_workload", 0)
        return a_weight + r + risk + wl
        
    time_filtered.sort(key=pre_rank, reverse=True)
    
    # 9. Top 8
    time_filtered = time_filtered[:8]
    
    def build_candidate(p, is_alternate=False):
        ph = p.get("phone", "")
        masked = "+92 XXX-XXX-" + ph[-4:] if len(ph) >= 4 else ph
        
        return ProviderCandidate(
            id=p["id"],
            name=p["name"],
            service_categories=p["service_categories"],
            specializations=p.get("specializations", []),
            distance_km=round(p.get("_distance_km", 0.0), 1),
            neighborhood=p["neighborhood"],
            rating=p["rating"],
            completed_jobs_in_area=p.get("completed_jobs_by_neighborhood", {}).get(p["neighborhood"], 0),
            on_time_score=p["on_time_score"],
            cancellation_rate=p["cancellation_rate"],
            review_recency_days=p["review_recency_days"],
            risk_score=p["risk_score"],
            current_workload=p["current_workload"],
            availability_status=p.get("_avail_status", "tomorrow_or_later"),
            next_slot=p.get("_next_slot", ""),
            base_visit_fee_pkr=p["base_visit_fee_pkr"],
            rate_per_hour_pkr=p["rate_per_hour_pkr"],
            gender=p["gender"],
            years_experience=p["years_experience"],
            languages=p["languages"],
            verified=p["verified"],
            phone_masked=masked,
            alternate_slot_reason=p.get("_alternate_reason") if is_alternate else None
        )
        
    final_candidates = [build_candidate(p) for p in time_filtered]
    final_alternates = [build_candidate(p, True) for p in alternates]
    
    result = DiscoveryResult(candidates=final_candidates, alternates=final_alternates, no_match_reason=reason)
    log.info("agent_end", agent="discovery", duration_ms=int((time.monotonic()-t0)*1000), n_candidates=len(result.candidates), n_alternates=len(result.alternates))
    return result
