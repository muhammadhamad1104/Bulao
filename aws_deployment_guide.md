# Bulao Backend — AWS Deployment Guide

## Option 1: AWS App Runner (Recommended for Hackathon)

### Prerequisites
- AWS Account with access keys (Access Key ID + Secret Access Key)
- Docker installed locally
- AWS CLI installed: `pip install awscli`

### Step 1 — Configure AWS CLI
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output (json)
```

### Step 2 — Create ECR Repository
```bash
aws ecr create-repository --repository-name bulao-backend --region us-east-1
# Note the repositoryUri from the output e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/bulao-backend
```

### Step 3 — Build & Push Docker Image
```bash
# From inside the backend/ folder:
cd backend

# Login to ECR (replace ACCOUNT_ID and REGION)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build
docker build -t bulao-backend .

# Tag
docker tag bulao-backend:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/bulao-backend:latest

# Push
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/bulao-backend:latest
```

### Step 4 — Create App Runner Service (AWS Console)
1. Go to AWS Console → App Runner → Create Service
2. Source: Container Registry → Amazon ECR
3. Select your `bulao-backend` image → `latest` tag
4. Port: **8080**
5. Environment Variables (add these):
   ```
   GEMINI_API_KEY=your_fresh_api_key_here
   GOOGLE_CLOUD_PROJECT=bulao-hackathon
   DEMO_MODE=false
   LOG_LEVEL=INFO
   ```
6. Health check path: `/health`
7. Click **Create & Deploy**

### Step 5 — Get Your Public URL
App Runner will give you a URL like:
```
https://xxxxxxxxxxxx.us-east-1.awsapprunner.com
```

### Step 6 — Update Flutter App
In `mobile/lib/core/services/api_service.dart`, change the base URL to:
```dart
static const String baseUrl = 'https://xxxxxxxxxxxx.us-east-1.awsapprunner.com';
```

---

## Option 2: Deploy with CLI (Fully Automated)

Run this script after completing Steps 1-3 above:

```bash
# Replace these values:
ACCOUNT_ID="123456789012"
REGION="us-east-1"
GEMINI_KEY="your_api_key_here"
IMAGE_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/bulao-backend:latest"

aws apprunner create-service \
  --service-name bulao-backend \
  --source-configuration "{
    \"ImageRepository\": {
      \"ImageIdentifier\": \"$IMAGE_URI\",
      \"ImageRepositoryType\": \"ECR\",
      \"ImageConfiguration\": {
        \"Port\": \"8080\",
        \"RuntimeEnvironmentVariables\": {
          \"GEMINI_API_KEY\": \"$GEMINI_KEY\",
          \"GOOGLE_CLOUD_PROJECT\": \"bulao-hackathon\",
          \"DEMO_MODE\": \"false\",
          \"LOG_LEVEL\": \"INFO\"
        }
      }
    },
    \"AutoDeploymentsEnabled\": false,
    \"AuthenticationConfiguration\": {
      \"AccessRoleArn\": \"arn:aws:iam::$ACCOUNT_ID:role/AppRunnerECRAccessRole\"
    }
  }" \
  --health-check-configuration "Protocol=HTTP,Path=/health,Interval=10,Timeout=5,HealthyThreshold=1,UnhealthyThreshold=3" \
  --region $REGION
```

---

## Estimated Cost
- App Runner: ~$0.064/vCPU-hour + $0.007/GB-hour
- For a hackathon demo (~24 hours): **< $2 total**

## Troubleshooting
| Error | Fix |
|---|---|
| 503 on /health | Check GEMINI_API_KEY is set correctly |
| 429 from agents | API key quota hit — rotate key or set DEMO_MODE=true |
| Docker build fails | Run `poetry lock --no-update` then rebuild |
