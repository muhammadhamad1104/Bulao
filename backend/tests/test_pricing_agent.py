import pytest
from app.models import Intent, ProviderCandidate
from app.agents import pricing_agent
from app.agents.pricing_agent import _compute_line_items

@pytest.fixture
def mock_provider():
    return ProviderCandidate(
        id="c1", name="Ali", service_categories=["plumber"], distance_km=1.0,
        neighborhood="G-13", rating=4.9, completed_jobs_in_area=50, on_time_score=0.9,
        cancellation_rate=0.01, review_recency_days=2, risk_score=0.05, current_workload=0.2,
        availability_status="available_now", next_slot="", base_visit_fee_pkr=500,
        rate_per_hour_pkr=1000, gender="male", years_experience=10, phone_masked="+92"
    )

def test_pricing_complexity(mock_provider):
    intent_basic = Intent(service_type="plumber", time_window="now", urgency="normal", job_complexity="basic", confidence=0.9, city="Islamabad")
    intent_complex = Intent(service_type="plumber", time_window="now", urgency="normal", job_complexity="complex", confidence=0.9, city="Islamabad")
    
    items_basic, total_basic = _compute_line_items(intent_basic, mock_provider, 0.4, False)
    items_complex, total_complex = _compute_line_items(intent_complex, mock_provider, 0.4, False)
    
    assert total_complex > total_basic

def test_pricing_emergency(mock_provider):
    intent_norm = Intent(service_type="plumber", time_window="now", urgency="normal", job_complexity="basic", confidence=0.9, city="Islamabad")
    intent_emerg = Intent(service_type="plumber", time_window="now", urgency="emergency", job_complexity="basic", confidence=0.9, city="Islamabad")
    
    items_norm, _ = _compute_line_items(intent_norm, mock_provider, 0.4, False)
    items_emerg, _ = _compute_line_items(intent_emerg, mock_provider, 0.4, False)
    
    assert not any(i.amount_pkr == 500 and "Urgency" in i.label_english for i in items_norm)
    assert any(i.amount_pkr == 500 and "Urgency" in i.label_english for i in items_emerg)

def test_pricing_surge(mock_provider):
    intent = Intent(service_type="plumber", time_window="now", urgency="normal", job_complexity="basic", confidence=0.9, city="Islamabad")
    items, _ = _compute_line_items(intent, mock_provider, 0.6, False)
    assert any("surge" in i.kind for i in items)

def test_pricing_first_booking(mock_provider):
    intent = Intent(service_type="plumber", time_window="now", urgency="normal", job_complexity="basic", confidence=0.9, city="Islamabad")
    items, _ = _compute_line_items(intent, mock_provider, 0.4, True)
    assert any(i.amount_pkr < 0 and i.kind == "discount" for i in items)

@pytest.mark.asyncio
async def test_pricing_agent_run(mock_provider):
    intent = Intent(service_type="plumber", time_window="now", urgency="normal", job_complexity="basic", confidence=0.9, city="Islamabad")
    res = await pricing_agent.run(intent, mock_provider, 0.6, True)
    
    assert res.estimated_range_pkr[1] - res.estimated_range_pkr[0] >= 250
    for item in res.line_items:
        assert item.label_english
        assert item.label_urdu
