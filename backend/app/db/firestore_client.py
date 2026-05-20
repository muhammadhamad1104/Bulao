from google.cloud import firestore
import structlog
from app.config import settings

log = structlog.get_logger()

# Async Client for Firestore (lazy init for tests)
_db = None

def get_db():
    global _db
    if _db is None:
        try:
            _db = firestore.AsyncClient(project=settings.GOOGLE_CLOUD_PROJECT)
        except Exception:
            log.warn("db_init_skipped", reason="no_credentials")
            _db = None
    return _db

async def save_booking(booking: dict) -> None:
    """Save or update a booking record in Firestore."""
    db = get_db()
    if not db:
        log.warn("db_save_skipped_no_db", id=booking.get("booking_id"))
        return
    try:
        await db.collection("bookings").document(booking["booking_id"]).set(booking)
        log.info("db_save_success", collection="bookings", id=booking["booking_id"])
    except Exception as e:
        log.error("db_save_failure", collection="bookings", id=booking.get("booking_id"), error=str(e))
        raise

async def get_booking(booking_id: str) -> dict | None:
    """Retrieve a booking record from Firestore."""
    db = get_db()
    if not db:
        return None
    try:
        doc = await db.collection("bookings").document(booking_id).get()
        if doc.exists:
            return doc.to_dict()
        return None
    except Exception as e:
        log.error("db_get_failure", collection="bookings", id=booking_id, error=str(e))
        return None

async def update_lifecycle(booking_id: str, status: str, timestamp_field: str, timestamp_val: str) -> None:
    """Update booking status and lifecycle timestamp."""
    db = get_db()
    if not db:
        return
    try:
        await db.collection("bookings").document(booking_id).update({
            "status": status,
            f"lifecycle.{timestamp_field}": timestamp_val
        })
        log.info("db_update_lifecycle", id=booking_id, status=status)
    except Exception as e:
        log.error("db_update_failure", id=booking_id, error=str(e))
        raise

async def get_user_bookings(user_id: str) -> list[dict]:
    """Retrieve all booking records for a given user from Firestore."""
    db = get_db()
    if not db:
        return []
    try:
        docs = db.collection("bookings").where("user_id", "==", user_id).stream()
        results = []
        async for doc in docs:
            results.append(doc.to_dict())
        # Sort by creation time / ID descending so new bookings show at top
        results.sort(key=lambda x: x.get("booking_id", ""), reverse=True)
        return results
    except Exception as e:
        log.error("db_list_failure", collection="bookings", user_id=user_id, error=str(e))
        return []

