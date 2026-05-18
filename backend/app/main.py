from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import structlog
from contextlib import asynccontextmanager
from app.routers import orchestrate, book, dispute, health, rating, lifecycle, followup_trigger, services
from app.config import settings

# Setup logging
structlog.configure(
    processors=[
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ]
)
log = structlog.get_logger()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    log.info("startup", service="bulao-backend", version="1.0.0", env="production" if not settings.DEMO_MODE else "demo")
    yield
    # Shutdown
    log.info("shutdown")

app = FastAPI(
    title="Bulao Backend",
    version="1.0.0",
    lifespan=lifespan
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(health.router)
app.include_router(orchestrate.router, prefix="/api")
app.include_router(book.router)
app.include_router(dispute.router)
app.include_router(rating.router)
app.include_router(lifecycle.router)
app.include_router(followup_trigger.router)
app.include_router(services.router)

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    log.error("unhandled_exception", error=str(exc))
    return {"error": "internal_server_error", "message": str(exc)}, 500
