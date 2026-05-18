#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
SERVICE_NAME="bulao-backend"
REGION="asia-south1"
IMAGE_TAG="v1.0.0"

echo "Building and pushing image for $PROJECT_ID..."

IMAGE_URI="asia-south1-docker.pkg.dev/$PROJECT_ID/bulao/$SERVICE_NAME:$IMAGE_TAG"

# Build and push using Cloud Build for faster performance
gcloud builds submit --tag "$IMAGE_URI" .

echo "Deploying to Cloud Run..."

gcloud run deploy "$SERVICE_NAME" \
    --image "$IMAGE_URI" \
    --region "$REGION" \
    --platform managed \
    --allow-unauthenticated \
    --set-env-vars "GOOGLE_CLOUD_PROJECT=$PROJECT_ID,DEMO_MODE=false,LOG_LEVEL=INFO" \
    --memory 1Gi \
    --cpu 1 \
    --min-instances 0 \
    --max-instances 10

echo "Deployment complete!"
gcloud run services describe "$SERVICE_NAME" --region "$REGION" --format 'value(status.url)'
