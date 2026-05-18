# Bulao Pitch Script — Regional Finals (May 25-26) + Islamabad Finals (June 7)

## PART 1 — Hook (0:00-1:00)
[Stand center stage. Phone in hand, screen off. Pause for 2 seconds.]

"Islamabad. Mid-May. The AC stops working. You open WhatsApp. You forward the same message to four group chats: 'Koi achha AC technician ka number bhejo G-13 ke liye?' Three hours later you have six numbers — half of them old, half of them don't pick up. The one who does asks PKR 4,000 for a visit. Your neighbour swears the same person charged him 1,500 last month.

This is how Pakistan's informal service economy works today. Through WhatsApp forwards. Through trust networks that don't scale. Through prices that nobody agrees on.

[Hold up the demo phone, screen on showing Bulao home screen.]

We built Bulao. You press a button. You speak in Urdu. Ninety seconds later you have a verified provider, a transparent price, and a confirmed booking. Six AI agents — visible on screen — do the work.

**Bolo, aur kaam ho jaye.**"

[Pause for 2 seconds. Tap the mic button to start the demo video.]

## PART 2 — Live demo (1:00-3:30)
[Demo video plays muted on the projector behind you. You narrate over it.]

"Pehla agent samajhta hai kya kaam hai, kab chahiye, kitna complex hai. It extracts seven fields from the Urdu sentence, with a confidence score.

[Beat at 1:00] Doosra agent paas ke providers dhoondhta hai. It uses a 30-minute travel buffer and suggests alternate slots if not enough match.

[Beat at 1:30] Yeh teesra agent — yeh sab se important hai. It scores candidates across SIX factors — distance, availability, rating, on-time, specialisation, risk — and explains its choice in natural Urdu with specific numbers. Not 'best for you' — 'Ali sab se behtar — 1.4 kilometre door, 4.8 rating, 98 percent on time'.

[Beat at 2:00] Chautha agent — pricing. Every rupee accounted for. Visit fee, service time, complexity adjustment for inverter ACs, surge because demand is high, welcome discount. AND a fairness note: 'Provider receives 1,920 after platform fee.'

[Beat at 2:30] Booking confirm. Receipt generated. Reminder scheduled.

[Beat at 3:20] AND — when something goes wrong — the sixth agent classifies the dispute and proposes a fair resolution. Two stars? Partial refund OR free re-service. The user chooses. Insaaf."

[Demo ends at 3:30. Step toward audience.]

## PART 3 — Antigravity (3:30-4:30)
"We built every line of this in five days, with Google Antigravity as our orchestrator. Not as an autocomplete — as a colleague.

We ran **over 60 Plan Artifacts**. We executed dozens of agent runs across five Manager View workspaces in parallel. We delegated browser verification, eval harnessing, data generation, prompt iteration — and we spent our human time on the things humans should — Urdu naturalness, demo direction, customer empathy.

[Specific moment.] On Day 3, Antigravity reviewed our Ranking Agent's output and flagged that our 'tradeoffs' field was being padded with English idioms — 'cheaper but slower' instead of 'lekin Rashid 30 minute door hai'. We iterated. Urdu naturalness went from 3.8 to 4.6 out of 5.

Yeh hai Antigravity-powered development."

## PART 4 — Why this wins (4:30-5:00)
"Two highest-weighted rubric criteria. Matching quality, 25 percent — six explicit factors with weights per urgency level. Antigravity integration, 20 percent — sixty Plan Artifacts in our trace deliverable.

Bulao is honest. The agents are visible. The prices are transparent. The disputes are resolved fairly. The Urdu sounds like Urdu.

[Pause. Look directly at judges.]

**Bolo, aur kaam ho jaye.**"

[Step back. Hand the mic.]

---

## Q&A — Anticipated questions

**Q1: "What about real Maps integration?"**
A: "Stretch goal. We chose mock data for demo reliability — Maps Places calls cost real money and rate-limit. The mock has 100 providers across 14 neighborhoods. The Discovery Agent is API-agnostic; swapping in Places is a one-day job."

**Q2: "What about provider onboarding?"**
A: "Roadmap. The dispute mechanism actually makes provider onboarding EASIER — providers know that disputes are classified fairly, not on the customer's word alone. Lower acquisition cost than apps that side with the customer."

**Q3: "Why six agents specifically?"**
A: "Each agent maps to a distinct rubric requirement. Pricing maps to 'dynamic pricing'. Follow-up & Dispute maps to the 15-percent dispute-and-reliability criterion. Five agents would have left points on the table."

**Q4: "Hardest part?"**
A: "Urdu naturalness in the Ranking Agent. The model defaults to English-translated Urdu. We built a quality sweep on Day 4 — three inputs, five agents, fifteen graded outputs — and iterated until the average grade hit 4.5 out of 5. That took six hours of prompt iteration across two of our teammates."
