from fastapi import APIRouter

router = APIRouter(tags=["System"])

@router.get("/health")
async def health():
    return {
        "status": "ok",
        "version": "0.1.0",
        "commit": "local"
    }
