import json
import math
import time
import urllib.request
import urllib.parse
from datetime import datetime, timedelta
from typing import Optional, Tuple, List, Dict
import random
import uuid
from pathlib import Path

import structlog
from app.models import Intent, ProviderCandidate, DiscoveryResult
from app.config import settings

log = structlog.get_logger()

# Global list of local providers (loaded at boot)
_PROVIDERS = []

def _load_local_providers():
    global _PROVIDERS
    try:
        base_dir = Path(__file__).parent.parent
        providers_path = base_dir / "data" / "providers.json"
        if providers_path.exists():
            with open(providers_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                _PROVIDERS = data
                log.info("loaded_local_providers_successfully", count=len(_PROVIDERS))
    except Exception as e:
        log.error("failed_to_load_local_providers", error=str(e))

# Initial load
_load_local_providers()

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

# Google Places query strings for each service type
# These match what a real user would type into Google Maps in Pakistan
_GOOGLE_PLACES_QUERIES = {
    "plumber":           "plumber",
    "electrician":       "electrician",
    "ac_technician":     "AC repair technician",
    "geyser_technician": "geyser repair technician",
    "carpenter":         "carpenter woodwork",
    "painter":           "house painter",
    "beautician":        "beauty salon beautician",
    "tutor":             "home tutor teacher",
    "appliance_repair":  "home appliance repair",
    "gas_leak_specialist": "gas pipeline repair",
}

def _search_google_places(service_type: str, lat: float, lng: float,
                           city: str = "Rawalpindi", radius_m: int = 20000,
                           raw_query: str = None) -> List[Dict]:
    """
    Search real businesses using Google Places Text Search API.
    Returns the same results the user sees in Google Maps.

    If raw_query is provided (e.g. "mechanic"), it's used directly as the search term
    instead of the mapped keyword — so ANY service the user asks for works without
    needing a manual keyword mapping.
    """
    api_key = settings.GOOGLE_MAPS_API_KEY.strip()
    if not api_key:
        return []

    if raw_query:
        # User said something unrecognized — use their exact words for the search
        # "mechanic chahie Rawalpindi" → "mechanic chahie Rawalpindi in Rawalpindi"
        # Google Places handles Urdu/mixed queries well
        query = f"{raw_query} in {city}"
    else:
        keyword = _GOOGLE_PLACES_QUERIES.get(service_type, service_type.replace("_", " "))
        query = f"{keyword} in {city}"

    params = urllib.parse.urlencode({
        "query": query,
        "location": f"{lat},{lng}",
        "radius": radius_m,
        "key": api_key,
    })
    url = f"https://maps.googleapis.com/maps/api/place/textsearch/json?{params}"
    req = urllib.request.Request(url, headers={"User-Agent": "BulaoHackathon/1.0"})

    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode("utf-8"))
            status = data.get("status", "")
            results = data.get("results", [])

            if status == "OK":
                log.info("google_places_success", query=query, count=len(results))
                return results
            elif status == "ZERO_RESULTS":
                log.info("google_places_zero_results", query=query)
                return []
            else:
                log.warning("google_places_api_error", status=status, query=query)
                return []
    except Exception as e:
        log.error("google_places_failure", error=str(e), query=query)
        return []


def _synthesize_from_google_place(place: Dict, base_lat: float, base_lng: float,
                                   service_type: str, intent: Intent) -> ProviderCandidate:
    """Convert a Google Places result into a Bulao ProviderCandidate.
    
    Real fields used: name, geometry (lat/lng), rating, user_ratings_total,
                      formatted_address, business_status, opening_hours.
    Operational fields (workload, experience, etc.) are deterministically
    synthesized from the place_id seed so they're stable across requests.
    """
    place_id = place.get("place_id", "unknown")
    name = place.get("name", f"Local {service_type.replace('_', ' ').title()}")
    geometry = place.get("geometry", {}).get("location", {})
    p_lat = geometry.get("lat", base_lat)
    p_lng = geometry.get("lng", base_lng)
    dist = haversine_km(base_lat, base_lng, p_lat, p_lng)

    # Real rating from Google (or default if not rated yet)
    google_rating = place.get("rating", 4.2)
    rating = round(min(5.0, max(1.0, google_rating)), 1)
    review_count = place.get("user_ratings_total", 0)

    # Address for neighborhood field
    address = place.get("formatted_address", place.get("vicinity", ""))
    # Extract neighborhood-level part (first segment before comma)
    neighborhood = address.split(",")[0].strip() if address else "Nearby"

    # Deterministic synthetic operational metrics seeded by place_id
    # (stable across requests — same place always gets same metrics)
    seed = sum(ord(c) for c in place_id)
    rng = random.Random(seed)

    completed_jobs = review_count if review_count > 0 else rng.randint(20, 150)
    on_time_score = round(rng.uniform(0.80, 0.99), 2)
    cancellation_rate = round(rng.uniform(0.01, 0.12), 2)
    risk_score = round(rng.uniform(0.01, 0.20), 2)
    workload = round(rng.uniform(0.1, 0.85), 1)
    years_exp = rng.randint(2, 20)
    base_fee = rng.choice([500, 700, 800, 1000, 1200])
    rate_per_hr = rng.choice([800, 1000, 1200, 1500, 2000])

    # Slot generation
    now = datetime.now()
    is_open = place.get("opening_hours", {}).get("open_now", True)
    if is_open:
        availability = "available_now"
        next_slot = now.isoformat() + "+05:00"
    else:
        availability = "next_slot_today"
        next_slot = (now + timedelta(hours=rng.randint(1, 6))).isoformat() + "+05:00"

    # Gender — unknown from Google, default male (most service workers in PK)
    gender = "male"

    return ProviderCandidate(
        id=f"gplace_{place_id[:12]}",
        name=name,
        service_categories=[service_type],
        specializations=[],
        distance_km=round(dist, 2),
        neighborhood=neighborhood,
        rating=rating,
        completed_jobs_in_area=completed_jobs,
        on_time_score=on_time_score,
        cancellation_rate=cancellation_rate,
        review_recency_days=rng.randint(1, 30),
        risk_score=risk_score,
        current_workload=workload,
        availability_status=availability,
        next_slot=next_slot,
        base_visit_fee_pkr=base_fee,
        rate_per_hour_pkr=rate_per_hr,
        gender=gender,
        years_experience=years_exp,
        languages=["urdu", "punjabi"],
        verified=True,
        phone_masked="+92 3XX XXXXXXX",  # Real phone requires Place Details API call
        lat=p_lat,
        lng=p_lng,
    )


# Overpass fallback (OSM) — kept for when Google Places key is not set
_OVERPASS_MIRRORS = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
    "https://maps.mail.ru/osm/tools/overpass/api/interpreter",
]

def _get_overpass_query(service_type: str, lat: float, lng: float, radius_m: int = 30000) -> str:
    craft_map = {
        "plumber": "plumber", "electrician": "electrician", "ac_technician": "hvac",
        "carpenter": "carpenter", "painter": "painter", "beautician": "hairdresser",
        "tutor": "teacher", "appliance_repair": "electronics_repair",
        "gas_leak_specialist": "gas", "geyser_technician": "plumber",
    }
    craft_tag = craft_map.get(service_type, "handicraft")
    return f"""
    [out:json][timeout:8];
    (node["craft"="{craft_tag}"](around:{radius_m},{lat},{lng});
     node["shop"="{craft_tag}"](around:{radius_m},{lat},{lng}););
    out body;
    """

def _search_overpass(service_type: str, lat: float, lng: float, radius_m: int = 30000) -> List[Dict]:
    """Overpass/OSM fallback — only used when Google Places key is not configured."""
    query = _get_overpass_query(service_type, lat, lng, radius_m=radius_m)
    encoded = urllib.parse.urlencode({"data": query})
    for mirror in _OVERPASS_MIRRORS:
        req = urllib.request.Request(mirror, data=encoded.encode(), headers={"User-Agent": "BulaoHackathon/1.0"})
        try:
            with urllib.request.urlopen(req, timeout=3) as r:
                data = json.loads(r.read().decode())
                elements = data.get("elements", [])
                if elements:
                    log.info("overpass_success", mirror=mirror, count=len(elements))
                return elements
        except Exception as e:
            log.warning("overpass_mirror_failure", mirror=mirror, error=str(e)[:80])
    log.error("overpass_all_mirrors_failed", service=service_type)
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

    phone_masked = "+92 300 XXX " + "".join([str(random.randint(0,9)) for _ in range(4)])

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
        phone_masked=phone_masked,
        lat=p_lat,
        lng=p_lng,
        alternate_slot_reason=None
    )

def _synthesize_local_provider(p: Dict, dist: float, intent: Intent) -> ProviderCandidate:
    """Map a local JSON provider dictionary to a ProviderCandidate model."""
    workload = p.get("current_workload", 0.5)
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

    raw_phone = p.get("phone") or p.get("phone_masked") or "+923331234567"
    if len(raw_phone) >= 10:
        phone_masked = raw_phone[:6] + "XXX" + raw_phone[9:]
    else:
        phone_masked = raw_phone + "XXX"

    completed_jobs = p.get("completed_jobs") or p.get("completed_jobs_in_area") or 50

    return ProviderCandidate(
        id=p.get("id") or f"prov_{uuid.uuid4().hex[:8]}",
        name=p.get("name", "Local Specialist"),
        service_categories=p.get("service_categories", [intent.service_type]),
        specializations=p.get("specializations", []),
        distance_km=round(dist, 1),
        neighborhood=p.get("neighborhood") or intent.location or "Nearby",
        rating=p.get("rating", 4.5),
        completed_jobs_in_area=completed_jobs,
        on_time_score=p.get("on_time_score", 0.90),
        cancellation_rate=p.get("cancellation_rate", 0.05),
        review_recency_days=p.get("review_recency_days", 5),
        risk_score=p.get("risk_score", 0.05),
        current_workload=workload,
        availability_status=p.get("availability_status") or status,
        next_slot=p.get("next_slot") or next_slot,
        base_visit_fee_pkr=p.get("base_visit_fee_pkr", 500),
        rate_per_hour_pkr=p.get("rate_per_hour_pkr", 1000),
        gender=p.get("gender") or "male",
        years_experience=p.get("years_experience", 5),
        languages=p.get("languages", ["Urdu"]),
        verified=p.get("verified", True),
        phone_masked=phone_masked,
        lat=p.get("lat"),
        lng=p.get("lng"),
        alternate_slot_reason=None
    )

async def run(intent: Intent, user_location: Optional[Tuple[float,float]] = None) -> DiscoveryResult:
    """Run location-aware discovery with expanding radius search on local/live candidates."""
    log.info("agent_start", agent="discovery", service=intent.service_type)
    t0 = time.monotonic()
    
    # 1. Resolve Location (Geocoding / GPS Priority)
    target_lat, target_lng = None, None
    
    # If the user specified a location in the query (not generic/empty)
    if intent.location and intent.location.strip().lower() not in ["", "nearby", "here", "current location", "my location", "islamabad"]:
        # Try neighborhoods cache first
        try:
            nb_path = Path(__file__).parent.parent / "data" / "neighborhoods.json"
            if nb_path.exists():
                with open(nb_path, "r", encoding="utf-8") as f:
                    nb_data = json.load(f)
                    match_key = next((k for k in nb_data if k.strip().lower() == intent.location.strip().lower()), None)
                    if match_key:
                        target_lat = nb_data[match_key]["lat"]
                        target_lng = nb_data[match_key]["lng"]
                        log.info("discovery_used_neighborhood_cache", location=intent.location, lat=target_lat, lng=target_lng)
        except Exception as e:
            log.error("neighborhoods_cache_error", error=str(e))
            
        if target_lat is None:
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

    raw_candidates = []
    city_label = intent.city or "Islamabad"

    # ── Tier 1: Google Places API (real Google Maps results) ──────────────────
    # Same businesses the user sees when searching on Google Maps.
    # If specialization_hint is set (user said something unrecognized like "mechanic"),
    # use it directly as the Google Places query instead of a mapped keyword.
    google_results = _search_google_places(
        intent.service_type, target_lat, target_lng,
        city=city_label, radius_m=20000,
        raw_query=intent.specialization_hint  # None for known services, raw text for unknown
    )
    if google_results:
        log.info("google_places_used", count=len(google_results), city=city_label)
        for place in google_results:
            cand = _synthesize_from_google_place(place, target_lat, target_lng, intent.service_type, intent)
            raw_candidates.append(cand)

    # ── Tier 2: Overpass / OpenStreetMap (no Google key configured) ───────────
    if not raw_candidates:
        osm_elements = _search_overpass(intent.service_type, target_lat, target_lng, radius_m=30000)
        if osm_elements:
            log.info("overpass_used", count=len(osm_elements))
            for el in osm_elements:
                cand = _synthesize_provider(el, target_lat, target_lng, intent.service_type, intent)
                raw_candidates.append(cand)

    # ── Tier 3: Local providers.json emergency fallback ───────────────────────
    # Only used when ALL live APIs fail (network issues, no keys set, etc.)
    if not raw_candidates and _PROVIDERS:
        log.warning("all_live_apis_failed_using_local_fallback",
                    service=intent.service_type, lat=target_lat, lng=target_lng)
        local_candidates = []
        for p in _PROVIDERS:
            if intent.service_type in p.get("service_categories", []):
                p_lat = p.get("lat")
                p_lng = p.get("lng")
                if p_lat is not None and p_lng is not None:
                    dist = haversine_km(target_lat, target_lng, p_lat, p_lng)
                    local_candidates.append((p, dist))

        matches = sorted([(p, d) for p, d in local_candidates if d <= 30], key=lambda x: x[1])
        if matches:
            log.info("local_fallback_providers_found", count=len(matches))
            for p, dist in matches:
                raw_candidates.append(_synthesize_local_provider(p, dist, intent))

    # 4. Filters & Post-processing
    candidates = []
    for cand in raw_candidates:
        # Apply gender preference filter
        if intent.gender_preference != "any" and cand.gender != intent.gender_preference:
            continue
            
        # Apply complexity filters
        if intent.job_complexity == "complex" and cand.years_experience < 5:
            continue
        if intent.job_complexity == "intermediate" and cand.years_experience < 2:
            continue
            
        candidates.append(cand)
        
    # Sort by distance
    candidates.sort(key=lambda x: x.distance_km)
    
    # Separate into matches and alternates based on time window
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
        
    reason = None
    if not matches:
        if alternates:
            # Promote alternates to matches so the user actually has candidates to select from!
            log.info("discovery_promoting_alternates_to_matches", count=len(alternates))
            matches = alternates
            alternates = []
        else:
            reason = "No candidates found matching your criteria."

    result = DiscoveryResult(candidates=matches, alternates=alternates, no_match_reason=reason)
    log.info("agent_end", agent="discovery", duration_ms=int((time.monotonic()-t0)*1000), n_candidates=len(matches), n_alternates=len(alternates))
    return result

