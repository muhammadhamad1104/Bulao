# Bulao — Bolo, aur kaam ho jaye.

Bulao is a voice-first, Urdu-native AI service orchestrator for Pakistan's informal economy — plumbers, electricians, AC technicians, beauticians, tutors. A user presses a big button on their phone, speaks in Urdu, Roman Urdu, or English, and within 90 seconds watches six AI agents extract their intent (with a confidence score and complexity tag), find providers nearby, rank them across six factors with visible reasoning, produce a transparent price breakdown, book a slot, track the service through completion, and — when something goes wrong — resolve the dispute fairly. The magic is that the agents are visible on screen as they work. That visibility is the agentic moneyshot the rubric rewards.

We built Bulao in five days for the AI Seekho 2026 Antigravity Hackathon (Challenge 2: AI Service Orchestrator for Informal Economy). Google Antigravity orchestrated every meaningful piece of work — from the 50-example Urdu utterance dataset to the six-agent Python backend to the polished Flutter mobile app. The 25%-weighted Antigravity Trace deliverable is at `docs/antigravity-trace/FINAL.pdf`.

**Tagline: Bolo, aur kaam ho jaye. (Speak, and it's handled.)**

---

## Demo Video
[![Bulao Demo](./docs/demo-assets/poster.png)](https://youtube.com/watch?v=unlisted-link)
Watch the full 4:30 demo on YouTube (unlisted): https://youtube.com/watch?v=unlisted-link

The video walks through one end-to-end booking (AC repair in G-13, Islamabad), including the new-in-v2 Pricing Card with line-item transparency and the new-in-v2 Dispute resolution flow when a service falls short of expectations.

---

## The 6-Agent Architecture
![Architecture](./docs/diagrams/architecture.png)

Six agents run in sequence inside the FastAPI backend on Cloud Run. Each agent has a single, narrow responsibility. The mobile app reveals each agent's output as an animated card as the pipeline progresses — that is the agentic moneyshot.

1. **Intent Agent** (Gemini Flash) — extracts service_type, location, time_window, urgency, job_complexity, specialization_hint, gender_preference from Urdu / Roman Urdu / English / code-switched input. Returns confidence score; populates clarification_question when confidence < 0.7.
2. **Discovery Agent** (Python, no LLM) — filters and pre-ranks up to 8 candidate providers from the 100-entry mock database. Enforces a 30-minute travel buffer; suggests alternate slots when fewer than 3 candidates fit.
3. **Ranking Agent** (Gemini 3 Pro) — scores candidates across six factors (distance, availability, rating, on-time, specialization, risk) with urgency-weighted profiles. Returns reasoning in both Urdu and English with at least three specific numbers cited per recommendation.
4. **Pricing Agent** (Gemini Flash, new in v2) — writes the natural-language explanation for a transparent line-item price quote. The math is deterministic Python; the LLM justifies it in language that feels fair. Always includes a fairness_note specifying what the provider receives.
5. **Booking Agent** (Python + Gemini Flash) — writes the confirmation message, generates the receipt PDF, initializes the service-quality lifecycle (confirmed → en_route → arrived → in_progress → completed).
6. **Follow-up & Dispute Agent** (Python + Gemini Flash + Cloud Scheduler) — two modes. Reminder/check-in on the happy path (Cloud Scheduler fires 30 min before and 2 hours after). Dispute classification + resolution when rating < 3 (partial_refund / full_refund / re_service / provider_warning / escalate_to_human).

---

## How Antigravity Was Used
Antigravity was the orchestrator for every meaningful piece of work in this five-day build. Below are four moments that capture how we used it.

### Plan Artifact before code
![Plan Artifact](./docs/antigravity-trace/manager-view/day1-plan-artifact.png)
We treated every non-trivial task as a Plan-Artifact-first task. Before any agent wrote code, Antigravity produced a Plan Artifact — a step-by-step breakdown we reviewed and either approved or redirected. The screenshot above shows the Plan Artifact for the Intent Agent build on Day 2: 14 steps from loading the .md prompt to wiring the FastAPI handler. We approved with one edit (tighter error-handling on parse failure), and Antigravity executed.

### Parallel Manager View workspaces
![Three Parallel Agents](./docs/antigravity-trace/manager-view/day1-three-parallel.png)
On Day 1 we ran three Manager View workspaces in parallel — one per teammate (Mobile, Backend, Infra) — each scaffolding a different layer of the stack. The screenshot shows all three running simultaneously, producing the Flutter project skeleton, the FastAPI scaffold, and the Cloud Run deployment in the same hour. This is the workflow the rubric's 25% Agent Trace score rewards.

### Browser recording verifies the Flutter app
![Browser Recording](./docs/antigravity-trace/browser-recordings/day2-flutter-test.png)
On Day 2 evening, an Antigravity browser-recording agent verified the Flutter app's home screen rendered correctly on the Android emulator — without a human in the loop. The agent navigated to the press-and-hold mic button, performed a hold gesture, and confirmed the recording UI appeared. We caught one bug from this (the hold gesture didn't fire on iOS) and fixed it that night.

### Knowledge Base for shared context
![Knowledge Base](./docs/antigravity-trace/knowledge-base/day3-shared-context.png)
We pinned the six agent system prompts, the 50-example dataset schema, and the v2 provider schema in the Knowledge Base. Every Manager View workspace referenced this shared context, which is what kept four humans + many Antigravity agents in sync on field names, JSON shapes, and Urdu conventions across five days.

---

## Tools & APIs
- **Google Antigravity** — IDE + agent orchestration (mandatory per rubric)
- **Gemini API** — Flash (cheap/fast) and 3 Pro (Ranking, voice input)
- **Google ADK** — agent framework, SequentialAgent + tool calling
- **Flutter 3.x** — mobile app (Android + iOS)
- **FastAPI + uvicorn** — Python backend on Cloud Run
- **Firestore** — provider data + booking persistence
- **Cloud Run (asia-south1)** — backend hosting
- **Cloud Scheduler** — Follow-up Agent triggers
- **Secret Manager** — Gemini API key
- **Cloud Build + Artifact Registry** — container deploy pipeline

---

## Setup & Running Locally
```bash
# Backend
cd backend
poetry install
cp .env.example .env # paste your GEMINI_API_KEY
PYTHONPATH=. poetry run python -m uvicorn app.main:app --reload

# Run the intent eval
PYTHONPATH=. poetry run python scripts/eval_intent.py --dataset data/intent_examples.jsonl --report eval_report.md
```

---

## The 50-Example Urdu Dataset
We hand-curated 50 realistic Pakistani service requests across 10 service categories, 14 neighborhoods (Islamabad, Rawalpindi, Karachi, Lahore), and four urgency levels. The dataset is committed at [backend/app/data/intent_examples.jsonl](./backend/app/data/intent_examples.jsonl).

15 were anchor examples written by the Product & Urdu lead (Pakistani native speaker). 35 were extended by Antigravity following dialect constraints and reviewed line-by-line by the same author.

**Final eval accuracy (Day 4):**
- **service_type**: 92%+
- **job_complexity**: 85%+
- **confidence calibration**: 80% of low-confidence examples correctly flagged

---

## Roadmap
If we kept building after May 20:
- **Real Google Maps Places integration** — replace mock provider data with live Places API queries scoped to each neighborhood.
- **Provider-side app** — a Flutter companion app for providers, with workload balancing, demand forecasting, and the dispute-response UI.
- **Multi-city expansion** — extend the 50-example dataset and provider mock to Lahore, Karachi, Faisalabad with city-specific Urdu dialects.
- **WhatsApp Business API integration** — bookings, reminders, and disputes delivered to user's WhatsApp instead of an in-app chat.

---

## Team
- **Ibrahim** — Product & Urdu lead. Owned the 50-example dataset, six agent system prompts, demo direction, README, pitch.
- **Muhammad Hamad** — Backend & Infrastructure lead. Built Intent, Discovery, Ranking, Pricing agents, and the orchestration pipeline.
- **Taha Fayyaz and Wajeeha Kamran** — Mobile lead. Built the Flutter app, agent cards, and voice UI.
- **Ghufran Mehmood** — Infrastructure lead. Cloud Run, deployment pipeline, and trace capture.

---

## Acknowledgements
- **AI Seekho** and **InnoVista** for organising AI Seekho 2026.
- **MoITT** and **Telenor Pakistan** for sponsoring the hackathon.
- **Google for Developers** for Antigravity and Gemini API credits.