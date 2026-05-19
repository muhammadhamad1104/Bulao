import json
import math
import time
import urllib.request
import urllib.parse
from datetime import datetime, timedelta
from typing import Optional, Tuple, List, Dict
import random
import uuid

import structlog
from app.models import Intent, ProviderCandidate, DiscoveryResult
from app.config import settings

log = structlog.get_logger()

def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    R = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lng2 - lng1)
    a = math.sin(dp / 2)**2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2)**2
    return 2 * R * math.asin(math.sqrt(a))

def _geocode_location(location: str, city: str) -> Optional[Tuple[float, float]]:
    """Geocode a location using Nominatim API (OpenStreetMap)."""
    if not location and not city:
        return None
        
    query = f"{location}, {city}" if location else city
    encoded_query = urllib.parse.quote(query)
    url = f"https://nominatim.openstreetmap.org/search?q={encoded_query}&format=json&limit=1"
    
    req = urllib.request.Request(url, headers={'User-Agent': 'BulaoHackathon/1.0'})
    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode('utf-8'))
            if data and len(data) > 0:
                return float(data[0]['lat']), float(data[0]['lon'])
    except Exception as e:
        log.error("geocoding_failure", error=str(e), query=query)
    return None

def _get_overpass_query(service_type: str, lat: float, lng: float, radius_m: int = 8000) -> str:
    """Map Bulao service types to OpenStreetMap tags."""
    craft_map = {
        "plumber": "plumber",
        "electrician": "electrician",
        "ac_technician": "hvac",
        "carpenter": "carpenter",
        "painter": "painter",
        "beautician": "hairdresser",
        "tutor": "teacher",
        "appliance_repair": "electronics_repair",
        "gas_leak_specialist": "gas",
        "geyser_technician": "plumber"
    }
    
    craft_tag = craft_map.get(service_type, "handicraft")
    
    query = f"""
    [out:json][timeout:10];
    (
      node["craft"="{craft_tag}"](around:{radius_m},{lat},{lng});
      node["shop"="{craft_tag}"](around:{radius_m},{lat},{lng});
    );
    out body;
    """
    return query

def _search_live_providers(service_type: str, lat: float, lng: float, radius_m: int = 8000) -> List[Dict]:
    """Search for real businesses via Overpass API."""
    query = _get_overpass_query(service_type, lat, lng, radius_m=radius_m)
    encoded_query = urllib.parse.urlencode({'data': query})
    url = "https://overpass-api.de/api/interpreter"
    
    req = urllib.request.Request(url, data=encoded_query.encode('utf-8'), headers={'User-Agent': 'BulaoHackathon/1.0'})
    
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
            return data.get("elements", [])
    except Exception as e:
        log.error("overpass_search_failure", error=str(e))
        return []

def _synthesize_provider(element: Dict, base_lat: float, base_lng: float, service_type: str, intent: Intent) -> ProviderCandidate:
    """Synthesize Bulao-specific metrics for a real map business."""
    # Real data from map
    name = element.get("tags", {}).get("name") or element.get("tags", {}).get("brand") or f"Local {service_type.replace('_', ' ').title()}"
    p_lat = element.get("lat", base_lat + random.uniform(-0.05, 0.05))
    p_lng = element.get("lon", base_lng + random.uniform(-0.05, 0.05))
    dist = haversine_km(base_lat, base_lng, p_lat, p_lng)
    
    # Synthesized deterministic data based on a hash of the ID or name
    seed = sum(ord(c) for c in str(element.get("id", name)))
    random.seed(seed)
    
    rating = round(random.uniform(4.0, 5.0), 1)
    completed_jobs = random.randint(10, 300)
    on_time_score = round(random.uniform(0.85, 0.99), 2)
    cancellation_rate = round(random.uniform(0.01, 0.1), 2)
    risk_score = round(random.uniform(0.01, 0.15), 2)
    workload = round(random.uniform(0.1, 0.9), 1)
    
    base_fee = random.choice([500, 800, 1000, 1500])
    hourly_rate = random.choice([600, 1000, 1200, 2000])
    
    gender = random.choice(["male", "female"]) if intent.gender_preference == "any" else intent.gender_preference
    exp = random.randint(2, 15)
    
    # Determine slot
    now = datetime.now()
    if workload < 0.4:
        status = "available_now"
        next_slot = (now + timedelta(minutes=45)).isoformat() + "+05:00"
    elif workload < 0.7:
        status = "next_slot_today"
        next_slot = (now + timedelta(hours=3)).isoformat() + "+05:00"
    else:
        status = "tomorrow_or_later"
        next_slot = (now + timedelta(days=1)).replace(hour=10, minute=0, second=0).isoformat() + "+05:00"

    return ProviderCandidate(
        id=f"map_prov_{element.get('id', uuid.uuid4().hex[:8])}",
        name=name,
        service_categories=[service_type],
        specializations=[intent.specialization_hint] if intent.specialization_hint else [],
        distance_km=round(dist, 1),
        neighborhood=intent.location or "Nearby",
        rating=rating,
        completed_jobs_in_area=completed_jobs,
        on_time_score=on_time_score,
        cancellation_rate=cancellation_rate,
        review_recency_days=random.randint(1, 14),
        risk_score=risk_score,
        current_workload=workload,
        availability_status=status,
        next_slot=next_slot,
        base_visit_fee_pkr=base_fee,
        rate_per_hour_pkr=hourly_rate,
        gender=gender,
        years_experience=exp,
        languages=["Urdu", "Punjabi", "English"] if rating > 4.7 else ["Urdu", "Punjabi"],
        verified=True,
        phone_masked="+92 300 " + "".join([str(random.randint(0,9)) for _ in range(7)]),
        alternate_slot_reason=None
    )

async def run(intent: Intent, user_location: Optional[Tuple[float,float]] = None) -> DiscoveryResult:
    """Run real-time discovery via live Maps API."""
    log.info("agent_start", agent="discovery", service=intent.service_type)
    t0 = time.monotonic()
    
    # 1. Resolve Location (Geocoding)
    target_lat, target_lng = None, None
    
    # If the user specified a location in the query (not empty, and not generic/current location)
    if intent.location and intent.location.strip().lower() not in ["", "nearby", "here", "current location", "my location", "islamabad"]:
        coords = _geocode_location(intent.location, intent.city or "Islamabad")
        if coords:
            target_lat, target_lng = coords
            log.info("discovery_used_query_location", location=intent.location, lat=target_lat, lng=target_lng)
            
    # If no query location was found/geocoded, fallback to the user's GPS coordinates
    if target_lat is None or target_lng is None:
        if user_location and user_location[0] is not None and user_location[1] is not None:
            target_lat, target_lng = user_location
            log.info("discovery_used_gps_location", lat=target_lat, lng=target_lng)
            
    # If both query location and GPS fail, fallback to Islamabad center
    if target_lat is None or target_lng is None:
        target_lat, target_lng = 33.6844, 73.0479
        log.info("discovery_fallback_islamabad", lat=target_lat, lng=target_lng)

    # 2. Search Live Maps with Expanding Radius
    radii_km = [2, 5, 15, 30] # Colony, District, City, Greater Area
    elements = []
    for r in radii_km:
        elements = _search_live_providers(intent.service_type, target_lat, target_lng, radius_m=r * 1000)
        if len(elements) > 0:
            log.info("providers_found_in_radius", radius_km=r, count=len(elements))
            break
            
    # 4. Map to Platform Candidates
    candidates = []
    for el in elements:
        cand = _synthesize_provider(el, target_lat, target_lng, intent.service_type, intent)
        
        # Apply strict complexity filter
        if intent.job_complexity == "complex" and cand.years_experience < 5:
            continue
        if intent.job_complexity == "intermediate" and cand.years_experience < 2:
            continue
            
        candidates.append(cand)
        
    # 5. Sort by distance
    candidates.sort(key=lambda x: x.distance_km)
    
    # Separate into matches and alternates based on time
    matches = []
    alternates = []
    
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
        target_start = now
        target_end = now + timedelta(days=7)
        
    for c in candidates:
        slot = datetime.fromisoformat(c.next_slot.replace('Z', '+00:00')).replace(tzinfo=None)
        if target_start - timedelta(minutes=30) <= slot <= target_end + timedelta(minutes=30) or intent.time_window == "flexible":
            matches.append(c)
        else:
            c.alternate_slot_reason = f"Earliest available is at {c.next_slot}"
            alternates.append(c)
            
    # Top 8 matches
    matches = matches[:8]
    if len(matches) < 3:
        alternates = alternates[:5]
    else:
        alternates = []
        
    reason = "No available providers matched your exact time window." if not matches and alternates else None

    result = DiscoveryResult(candidates=matches, alternates=alternates, no_match_reason=reason)
    log.info("agent_end", agent="discovery", duration_ms=int((time.monotonic()-t0)*1000), n_candidates=len(matches), n_alternates=len(alternates))
    return result
