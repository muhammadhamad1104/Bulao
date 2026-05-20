"""
Smart LLM ranking result cache.

Purpose:
  Avoid redundant LLM ranking calls when multiple users request the exact same
  service type in the same geographic area within a short time window.

What we cache:
  - ONLY the LLM ranking result (recommended provider ID + scores)
  - Keyed by: service_type + geographic grid cell (0.02-degree lat/lng bucket ≈ 2km)
  - TTL: 5 minutes — short enough to stay fresh, long enough to de-duplicate
    burst traffic in the same area

What we do NOT cache:
  - Discovery results (these are real-time and user-location-specific)
  - Pricing (always freshly calculated per provider per user)
  - Booking/confirmation (always unique)
"""
import json
import time
import math
from typing import Optional
import structlog
from app.models import RankingResult

log = structlog.get_logger()

# In-memory cache (no disk I/O overhead for a 5-minute TTL)
_RANKING_CACHE: dict = {}

# Geographic bucket size: 0.02 degrees ≈ ~2km cells
_GEO_BUCKET = 0.02

# Cache TTL: 5 minutes
_TTL_SECONDS = 5 * 60


def _geo_key(lat: Optional[float], lng: Optional[float]) -> str:
    """Snap a coordinate to a 2km grid cell to group nearby requests."""
    if lat is None or lng is None:
        return "unknown"
    bucket_lat = math.floor(lat / _GEO_BUCKET) * _GEO_BUCKET
    bucket_lng = math.floor(lng / _GEO_BUCKET) * _GEO_BUCKET
    return f"{bucket_lat:.4f}_{bucket_lng:.4f}"


def _generate_key(service_type: str, lat: Optional[float], lng: Optional[float]) -> str:
    """Generate a cache key from service type and geographic bucket."""
    return f"rank_{service_type}_{_geo_key(lat, lng)}"


def get_cached_ranking(
    service_type: str,
    lat: Optional[float],
    lng: Optional[float]
) -> Optional[RankingResult]:
    """
    Retrieve a cached LLM ranking result if fresh (within TTL).
    Returns None on cache miss or expiry.
    """
    key = _generate_key(service_type, lat, lng)
    entry = _RANKING_CACHE.get(key)

    if not entry:
        log.info("ranking_cache_miss", cache_key=key)
        return None

    age = time.time() - entry["timestamp"]
    if age > _TTL_SECONDS:
        # Evict expired entry
        del _RANKING_CACHE[key]
        log.info("ranking_cache_expired", cache_key=key, age_seconds=int(age))
        return None

    log.info("ranking_cache_hit", cache_key=key, age_seconds=int(age))
    return entry["ranking"]


def save_ranking(
    service_type: str,
    lat: Optional[float],
    lng: Optional[float],
    ranking: RankingResult
) -> None:
    """
    Save an LLM ranking result to the in-memory cache.
    Only stores the recommended provider ID and scores — not full provider objects.
    """
    key = _generate_key(service_type, lat, lng)
    _RANKING_CACHE[key] = {
        "ranking": ranking,
        "timestamp": time.time()
    }
    log.info("ranking_cache_saved", cache_key=key, ttl_seconds=_TTL_SECONDS)


def evict_expired() -> int:
    """Remove all expired entries. Returns the number evicted."""
    now = time.time()
    expired_keys = [k for k, v in _RANKING_CACHE.items() if now - v["timestamp"] > _TTL_SECONDS]
    for k in expired_keys:
        del _RANKING_CACHE[k]
    return len(expired_keys)
