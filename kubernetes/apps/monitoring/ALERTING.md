# Alerting Setup

## Overview

Prometheus Alertmanager configuration for Weather Map application with webhook notifications.

## Alerts Configured

### Critical Alerts 🚨

1. **WeatherMapPodCrashing**
   - Trigger: Pod restarts > 0 in last 5 minutes
   - Duration: 1 minute
   - Action: Immediate webhook notification

2. **WeatherMapHigh5xxRate**
   - Trigger: 5xx error rate > 0.05 req/s
   - Duration: 2 minutes
   - Action: Immediate webhook notification

### Warning Alerts ⚠️

3. **WeatherMapHighCPU**
   - Trigger: CPU usage > 80% of limit
   - Duration: 5 minutes
   - Action: Webhook notification

4. **WeatherMapHighMemory**
   - Trigger: Memory usage > 80% of limit
   - Duration: 5 minutes
   - Action: Webhook notification

5. **WeatherMapPodNotReady**
   - Trigger: Pod not in Running/Succeeded state
   - Duration: 5 minutes
   - Action: Webhook notification

6. **WeatherMapHPAMaxReplicas**
   - Trigger: HPA reached max replicas
   - Duration: 5 minutes
   - Action: Webhook notification (consider scaling limits)

7. **WeatherAPIHighErrorRate**
   - Trigger: Weather API error rate > 10%
   - Duration: 2 minutes
   - Action: Webhook notification

### Info Alerts ℹ️

8. **WeatherMapHPAScaling**
   - Trigger: HPA replica count changed
   - Duration: Immediate
   - Action: Webhook notification (grouped, 24h repeat)

## Webhook Receiver

Simple Flask application that receives Alertmanager webhooks and sends formatted alerts to Discord.

### Status

✅ **Discord Integration Active**

- Webhook URL: `https://discord.com/api/webhooks/1486694466436993044/WorvOSDMnUojPJ4XjRfHB6iwemfniQ__vlFoCt6LYlwjDEtpEXTNFOwBuBXfXoW9cJN7`
- Status: Working (HTTP 204 responses)
- Alerts are automatically sent to Discord with color-coded embeds

### Endpoints

- `POST /webhook` - Default webhook endpoint
- `POST /webhook/critical` - Critical alerts
- `POST /webhook/warning` - Warning alerts
- `POST /webhook/info` - Info alerts (HPA scaling)
- `GET /health` - Health check

### Alert Format

```
🔥 **WeatherMapPodCrashing**
Status: FIRING
Severity: CRITICAL
Component: weather-map

Pod weather-map-backend-xxx is crash looping
Pod weather-map-backend-xxx in namespace weather-map has restarted 3 times in the last 5 minutes

Pod: weather-map-backend-xxx
Namespace: weather-map
```

## Integration Examples

### Slack Integration

Add to `webhook-receiver.py`:

```python
import requests

def send_to_slack(message):
    webhook_url = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
    payload = {
        "text": message,
        "username": "Prometheus Alert",
        "icon_emoji": ":fire:"
    }
    requests.post(webhook_url, json=payload)
```

### Discord Integration

```python
def send_to_discord(message):
    webhook_url = "https://discord.com/api/webhooks/YOUR/WEBHOOK"
    payload = {
        "content": message,
        "username": "Prometheus Alert"
    }
    requests.post(webhook_url, json=payload)
```

### Microsoft Teams Integration

```python
def send_to_teams(message):
    webhook_url = "https://outlook.office.com/webhook/YOUR/WEBHOOK"
    payload = {
        "@type": "MessageCard",
        "@context": "http://schema.org/extensions",
        "text": message
    }
    requests.post(webhook_url, json=payload)
```

## Testing Alerts

### Trigger High CPU Alert

```bash
# Port-forward to backend
kubectl port-forward -n weather-map svc/weather-map-backend 3001:80

# Generate load
for i in {1..1000}; do curl http://localhost:3001/api/weather?city=Bangkok & done
```

### Trigger Pod Crash Alert

```bash
# Kill a pod
kubectl delete pod -n weather-map -l app=weather-map-backend --force
```

### Trigger HPA Scaling

```bash
# Generate sustained load to trigger HPA
kubectl run -it --rm load-generator --image=busybox --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://weather-map-backend.weather-map/api/weather?city=Bangkok; done"
```

## Viewing Alerts

### Prometheus UI

```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Open http://localhost:9090/alerts
```

### Alertmanager UI

```bash
# Port-forward Alertmanager
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093

# Open http://localhost:9093
```

### Webhook Receiver Logs

```bash
# View webhook receiver logs
kubectl logs -n monitoring -l app=webhook-receiver -f
```

## Alert Routing

```
┌─────────────┐
│ Prometheus  │
│   Alerts    │
└──────┬──────┘
       │
       v
┌─────────────┐
│ Alertmanager│
└──────┬──────┘
       │
       ├─── Critical ──> /webhook/critical
       ├─── Warning  ──> /webhook/warning
       └─── Info     ──> /webhook/info
                          │
                          v
                    ┌──────────────┐
                    │   Webhook    │
                    │   Receiver   │
                    └──────┬───────┘
                           │
                           ├─── Slack
                           ├─── Discord
                           ├─── Teams
                           └─── Logs
```

## Configuration Files

- `prometheus-rules.yaml` - PrometheusRule CRD with alert definitions
- `alertmanager-config.yaml` - Alertmanager configuration secret
- `webhook-receiver.yaml` - Webhook receiver deployment

## Deployment

```bash
# Apply PrometheusRules
kubectl apply -f kubernetes/apps/monitoring/prometheus-rules.yaml

# Apply Alertmanager config
kubectl apply -f kubernetes/apps/monitoring/alertmanager-config.yaml

# Deploy webhook receiver
kubectl apply -f kubernetes/apps/monitoring/webhook-receiver.yaml

# Verify
kubectl get prometheusrules -n monitoring
kubectl get pods -n monitoring -l app=webhook-receiver
```

## Troubleshooting

### Alerts not firing

```bash
# Check PrometheusRule
kubectl describe prometheusrule weather-map-alerts -n monitoring

# Check Prometheus targets
# Go to Prometheus UI → Status → Targets

# Check alert rules
# Go to Prometheus UI → Alerts
```

### Webhook not receiving alerts

```bash
# Check Alertmanager config
kubectl get secret alertmanager-kube-prometheus-stack-alertmanager -n monitoring -o yaml

# Check webhook receiver logs
kubectl logs -n monitoring -l app=webhook-receiver -f

# Test webhook manually
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -- \
  curl -X POST http://webhook-receiver.monitoring:8080/webhook \
  -H "Content-Type: application/json" \
  -d '{"alerts":[{"status":"firing","labels":{"alertname":"Test"}}]}'
```
