import pytest
from app.models import Intent
from app.agents import discovery_agent

@pytest.mark.asyncio
async def test_discovery_agent_exact_neighborhood(monkeypatch):
    mock_provs = [{
        "id": "mock_1", "name": "Plumber", "service_categories": ["plumber"],
        "gender": "male", "years_experience": 10, "rating": 5.0, "risk_score": 0.0,
        "current_workload": 0.0, "base_visit_fee_pkr": 500, "rate_per_hour_pkr": 1000,
        "languages": ["urdu"], "verified": True, "phone": "+923331234567",
        "neighborhood": "G-13", "lat": 33.6584, "lng": 73.0479,
        "cancellation_rate": 0.0, "on_time_score": 1.0, "review_recency_days": 1,
        "available_slots": ["2026-05-16T10:00:00+05:00"]
    }]
    monkeypatch.setattr("app.agents.discovery_agent._PROVIDERS", mock_provs)
    
    intent = Intent(
        service_type="plumber",
        location="G-13",
        city="Islamabad",
        time_window="flexible",
        urgency="normal",
        job_complexity="basic",
        gender_preference="any",
        confidence=0.9
    )
    res = await discovery_agent.run(intent)
    assert res.candidates or res.alternates
    for c in res.candidates:
        assert c.neighborhood == "G-13" or c.distance_km < 5.0
        assert "plumber" in c.service_categories

@pytest.mark.asyncio
async def test_discovery_agent_gender_filter():
    intent = Intent(
        service_type="beautician",
        location=None,
        city="Islamabad",
        time_window="flexible",
        urgency="normal",
        job_complexity="basic",
        gender_preference="female",
        confidence=0.9
    )
    res = await discovery_agent.run(intent)
    for c in res.candidates:
        assert c.gender == "female"
        assert "beautician" in c.service_categories

@pytest.mark.asyncio
async def test_discovery_agent_complexity_filter():
    intent = Intent(
        service_type="electrician",
        location=None,
        city="Islamabad",
        time_window="flexible",
        urgency="normal",
        job_complexity="complex",
        gender_preference="any",
        confidence=0.9
    )
    res = await discovery_agent.run(intent)
    for c in res.candidates:
        assert c.years_experience >= 5

@pytest.mark.asyncio
async def test_discovery_agent_phone_masked():
    intent = Intent(
        service_type="painter",
        location=None,
        city="Islamabad",
        time_window="flexible",
        urgency="normal",
        job_complexity="basic",
        gender_preference="any",
        confidence=0.9
    )
    res = await discovery_agent.run(intent)
    for c in res.candidates + res.alternates:
        assert "XXX" in c.phone_masked
        assert len(c.phone_masked) >= 8

@pytest.mark.asyncio
async def test_discovery_agent_empty_returns_reason():
    intent = Intent(
        service_type="gas_leak_specialist",
        location=None,
        city="Islamabad",
        time_window="now",
        urgency="emergency",
        job_complexity="complex",
        gender_preference="female",
        specialization_hint="unobtanium",
        confidence=0.9
    )
    res = await discovery_agent.run(intent)
    if not res.candidates and not res.alternates:
        assert res.no_match_reason is not None
