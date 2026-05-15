import json
import pytest
from pathlib import Path
from app.agents import intent_agent

@pytest.fixture
def intent_examples():
    path = Path("app/data/intent_examples.jsonl")
    if not path.exists():
        return []
    examples = []
    with open(path, "r") as f:
        for line in f:
            if line.strip():
                examples.append(json.loads(line))
    return examples

@pytest.mark.asyncio
async def test_intent_accuracy(intent_examples, monkeypatch):
    monkeypatch.setattr("app.agents.intent_agent.get_client", lambda: None)
    from app.config import settings
    if settings.GEMINI_API_KEY == "fake":
        pytest.skip("Skipping accuracy test in mock mode")
    
    if not intent_examples:
        pytest.skip("No intent examples found")

    svc_correct = 0
    cmplx_correct = 0
    
    for ex in intent_examples:
        actual = await intent_agent.run(ex["input"])
        expected = ex["expected"]
        
        if actual.service_type == expected.get("service_type"):
            svc_correct += 1
        if actual.job_complexity == expected.get("job_complexity"):
            cmplx_correct += 1
            
        if expected.get("needs_clarification"):
            assert actual.confidence < 0.7, f"Expected low confidence for {ex['input']}"
            assert actual.clarification_question is not None
        else:
            conf_min = expected.get("confidence_min", 0.7)
            assert actual.confidence >= (conf_min - 0.1), f"Confidence too low for {ex['input']}"

    n = len(intent_examples)
    assert (svc_correct / n) >= 0.50, f"Service type accuracy too low: {svc_correct/n}"
    assert (cmplx_correct / n) >= 0.50, f"Complexity accuracy too low: {cmplx_correct/n}"
