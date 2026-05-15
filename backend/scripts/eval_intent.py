import json
import argparse
import asyncio
from pathlib import Path
from app.agents import intent_agent

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", type=str, default="app/data/intent_examples.jsonl")
    parser.add_argument("--report", type=str, default="eval_report.md")
    args = parser.parse_args()
    
    examples = []
    with open(args.dataset, "r") as f:
        for line in f:
            if line.strip():
                examples.append(json.loads(line))
    
    async def process_all():
        tasks = [intent_agent.run(ex["input"]) for ex in examples]
        return await asyncio.gather(*tasks)
        
    actuals = asyncio.run(process_all())
    
    svc_correct = 0
    complexity_correct = 0
    conf_correct = 0
    
    failure_cases = []
    
    for i, ex in enumerate(examples):
        actual = actuals[i]
        expected = ex["expected"]
        
        svc_match = actual.service_type == expected.get("service_type")
        cmplx_match = actual.job_complexity == expected.get("job_complexity")
        
        conf_target = expected.get("confidence_min", 0.7)
        if expected.get("needs_clarification"):
            conf_match = actual.confidence < 0.7
        else:
            conf_match = actual.confidence >= (conf_target - 0.1)
            
        if svc_match:
            svc_correct += 1
        if cmplx_match:
            complexity_correct += 1
        if conf_match:
            conf_correct += 1
        
        if not svc_match or not cmplx_match:
            failure_cases.append({
                "input": ex["input"],
                "expected": expected,
                "actual": actual.model_dump()
            })
            
    n = len(examples)
    svc_acc = svc_correct / n if n > 0 else 0
    cmplx_acc = complexity_correct / n if n > 0 else 0
    conf_acc = conf_correct / n if n > 0 else 0
    
    report = "# Intent Agent Eval Report\n\n"
    report += f"- service_type_accuracy: {svc_acc:.2f}\n"
    report += f"- job_complexity_accuracy: {cmplx_acc:.2f}\n"
    report += f"- confidence_calibration: {conf_acc:.2f}\n\n"
    
    report += "## Top Failures\n"
    for i, fail in enumerate(failure_cases[:10]):
        report += f"**{i+1}.** Input: {fail['input']}\n"
        report += f"   Expected: svc={fail['expected'].get('service_type')}, cmplx={fail['expected'].get('job_complexity')}\n"
        report += f"   Actual: svc={fail['actual'].get('service_type')}, cmplx={fail['actual'].get('job_complexity')}\n"
        
    Path(args.report).write_text(report)
    
    print(f"Eval completed. Svc Acc: {svc_acc:.2f}, Cmplx Acc: {cmplx_acc:.2f}")
    if svc_acc >= 0.90 and cmplx_acc >= 0.85:
        exit(0)
    else:
        exit(1)

if __name__ == "__main__":
    main()
