#!/bin/bash

# Test script to trigger WeatherMapPodNotReady alert
# Alert threshold: Pod not in Running/Succeeded state for 5 minutes

set -e

echo "=========================================="
echo "Testing: WeatherMapPodNotReady Alert"
echo "=========================================="
echo ""

# Check if namespace exists
if ! kubectl get namespace weather-map &> /dev/null; then
    echo "❌ Error: weather-map namespace not found"
    exit 1
fi

echo "📋 Current deployment status:"
kubectl get deployment -n weather-map weather-map-backend
echo ""

# Scale down to 0 to simulate pod down
echo "⬇️  Scaling backend deployment to 0 replicas..."
kubectl scale deployment -n weather-map weather-map-backend --replicas=0

echo ""
echo "⏳ Waiting for pods to terminate..."
sleep 10

echo ""
echo "📋 Pod status (should be empty or terminating):"
kubectl get pods -n weather-map -l app=weather-map-backend
echo ""

echo "✅ Pods scaled down!"
echo ""
echo "Expected behavior:"
echo "  - All backend pods should be terminated"
echo "  - Alert 'WeatherMapPodNotReady' should fire after 5 minutes"
echo ""
echo "⏰ Waiting 5 minutes for alert to fire..."
echo "   (You can Ctrl+C and check manually)"
echo ""

# Optional: wait for alert
for i in {1..5}; do
    echo "   ⏳ $i/5 minutes elapsed..."
    sleep 60
done

echo ""
echo "🔔 Alert should be firing now!"
echo ""
echo "Monitor alerts:"
echo "  kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
echo "  Open: http://localhost:9090/alerts"
echo ""
echo "⚠️  CLEANUP: Don't forget to scale back up:"
echo "  kubectl scale deployment -n weather-map weather-map-backend --replicas=2"
