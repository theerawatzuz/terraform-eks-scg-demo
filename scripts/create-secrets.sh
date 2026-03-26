#!/bin/bash
set -e

REGION="ap-southeast-1"

# Check if required environment variables are set
if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_TOKEN environment variable is not set"
  echo "Usage: GITHUB_TOKEN=your_token WEATHER_API_KEY=your_key ./scripts/create-secrets.sh"
  exit 1
fi

if [ -z "$WEATHER_API_KEY" ]; then
  echo "Error: WEATHER_API_KEY environment variable is not set"
  echo "Usage: GITHUB_TOKEN=your_token WEATHER_API_KEY=your_key ./scripts/create-secrets.sh"
  exit 1
fi

echo "Creating secrets in AWS Secrets Manager..."

# 1. ArgoCD Image Updater Git Credentials
echo "Creating ArgoCD Image Updater Git credentials..."
aws secretsmanager create-secret \
  --name eks/argocd-image-updater/git-credentials \
  --description "Git credentials for ArgoCD Image Updater" \
  --secret-string "{
    \"username\": \"git\",
    \"password\": \"$GITHUB_TOKEN\"
  }" \
  --region $REGION \
  --profile default 2>/dev/null || \
aws secretsmanager update-secret \
  --secret-id eks/argocd-image-updater/git-credentials \
  --secret-string "{
    \"username\": \"git\",
    \"password\": \"$GITHUB_TOKEN\"
  }" \
  --region $REGION \
  --profile default

echo "✓ ArgoCD Image Updater Git credentials created/updated"

# 2. Weather Map Backend Secrets
echo "Creating Weather Map Backend secrets..."
aws secretsmanager create-secret \
  --name eks/weather-map/backend \
  --description "Weather Map Backend environment variables" \
  --secret-string "{
    \"WEATHER_API_KEY\": \"$WEATHER_API_KEY\",
    \"WEATHER_PROVIDER\": \"openweathermap\",
    \"PORT\": \"3001\",
    \"FRONTEND_URL\": \"https://weather-app.thebrainsurf.site\",
    \"NODE_ENV\": \"production\"
  }" \
  --region $REGION \
  --profile default 2>/dev/null || \
aws secretsmanager update-secret \
  --secret-id eks/weather-map/backend \
  --secret-string "{
    \"WEATHER_API_KEY\": \"$WEATHER_API_KEY\",
    \"WEATHER_PROVIDER\": \"openweathermap\",
    \"PORT\": \"3001\",
    \"FRONTEND_URL\": \"https://weather-app.thebrainsurf.site\",
    \"NODE_ENV\": \"production\"
  }" \
  --region $REGION \
  --profile default

echo "✓ Weather Map Backend secrets created/updated"

# 3. Weather Map Frontend Secrets
echo "Creating Weather Map Frontend secrets..."
aws secretsmanager create-secret \
  --name eks/weather-map/frontend \
  --description "Weather Map Frontend environment variables" \
  --secret-string '{
    "VITE_API_URL": "https://weather-api.thebrainsurf.site"
  }' \
  --region $REGION \
  --profile default 2>/dev/null || \
aws secretsmanager update-secret \
  --secret-id eks/weather-map/frontend \
  --secret-string '{
    "VITE_API_URL": "https://weather-api.thebrainsurf.site"
  }' \
  --region $REGION \
  --profile default

echo "✓ Weather Map Frontend secrets created/updated"

echo ""
echo "All secrets created successfully!"
echo ""
echo "Secrets created:"
echo "  - eks/argocd-image-updater/git-credentials"
echo "  - eks/weather-map/backend"
echo "  - eks/weather-map/frontend"
