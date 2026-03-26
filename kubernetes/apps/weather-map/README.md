# Weather Map Application

Weather Map application with full observability stack integration.

## Components

### Backend

- Node.js API with Express
- Pino structured logging (JSON format for Loki)
- Prometheus metrics endpoint at `/metrics`
- Health check endpoint at `/health`

### Frontend

- React application
- Nginx web server

## Observability

### Metrics (Prometheus)

Backend exposes metrics at `http://weather-map-backend/metrics`:

#### HTTP Metrics

- `http_request_duration_seconds` - HTTP request latency histogram
  - Labels: `method`, `route`, `status`
- `http_requests_total` - Total HTTP requests counter
  - Labels: `method`, `route`, `status`

#### Weather API Metrics

- `weather_api_calls_total` - Weather API calls counter
  - Labels: `status` (success/error)
- `weather_api_duration_seconds` - Weather API latency histogram

#### Viewing Metrics

```bash
# Port-forward to backend
kubectl port-forward -n weather-map svc/weather-map-backend 3001:80

# View metrics
curl http://localhost:3001/metrics
```

### Logs (Loki)

Backend uses Pino for structured JSON logging. Logs are automatically collected by Promtail and sent to Loki.

#### Log Format

```json
{
  "level": 30,
  "time": 1234567890,
  "msg": "Request completed",
  "req": {
    "method": "GET",
    "url": "/api/weather",
    "headers": {...}
  },
  "res": {
    "statusCode": 200
  },
  "responseTime": 123
}
```

#### Querying Logs in Grafana

```logql
# All backend logs
{namespace="weather-map", app="weather-map-backend"}

# Error logs only
{namespace="weather-map", app="weather-map-backend"} |= "error"

# Logs with response time > 1s
{namespace="weather-map", app="weather-map-backend"} | json | responseTime > 1000
```

### Traces (Tempo)

Distributed tracing integration (if implemented in backend).

### Grafana Dashboard

Pre-configured dashboard available at: Grafana → Dashboards → Weather Map Dashboard

Includes:

- HTTP request rate by endpoint
- Request duration percentiles (p95, p99)
- Weather API call rate and status
- Weather API latency
- Live log stream

## Accessing Services

### Applications

- Frontend: https://weather-app.thebrainsurf.site
- Backend API: https://weather-api.thebrainsurf.site

### Monitoring

- Grafana: https://grafana.thebrainsurf.site
- Prometheus: https://prometheus.thebrainsurf.site

## ServiceMonitor

Prometheus automatically scrapes metrics from the backend using ServiceMonitor:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: weather-map-backend
  namespace: weather-map
spec:
  selector:
    matchLabels:
      app: weather-map-backend
  endpoints:
    - port: http
      path: /metrics
      interval: 30s
```

## Troubleshooting

### Check if metrics are being scraped

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n weather-map

# Check Prometheus targets
# Go to Prometheus UI → Status → Targets
# Look for "weather-map/weather-map-backend"
```

### Check logs

```bash
# View backend logs
kubectl logs -n weather-map -l app=weather-map-backend -f

# View logs in Grafana
# Go to Explore → Select Loki → Query: {namespace="weather-map"}
```

### Check metrics endpoint

```bash
# Port-forward and test
kubectl port-forward -n weather-map svc/weather-map-backend 3001:80
curl http://localhost:3001/metrics
```

## Example Queries

### PromQL (Prometheus)

```promql
# Request rate
rate(http_requests_total{namespace="weather-map"}[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{namespace="weather-map"}[5m]))

# Error rate
rate(http_requests_total{namespace="weather-map", status=~"5.."}[5m])

# Weather API success rate
rate(weather_api_calls_total{namespace="weather-map", status="success"}[5m])
```

### LogQL (Loki)

```logql
# All logs
{namespace="weather-map", app="weather-map-backend"}

# Errors only
{namespace="weather-map", app="weather-map-backend"} |= "error"

# Slow requests (>1s)
{namespace="weather-map", app="weather-map-backend"} | json | responseTime > 1000

# Weather API calls
{namespace="weather-map", app="weather-map-backend"} |= "weather api"
```
