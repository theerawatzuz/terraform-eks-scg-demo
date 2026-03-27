#!/bin/bash

# Test script to trigger WeatherMapPodCrashing alert
# Alert threshold: Pod restart rate > 0 in last 5 minutes

set -e

echo "=========================================="
echo "Testing: WeatherMapPodCrashing Alert"
echo "=========================================="
echo ""

# Check if namespace exists
if ! kubectl get namespace weather-map &> /dev/null; then
    echo "❌ Error: weather-map namespace not found"
    exit 1
fi

# Get backend pods
echo "📋 Current backend pods:"
kubectl get pods -n weather-map -l app=weather-map-backend
echo ""

# Force delete a pod to trigger restart
echo "🔥 Force deleting a backend pod to trigger crash/restart..."
POD=$(kubectl get pods -n weather-map -l app=weather-map-backend -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD" ]; then
    echo "❌ Error: No backend pods found"
    exit 1
fi

echo "Deleting pod: $POD"
kubectl delete pod -n weather-map "$POD" --force --grace-period=0

echo ""
echo "⏳ Waiting for pod to restart..."
sleep 5

echo ""
echo "📋 Pod status after deletion:"
kubectl get pods -n weather-map -l app=weather-map-backend
echo ""

echo "📊 Checking restart count:"
kubectl get pods -n weather-map -l app=weather-map-backend -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].restartCount}{"\n"}{end}'
echo ""

echo "✅ Pod crash triggered!"
echo ""
echo "Expected behavior:"
echo "  - Pod should restart immediately"
echo "  - Restart count should increment"
echo "  - Alert 'WeatherMapPodCrashing' should fire after 1 minute"
echo ""
echo "Monitor alerts:"
echo "  kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
echo "  Open: http://localhost:9090/alerts"
echo ""
echo "Check webhook logs:"
echo "  kubectl logs -n monitoring -l app=webhook-receiver -f"
