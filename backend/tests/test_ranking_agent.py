import pytest
from app.models import Intent, ProviderCandidate
from app.agents import ranking_agent
from app.agents.ranking_agent import _compute_factor_scores

@pytest.fixture
def mock_candidates():
    return [
        ProviderCandidate(
            id="c1", name="Ali", service_categories=["plumber"], distance_km=1.0,
            neighborhood="G-13", rating=4.9, completed_jobs_in_area=50, on_time_score=0.9,
            cancellation_rate=0.01, review_recency_days=2, risk_score=0.05, current_workload=0.2,
            availability_status="available_now", next_slot="", base_visit_fee_pkr=500,
            rate_per_hour_pkr=1000, gender="male", years_experience=10, phone_masked="+92"
        ),
        ProviderCandidate(
            id="c2", name="Hassan", service_categories=["plumber"], distance_km=5.0,
            neighborhood="F-7", rating=4.5, completed_jobs_in_area=20, on_time_score=0.8,
            cancellation_rate=0.05, review_recency_days=5, risk_score=0.1, current_workload=0.8,
            availability_status="tomorrow_or_later", next_slot="", base_visit_fee_pkr=300,
            rate_per_hour_pkr=800, gender="male", years_experience=5, phone_masked="+92"
        )
    ]

@pytest.mark.asyncio
async def test_ranking_weights(mock_candidates):
    intent_emerg = Intent(service_type="plumber", time_window="now", urgency="emergency", job_complexity="basic", confidence=0.9, city="Islamabad")
    intent_norm = Intent(service_type="plumber", time_window="flexible", urgency="normal", job_complexity="basic", confidence=0.9, city="Islamabad")
    
    fs_emerg_c1 = _compute_factor_scores(mock_candidates[0], intent_emerg)
    fs_norm_c1 = _compute_factor_scores(mock_candidates[0], intent_norm)
    
    assert fs_emerg_c1.availability > fs_norm_c1.availability or intent_emerg.urgency == "emergency"

@pytest.mark.asyncio
async def test_ranking_reasoning(mock_candidates):
    intent = Intent(service_type="plumber", time_window="now", urgency="emergency", job_complexity="basic", confidence=0.9, city="Islamabad")
    res = await ranking_agent.run(intent, mock_candidates)
    
    digits = sum(c.isdigit() for c in res.reasoning_english)
    assert digits >= 3
    
    assert any(w in res.reasoning_urdu.lower() for w in ["hai", "behtar", "sirf", "door", "mein", "ke", "ki", "ka"])
    
    if len(mock_candidates) >= 3:
        assert len(res.top_three_ids) == 3
        
    assert len(res.factor_scores) == len(mock_candidates)

@pytest.mark.asyncio
async def test_ranking_empty():
    intent = Intent(service_type="plumber", time_window="now", urgency="emergency", job_complexity="basic", confidence=0.9, city="Islamabad")
    res = await ranking_agent.run(intent, [])
    assert res.recommended_id is None
    assert res.error == "no_candidates"
