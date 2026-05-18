from fastapi import APIRouter

router = APIRouter(tags=["Services"])

@router.get("/services")
async def get_services():
    """
    Returns the list of available services in the exact order for the UI.
    """
    return {
        "services": [
            "Plumbing",
            "Electrical",
            "Painting",
            "HVAC",
            "Locksmith",
            "Carpentry"
        ]
    }
