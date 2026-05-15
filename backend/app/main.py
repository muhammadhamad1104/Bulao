from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import structlog
from app.config import settings
from app.models import OrchestrateRequest
from app import orchestrator

log = structlog.get_logger()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Init logger + ADK client at startup
    structlog.configure(
        processors=[
            structlog.stdlib.add_log_level,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.JSONRenderer()
        ]
    )
    log.bind(service="bulao-backend", env=settings.GOOGLE_CLOUD_PROJECT)
    log.info("Starting Bulao Backend")
    yield
    log.info("Shutting down Bulao Backend")

app = FastAPI(title="Bulao Backend", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    log.error("Unhandled exception", error=str(exc))
    return JSONResponse(
        status_code=500,
        content={"error": str(exc), "code": 500},
    )

@app.get("/health")
async def health():
    return {"status": "ok", "version": "1.0.0", "commit": "local"}

@app.post("/orchestrate")
async def orchestrate(req: OrchestrateRequest):
    try:
        return await orchestrator.run_pipeline(req)
    except Exception as e:
        log.error("Orchestration failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/book")
async def book():
    # Stub for Day 3; returns 501 Not Implemented for now
    raise HTTPException(status_code=501, detail="Not Implemented")
