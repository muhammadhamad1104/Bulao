"""
Shared LLM client utility with exponential backoff retry for 429/quota errors.
All agents should use safe_generate() instead of calling client directly.
"""
import asyncio
import time
import structlog
from typing import Optional
from app.config import settings

log = structlog.get_logger()

_INVALID_KEYS = {"", "paste-your-key-here", "fake", "your_gemini_api_key_here"}

def get_client():
    """Return a google-genai Client if a valid API key is set, else None."""
    from google.genai import Client
    key = settings.GEMINI_API_KEY.strip()
    if key and key not in _INVALID_KEYS:
        return Client(api_key=key)
    return None

async def safe_generate(
    client,
    model: str,
    contents: str,
    config: dict,
    max_retries: int = 3,
    agent_name: str = "unknown",
) -> Optional[str]:
    """
    Call client.models.generate_content with exponential backoff on 429 errors.
    Returns response.text on success, None on final failure.
    """
    for attempt in range(max_retries):
        try:
            response = client.models.generate_content(
                model=model,
                contents=contents,
                config=config,
            )
            return response.text
        except Exception as e:
            err_str = str(e)
            is_quota = "429" in err_str or "RESOURCE_EXHAUSTED" in err_str or "quota" in err_str.lower()
            
            if is_quota and attempt < max_retries - 1:
                wait = 2 ** attempt  # 1s, 2s, 4s
                log.warning(
                    "llm_quota_retry",
                    agent=agent_name,
                    attempt=attempt + 1,
                    wait_s=wait,
                    error=err_str[:120],
                )
                await asyncio.sleep(wait)
                continue
            
            # Non-retriable error or final attempt
            log.error(
                "llm_failure",
                agent=agent_name,
                attempt=attempt + 1,
                error=err_str[:200],
                is_quota=is_quota,
            )
            return None

    return None
