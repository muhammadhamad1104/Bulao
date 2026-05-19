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

log = structlog.get_logger()

# Global LLM instance (loaded once into memory when the app boots)
_llm = None

def _get_llm():
    global _llm
    if _llm is None:
        try:
            from llama_cpp import Llama
            
            # Docker path or local fallback path
            model_path = "/app/models/qwen.gguf"
            if not os.path.exists(model_path):
                # Fallback for local PC execution outside Docker
                local_path = Path(__file__).parent.parent.parent / "models" / "qwen.gguf"
                model_path = str(local_path)
                
            if not os.path.exists(model_path):
                log.warning("local_model_not_found", path=model_path)
                return None
                
            log.info("loading_local_llm_into_memory", path=model_path)
            # n_ctx=2048 is plenty for our tasks, keeping RAM usage low
            _llm = Llama(model_path=model_path, n_ctx=2048, verbose=False)
            log.info("local_llm_loaded_successfully")
        except ImportError:
            log.error("llama_cpp_python_not_installed")
        except Exception as e:
            log.error("llm_initialization_failure", error=str(e))
            
    return _llm

def preload_model():
    """Pre-load the model into memory."""
    _get_llm()

def get_client():
    """
    Returns None since we no longer use a google/groq client object.
    The agents will pass None, and safe_generate handles the rest.
    """
    return None

async def safe_generate(
    client,  # Ignored now
    model: str, # Ignored now
    contents: str,
    config: dict,
    max_retries: int = 1, # Local models don't have rate limits, so no retries needed
    agent_name: str = "unknown",
) -> Optional[str]:
    """
    Generate content using the bundled local GGUF model.
    Guarantees strict JSON output if requested.
    """
    system_instruction = config.get("system_instruction", "")
    
    llm = _get_llm()
    if not llm:
        log.warning("bundled_llm_unavailable", agent=agent_name)
        return None
        
    messages = []
    if system_instruction:
        messages.append({"role": "system", "content": system_instruction})
    messages.append({"role": "user", "content": contents})

    # Determine if JSON format is required
    response_format = None
    if config.get("response_mime_type") == "application/json":
        response_format = {"type": "json_object"}

    t0 = time.monotonic()
    log.info("local_llm_start", agent=agent_name, prompt_length=len(contents))
    
    try:
        # llama_cpp inference (blocking, so we MUST offload to threadpool to prevent health check timeouts)
        response = await asyncio.to_thread(
            llm.create_chat_completion,
            messages=messages,
            temperature=config.get("temperature", 0.1),
            response_format=response_format,
            max_tokens=250  # Reduced to speed up generation
        )
        
        result_text = response['choices'][0]['message']['content']
        duration = int((time.monotonic() - t0) * 1000)
        
        log.info("local_llm_success", agent=agent_name, duration_ms=duration, output_length=len(result_text))
        return result_text
        
    except Exception as e:
        log.error("local_llm_failure", agent=agent_name, error=str(e))
        return None
