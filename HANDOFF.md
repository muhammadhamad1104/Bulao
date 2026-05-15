# Backend Workflows Handoff

## Submission Package v1.0.0
- **Image URI**: `asia-south1-docker.pkg.dev/bulao-hackathon/bulao/bulao-backend:v1.0.0`
- **Region**: `asia-south1` (Mumbai)
- **Deployment Script**: `backend/scripts/deploy.sh`

## Environment Variables
The following variables must be set in Secret Manager or Cloud Run:
- `GEMINI_API_KEY`: Required for real agent calls.
- `GOOGLE_CLOUD_PROJECT`: `bulao-hackathon`.
- `DEMO_MODE`: Set to `true` for the demo video to bypass real LLM latency and quota limits.
- `LOG_LEVEL`: `INFO`.

## Database
- We use Firestore (Native mode).
- Collection: `bookings`.
- Index required: `(status ASC, scheduled_time ASC)`.

## Scheduler
- A Cloud Scheduler job should be set up to call `POST /followup/trigger` every 30 minutes.
- Service Account: `bulao-scheduler@bulao-hackathon.iam.gserviceaccount.com`.

## Responsibility
- **Backend Workflows Lead** (Muhammad Hamad) owns the orchestration logic and transactional endpoints.
- **Backend Agents Lead** owns the individual agent prompts and intelligence.
- **Infrastructure Lead** (You) owns the final deployment and Secret Manager.
