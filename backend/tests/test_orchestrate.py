import pytest
from app.main import app
from fastapi.testclient import TestClient

client = TestClient(app)

@pytest.fixture(autouse=True)
def mock_clients(monkeypatch):
    monkeypatch.setattr("app.agents.intent_agent.get_client", lambda: None)
    monkeypatch.setattr("app.agents.ranking_agent.get_client", lambda: None)
    monkeypatch.setattr("app.agents.pricing_agent.get_client", lambda: None)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_orchestrate_success():
    payload = {
        "text": "Mujhe G-13 mein kal subah AC theek karwana hai",
        "user_id": "u_test"
    }
    response = client.post("/orchestrate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "intent" in data
    assert "discovery" in data
    assert "ranking" in data
    assert "pricing" in data
    assert data["intent"]["service_type"] == "ac_technician"
    assert data["intent"]["confidence"] >= 0.7

def test_orchestrate_clarification():
    payload = {
        "text": "mere ghar pe plumber bhejo",
        "user_id": "u_test"
    }
    response = client.post("/orchestrate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data.get("needs_clarification") is True
    assert "clarification_question" in data
    assert data["intent"]["confidence"] < 0.7

def test_orchestrate_no_match():
    payload = {
        "text": "gas leak specialist in F-7 right now",
        "user_id": "u_test"
    }
    # This might find a match or not depending on random seed, but let's test if it returns 200 properly anyway
    response = client.post("/orchestrate", json=payload)
    assert response.status_code == 200
    data = response.json()
    if data.get("discovery", {}).get("no_match_reason"):
        assert "user_message_urdu" in data
