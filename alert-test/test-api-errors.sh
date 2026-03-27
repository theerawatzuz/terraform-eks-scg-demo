#!/bin/bash

# Test script to trigger WeatherAPIHighErrorRate alert using k6
# Alert threshold: Weather API error rate > 10% for 2 minutes

set -e

echo "=========================================="
echo "Testing: WeatherAPIHighErrorRate Alert"
echo "=========================================="
echo ""

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
    echo "❌ Error: k6 is not installed"
    echo "Install: brew install k6"
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace weather-map &> /dev/null; then
    echo "❌ Error: weather-map namespace not found"
    exit 1
fi

echo "📋 Current backend pods:"
kubectl get pods -n weather-map -l app=weather-map-backend
echo ""

# Setup port-forward
echo "🔌 Setting up port-forward to backend service..."
kubectl port-forward -n weather-map svc/weather-map-backend 3001:80 &
PF_PID=$!

# Wait for port-forward to be ready
sleep 3

# Cleanup function
cleanup() {
    echo ""
    echo "🧹 Cleaning up..."
    kill $PF_PID 2>/dev/null || true
}
trap cleanup EXIT

# Test connection
echo "🔍 Testing connection..."
if ! curl -s http://localhost:3001/api/weather?city=Bangkok > /dev/null; then
    echo "❌ Error: Cannot connect to backend service"
    exit 1
fi

echo "✅ Connection successful!"
echo ""

# Run k6 load test
echo "🚀 Starting k6 load test..."
echo "   Duration: ~3.5 minutes (10s ramp + 3min sustained + 10s ramp down)"
echo "   VUs: 15 concurrent users"
echo "   Target: Generate Weather API errors (30% invalid cities)"
echo ""

k6 run --env BASE_URL=http://localhost:3001 k6-api-errors.js

echo ""
echo "✅ Load test completed!"
echo ""
echo "Expected behavior:"
echo "  - ~30% of requests use invalid city names"
echo "  - Weather API error rate should exceed 10%"
echo "  - Alert 'WeatherAPIHighErrorRate' should fire after 2 minutes"
echo ""
echo "Monitor alerts:"
echo "  kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
echo "  Open: http://localhost:9090/alerts"
echo ""
echo "Check Prometheus metrics:"
echo "  Query: rate(weather_api_calls_total{status=\"error\"}[5m]) / rate(weather_api_calls_total[5m])"
