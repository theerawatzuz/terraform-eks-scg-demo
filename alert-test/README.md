# Alert Testing Suite

Test suite for validating Prometheus alerts in the Weather Map application.

## Prerequisites

- k6 installed: `brew install k6` (macOS) or see https://k6.io/docs/getting-started/installation/
- kubectl configured with access to the cluster
- Port-forwarding or ingress access to services

## Alert Coverage

This test suite covers all configured alerts:

1. ✅ **WeatherMapPodCrashing** - Pod restart/crash detection
2. ✅ **WeatherMapPodNotReady** - Pod availability
3. ✅ **WeatherMapHighCPU** - CPU usage > 80%
4. ✅ **WeatherMapHighMemory** - Memory usage > 80%
5. ✅ **WeatherMapHigh5xxRate** - HTTP 5xx error rate
6. ✅ **WeatherAPIHighErrorRate** - Weather API error rate > 10%
7. ✅ **WeatherMapHPAScaling** - HPA scaling events
8. ✅ **WeatherMapHPAMaxReplicas** - HPA max replicas reached

## Quick Start

```bash
# Run all tests
./run-all-tests.sh

# Run specific test
./test-high-cpu.sh
./test-high-memory.sh
./test-pod-crash.sh
./test-http-errors.sh
```

## Test Scripts

### K6 Load Tests

- `k6-high-cpu.js` - Generate CPU load to trigger high CPU alert
- `k6-high-memory.js` - Generate memory pressure (via sustained requests)
- `k6-http-errors.js` - Generate 5xx errors
- `k6-api-errors.js` - Trigger Weather API errors
- `k6-hpa-scaling.js` - Trigger HPA scaling

### Shell Scripts

- `test-pod-crash.sh` - Force pod crash/restart
- `test-pod-down.sh` - Scale deployment to 0
- `test-high-cpu.sh` - Run k6 CPU load test
- `test-high-memory.sh` - Run k6 memory test
- `test-http-errors.sh` - Run k6 error generation
- `run-all-tests.sh` - Run all tests sequentially

## Monitoring Alerts

### View Prometheus Alerts

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Open http://localhost:9090/alerts
```

### View AlertManager

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
# Open http://localhost:9093
```

### View Webhook Logs

```bash
kubectl logs -n monitoring -l app=webhook-receiver -f
```

### Check Discord

Alerts should appear in your Discord channel configured in the webhook receiver.

## Test Details

### 1. High CPU Test

**Target Alert:** `WeatherMapHighCPU`

- Threshold: CPU > 80% of limit for 5 minutes
- Method: Sustained high-concurrency requests

```bash
./test-high-cpu.sh
```

### 2. High Memory Test

**Target Alert:** `WeatherMapHighMemory`

- Threshold: Memory > 80% of limit for 5 minutes
- Method: Sustained requests to accumulate memory

```bash
./test-high-memory.sh
```

### 3. Pod Crash Test

**Target Alert:** `WeatherMapPodCrashing`

- Threshold: Restart rate > 0 in last 5 minutes
- Method: Force delete pod

```bash
./test-pod-crash.sh
```

### 4. Pod Down Test

**Target Alert:** `WeatherMapPodNotReady`

- Threshold: Pod not Running/Succeeded for 5 minutes
- Method: Scale deployment to 0

```bash
./test-pod-down.sh
```

### 5. HTTP 5xx Error Test

**Target Alert:** `WeatherMapHigh5xxRate`

- Threshold: 5xx rate > 0.05 req/s for 2 minutes
- Method: Send requests to non-existent endpoints

```bash
./test-http-errors.sh
```

### 6. Weather API Error Test

**Target Alert:** `WeatherAPIHighErrorRate`

- Threshold: Error rate > 10% for 2 minutes
- Method: Send invalid city names

```bash
./test-api-errors.sh
```

### 7. HPA Scaling Test

**Target Alert:** `WeatherMapHPAScaling`

- Threshold: Replica count changes
- Method: Generate sustained load

```bash
./test-hpa-scaling.sh
```

## Expected Timeline

| Alert            | Trigger Time | Alert Fires After | Total Time |
| ---------------- | ------------ | ----------------- | ---------- |
| PodCrashing      | Immediate    | 1 minute          | ~1-2 min   |
| PodNotReady      | Immediate    | 5 minutes         | ~5-6 min   |
| HighCPU          | 2-3 minutes  | 5 minutes         | ~7-8 min   |
| HighMemory       | 2-3 minutes  | 5 minutes         | ~7-8 min   |
| High5xxRate      | Immediate    | 2 minutes         | ~2-3 min   |
| APIHighErrorRate | Immediate    | 2 minutes         | ~2-3 min   |
| HPAScaling       | 1-2 minutes  | Immediate         | ~1-2 min   |

## Cleanup

After testing, restore normal state:

```bash
# Scale deployments back to normal
kubectl scale deployment -n weather-map weather-map-backend --replicas=2
kubectl scale deployment -n weather-map weather-map-frontend --replicas=2

# Wait for HPA to stabilize
kubectl get hpa -n weather-map -w
```

## Troubleshooting

### Alerts not firing

1. Check PrometheusRule is loaded:

```bash
kubectl get prometheusrule -n monitoring weather-map-alerts -o yaml
```

2. Check Prometheus targets are up:

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Visit http://localhost:9090/targets
```

3. Check metrics are being collected:

```bash
# Query Prometheus
# Visit http://localhost:9090/graph
# Try: kube_pod_container_status_restarts_total{namespace="weather-map"}
```

### Load test not generating enough load

- Increase VUs (virtual users) in k6 scripts
- Increase duration
- Check pod resource limits

### Services not accessible

```bash
# Port-forward backend
kubectl port-forward -n weather-map svc/weather-map-backend 3001:80

# Port-forward frontend
kubectl port-forward -n weather-map svc/weather-map-frontend 3000:80
```

## Notes

- Tests are designed to trigger alerts without causing actual service disruption
- Some tests require sustained load for several minutes
- Monitor Discord/webhook receiver for alert notifications
- Clean up after testing to avoid false alerts
