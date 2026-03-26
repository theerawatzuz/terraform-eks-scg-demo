#!/bin/bash
set -e

echo "🧪 Testing Prometheus Alerts & Discord Webhook"
echo "=============================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "\n${YELLOW}1. Checking webhook receiver...${NC}"
kubectl get pods -n monitoring -l app=webhook-receiver

echo -e "\n${YELLOW}2. Checking PrometheusRules...${NC}"
kubectl get prometheusrules weather-map-alerts -n monitoring

echo -e "\n${YELLOW}3. Testing webhook endpoint...${NC}"
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -- \
  curl -X POST http://webhook-receiver.monitoring.svc.cluster.local:8080/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "alerts": [{
      "status": "firing",
      "labels": {
        "alertname": "TestAlert",
        "severity": "info",
        "component": "test"
      },
      "annotations": {
        "summary": "This is a test alert",
        "description": "Testing Discord webhook integration"
      }
    }]
  }'

echo -e "\n${YELLOW}4. Checking webhook receiver logs...${NC}"
kubectl logs -n monitoring -l app=webhook-receiver --tail=20

echo -e "\n${GREEN}✅ Test completed! Check your Discord channel for the test alert.${NC}"

echo -e "\n${YELLOW}5. To trigger real alerts:${NC}"
echo "   - High CPU: kubectl run -it --rm load-generator --image=busybox --restart=Never -- /bin/sh -c 'while true; do :; done'"
echo "   - Pod crash: kubectl delete pod -n weather-map -l app=weather-map-backend --force"
echo "   - HPA scale: kubectl run -it --rm load-generator --image=busybox --restart=Never -- /bin/sh -c 'while true; do wget -q -O- http://weather-map-backend.weather-map/health; done'"

echo -e "\n${YELLOW}6. View alerts in Prometheus:${NC}"
echo "   kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
echo "   Open: http://localhost:9090/alerts"

echo -e "\n${YELLOW}7. View Alertmanager:${NC}"
echo "   kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093"
echo "   Open: http://localhost:9093"
