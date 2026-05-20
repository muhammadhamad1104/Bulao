"""
100% Self-Hosted Local LLM Client using llama-cpp-python.
Zero external API calls. Runs locally in the Docker container.
"""
import os
import time
import json
import asyncio
import structlog
from typing import Optional
from pathlib import Path
from app.config import settings

log = structlog.get_logger()

# Global client helper
_INVALID_KEYS = {"", "paste-your-key-here", "fake", "your_gemini_api_key_here"}

def get_client():
    """Return a google-genai Client if a valid API key is set, else None."""
    try:
        from google.genai import Client
        key = settings.GEMINI_API_KEY.strip() or settings.API_KEY.strip()
        if key and key not in _INVALID_KEYS:
            return Client(api_key=key)
    except Exception as e:
        log.warning("google_genai_import_or_client_failed", error=str(e))
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
    Generate content. Prioritizes the cloud APIs (DigitalOcean GenAI / Google Gemini)
    if an API key is present, otherwise falls back to the self-hosted local model.
    """
    system_instruction = config.get("system_instruction", "")
    key = settings.GEMINI_API_KEY.strip() or settings.API_KEY.strip()
    
    # --- 1. Cloud DigitalOcean or Google Gemini API Path ---
    if key and key not in _INVALID_KEYS:
        t0 = time.monotonic()
        
        # A. Route via DigitalOcean Serverless GenAI Platform if base URL is configured and NOT a Gemini API key
        is_gemini_key = key.startswith("AIzaSy")
        
        if settings.DIGITALOCEAN_BASE_URL and not is_gemini_key:
            do_model = settings.DIGITALOCEAN_MODEL
            log.info("cloud_digitalocean_start", agent=agent_name, model=do_model)
            
            headers = {
                "Authorization": f"Bearer {key}",
                "Content-Type": "application/json"
            }
            
            messages = []
            if system_instruction:
                messages.append({"role": "system", "content": system_instruction})
            messages.append({"role": "user", "content": contents})
            
            payload = {
                "model": do_model,
                "messages": messages,
                "temperature": config.get("temperature", 0.1),
            }
            
            if config.get("response_mime_type") == "application/json":
                payload["response_format"] = {"type": "json_object"}
                
            import httpx
            
            do_success = False
            for attempt in range(max_retries):
                try:
                    async with httpx.AsyncClient() as http_client:
                        response = await http_client.post(
                            f"{settings.DIGITALOCEAN_BASE_URL}/chat/completions",
                            json=payload,
                            headers=headers,
                            timeout=30.0
                        )
                        
                        if response.status_code == 200:
                            data = response.json()
                            result_text = data["choices"][0]["message"]["content"]
                            duration = int((time.monotonic() - t0) * 1000)
                            log.info("cloud_digitalocean_success", agent=agent_name, duration_ms=duration)
                            return result_text
                        
                        log.warning(
                            "cloud_digitalocean_status_error",
                            status_code=response.status_code,
                            response_text=response.text[:200]
                        )
                        
                        if response.status_code == 429 and attempt < max_retries - 1:
                            wait = 2 ** attempt
                            await asyncio.sleep(wait)
                            continue
                        # 403 = permanent auth failure — no point retrying
                        break
                except Exception as e:
                    log.error("cloud_digitalocean_exception", agent=agent_name, attempt=attempt + 1, error=str(e))
                    if attempt < max_retries - 1:
                        await asyncio.sleep(2 ** attempt)
                        continue
                    break
                    
        # B. Fallback to direct Google Gemini API — only if this IS a Gemini key.
        # A DigitalOcean/other key will always get 400 INVALID_ARGUMENT from Gemini, so don't try.
        if client and is_gemini_key:
            gemini_model = "gemini-1.5-flash" if "flash" in model else "gemini-1.5-flash"
            log.info("cloud_gemini_start", agent=agent_name, model=gemini_model)
            
            for attempt in range(max_retries):
                try:
                    # offload blocking SDK call to threadpool to keep FastAPI responsive
                    response = await asyncio.to_thread(
                        client.models.generate_content,
                        model=gemini_model,
                        contents=contents,
                        config=config
                    )
                    duration = int((time.monotonic() - t0) * 1000)
                    log.info("cloud_gemini_success", agent=agent_name, duration_ms=duration)
                    return response.text
                except Exception as e:
                    err_str = str(e)
                    is_quota = "429" in err_str or "RESOURCE_EXHAUSTED" in err_str or "quota" in err_str.lower()
                    
                    if is_quota and attempt < max_retries - 1:
                        wait = 2 ** attempt
                        log.warning("cloud_gemini_quota_retry", agent=agent_name, attempt=attempt + 1, wait_s=wait)
                        await asyncio.sleep(wait)
                        continue
                        
                    log.error("cloud_gemini_failure", agent=agent_name, attempt=attempt + 1, error=err_str[:200])
                    break # Fall back to local LLM path

    # --- 2. Deterministic Fallback Path ---
    log.warning("llm_unavailable_using_keyword_fallback", agent=agent_name)
    return None
