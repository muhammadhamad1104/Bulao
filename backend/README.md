# Bulao Backend

## Overview
Bulao is a voice-first, Urdu-native AI service orchestrator for Pakistan's informal economy. This backend coordinates six AI agents to extract intent, discover providers, rank them, compute prices, and handle bookings.

## Architecture
See `/docs/diagrams/architecture.png` for architecture.

## Run locally
1. `poetry install`
2. `cp .env.example .env` and fill in `GEMINI_API_KEY`
3. `poetry run uvicorn app.main:app --reload --port 8080`

## Deploy
To deploy to Cloud Run:
`docker build -t bulao-backend .`
