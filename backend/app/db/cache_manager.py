import sqlite3
import json
import time
from pathlib import Path
from typing import Optional, Tuple
import structlog
from app.models import DiscoveryResult, RankingResult

log = structlog.get_logger()

# Store database in the data directory
_DB_PATH = Path(__file__).parent.parent / "data" / "bulao_cache.db"

def _get_connection():
    # Ensure data directory exists
    _DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    
    conn = sqlite3.connect(_DB_PATH)
    # Initialize table if it doesn't exist
    conn.execute("""
        CREATE TABLE IF NOT EXISTS agent_cache (
            cache_key TEXT PRIMARY KEY,
            discovery_json TEXT,
            ranking_json TEXT,
            timestamp REAL
        )
    """)
    conn.commit()
    return conn

def _generate_key(service_type: str, location: Optional[str], city: str) -> str:
    loc_part = location.strip().lower() if location else "none"
    city_part = city.strip().lower() if city else "none"
    return f"{service_type}_{loc_part}_{city_part}"

def get_cached_results(service_type: str, location: Optional[str], city: str, max_age_hours: int = 48) -> Tuple[Optional[DiscoveryResult], Optional[RankingResult]]:
    """Retrieve unexpired results from the SQLite cache."""
    key = _generate_key(service_type, location, city)
    try:
        with _get_connection() as conn:
            cursor = conn.execute("SELECT discovery_json, ranking_json, timestamp FROM agent_cache WHERE cache_key = ?", (key,))
            row = cursor.fetchone()
            
            if row:
                discovery_json, ranking_json, timestamp = row
                
                # Check expiration
                if (time.time() - timestamp) > (max_age_hours * 3600):
                    log.info("cache_expired", cache_key=key, age_hours=int((time.time() - timestamp) / 3600))
                    return None, None
                    
                log.info("cache_hit", cache_key=key)
                
                # Deserialize
                discovery = DiscoveryResult.model_validate_json(discovery_json) if discovery_json else None
                ranking = RankingResult.model_validate_json(ranking_json) if ranking_json else None
                
                return discovery, ranking
                
    except Exception as e:
        log.error("cache_read_failure", error=str(e), cache_key=key)
        
    log.info("cache_miss", cache_key=key)
    return None, None

def save_results(service_type: str, location: Optional[str], city: str, discovery: DiscoveryResult, ranking: RankingResult) -> None:
    """Save discovery and ranking results to the SQLite cache."""
    key = _generate_key(service_type, location, city)
    try:
        with _get_connection() as conn:
            discovery_json = discovery.model_dump_json() if discovery else None
            ranking_json = ranking.model_dump_json() if ranking else None
            
            conn.execute("""
                INSERT OR REPLACE INTO agent_cache (cache_key, discovery_json, ranking_json, timestamp)
                VALUES (?, ?, ?, ?)
            """, (key, discovery_json, ranking_json, time.time()))
            conn.commit()
            log.info("cache_saved", cache_key=key)
    except Exception as e:
        log.error("cache_save_failure", error=str(e), cache_key=key)
