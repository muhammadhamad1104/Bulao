# Schema version: 1.0 — FROZEN as of Day 4. Coordinate with Backend Workflows before changing.

from pydantic import BaseModel
from typing import Literal, Optional, Tuple, List, Dict

# Schema version: 1.0 — FROZEN as of Day 4. Coordinate with Backend Workflows before changing.

class Intent(BaseModel):
    service_type: Literal["plumber","electrician","ac_technician","geyser_technician","carpenter","painter","beautician","tutor","appliance_repair","gas_leak_specialist"]
    location: Optional[str] = None
    city: str = "Islamabad"
    time_window: str
    urgency: Literal["emergency","high","normal","flexible"]
    job_complexity: Literal["basic","intermediate","complex"]
    specialization_hint: Optional[str] = None
    gender_preference: Literal["male","female","any"] = "any"
    budget_range: Optional[Tuple[int,int]] = None
    raw_notes: Optional[str] = None
    confidence: float # 0.0 to 1.0
    needs_clarification: bool = False
    clarification_question: Optional[str] = None

class ProviderCandidate(BaseModel):
    id: str
    name: str
    service_categories: List[str]
    specializations: List[str] = []
    distance_km: float
    neighborhood: str
    rating: float
    completed_jobs_in_area: int
    on_time_score: float
    cancellation_rate: float
    review_recency_days: int
    risk_score: float
    current_workload: float
    availability_status: Literal["available_now","next_slot_within_2h","next_slot_today","tomorrow_or_later"]
    next_slot: str # ISO datetime
    base_visit_fee_pkr: int
    rate_per_hour_pkr: int
    gender: Literal["male","female"]
    years_experience: int
    languages: List[str] = []
    verified: bool = True
    phone_masked: str
    lat: Optional[float] = None
    lng: Optional[float] = None
    alternate_slot_reason: Optional[str] = None # only on alternates

class DiscoveryResult(BaseModel):
    candidates: List[ProviderCandidate]
    alternates: List[ProviderCandidate] = []
    no_match_reason: Optional[str] = None

class FactorScores(BaseModel):
    distance: float
    availability: float
    rating: float
    on_time: float
    specialization: float
    risk: float
    total: float

class RankingResult(BaseModel):
    recommended_id: Optional[str]
    top_three_ids: List[str] = []
    factor_scores: Dict[str, FactorScores] = {}
    reasoning_english: str = ""
    reasoning_urdu: str = ""
    tradeoffs: str = ""
    confidence: Literal["high","medium","low"] = "medium"
    error: Optional[str] = None

class PriceLineItem(BaseModel):
    label_english: str
    label_urdu: str
    amount_pkr: int # negative for discounts
    kind: Literal["base","addon","multiplier","discount","surge"]

class PriceQuote(BaseModel):
    quote_id: str
    line_items: List[PriceLineItem]
    subtotal_pkr: int
    estimated_total_pkr: int
    estimated_range_pkr: Tuple[int,int]
    explanation_english: str
    explanation_urdu: str
    fairness_note: str
    expires_at: str # ISO

class BookingLifecycle(BaseModel):
    confirmed_at: Optional[str] = None
    en_route_at: Optional[str] = None
    arrived_at: Optional[str] = None
    in_progress_at: Optional[str] = None
    completed_at: Optional[str] = None
    cancelled_at: Optional[str] = None

class Booking(BaseModel):
    booking_id: str
    user_id: str
    provider_id: str
    service_type: str
    location: str
    city: str
    scheduled_time: str
    status: Literal["confirmed","en_route","arrived","in_progress","completed","cancelled","disputed"] = "confirmed"
    lifecycle: BookingLifecycle
    accepted_quote: PriceQuote
    intent_snapshot: Intent
    ranking_snapshot: Optional[RankingResult] = None
    receipt_url: Optional[str] = None
    confirmation_message_english: str = ""
    confirmation_message_urdu: str = ""
    provider_name: Optional[str] = None
    provider_lat: Optional[float] = None
    provider_lng: Optional[float] = None
    provider_phone: Optional[str] = None
    # Static ETA + WhatsApp tracking fields
    user_lat: Optional[float] = None
    user_lng: Optional[float] = None
    eta_minutes: Optional[int] = None
    whatsapp_url: Optional[str] = None

class FollowupResult(BaseModel):
    mode: Literal["reminder","checkin","dispute"]
    english: str = ""
    urdu: str = ""
    cta: Literal["rate","contact_provider","none"] = "none"
    classification: Optional[str] = None
    resolution: Optional[str] = None
    refund_pkr: int = 0
    escalate_to_human: bool = False

class OrchestrateRequest(BaseModel):
    text: str
    user_id: str
    user_location: Optional[Tuple[float,float]] = None # (lat, lng)

class OrchestrateResponse(BaseModel):
    intent: Intent
    discovery: Optional[DiscoveryResult] = None
    ranking: Optional[RankingResult] = None
    pricing: Optional[PriceQuote] = None
    booking_preview: Optional[Dict] = None
    followup_planned: Optional[Dict] = None
    needs_clarification: bool = False
    clarification_question: Optional[str] = None
    user_message_urdu: Optional[str] = None
    user_message_english: Optional[str] = None
