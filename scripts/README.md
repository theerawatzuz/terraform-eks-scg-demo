# Scripts

## create-secrets.sh

สคริปต์สำหรับสร้าง secrets ใน AWS Secrets Manager

### การใช้งาน

```bash
# ตั้งค่า environment variables
export GITHUB_TOKEN="your_github_token_here"
export WEATHER_API_KEY="your_weather_api_key_here"

# รัน script
./scripts/create-secrets.sh

# หรือรันแบบ one-liner
GITHUB_TOKEN=your_token WEATHER_API_KEY=your_key ./scripts/create-secrets.sh
```

### Secrets ที่สร้าง

1. **eks/argocd-image-updater/git-credentials**
   - username: git
   - password: GitHub Personal Access Token

2. **eks/weather-map/backend**
   - WEATHER_API_KEY: OpenWeatherMap API key
   - WEATHER_PROVIDER: openweathermap
   - PORT: 3001
   - FRONTEND_URL: https://weather-app.thebrainsurf.site
   - NODE_ENV: production

3. **eks/weather-map/frontend**
   - VITE_API_URL: https://weather-api.thebrainsurf.site

### หมายเหตุ

- Script จะสร้าง secret ใหม่ หรืออัพเดทถ้ามีอยู่แล้ว
- ใช้ AWS profile "default" และ region "ap-southeast-1"
- External Secrets Operator จะดึง secrets เหล่านี้มาใช้ใน Kubernetes

### การตรวจสอบ

```bash
# ดู secrets ใน AWS
aws secretsmanager list-secrets --region ap-southeast-1

# ดูค่าใน secret
aws secretsmanager get-secret-value --secret-id eks/weather-map/backend --region ap-southeast-1

# ตรวจสอบ External Secrets ใน Kubernetes
kubectl get externalsecrets -n weather-map
kubectl get secrets -n weather-map
```
