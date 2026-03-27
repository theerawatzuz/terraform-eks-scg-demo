#!/bin/bash

# Test script to trigger WeatherMapHighCPU alert using k6
# Alert threshold: CPU > 80% of limit for 5 minutes

set -e

echo "=========================================="
echo "Testing: WeatherMapHighCPU Alert"
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

echo "📊 Current CPU usage:"
kubectl top pods -n weather-map -l app=weather-map-backend 2>/dev/null || echo "Metrics not available yet"
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
echo "   Duration: ~8 minutes (30s ramp + 7min sustained + 30s ramp down)"
echo "   VUs: 50 concurrent users"
echo "   Target: Generate high CPU load"
echo ""

k6 run --env BASE_URL=http://localhost:3001 k6-high-cpu.js

echo ""
echo "✅ Load test completed!"
echo ""
echo "📊 Check current CPU usage:"
echo "  kubectl top pods -n weather-map -l app=weather-map-backend"
echo ""
echo "Expected behavior:"
echo "  - CPU usage should exceed 80% during test"
echo "  - Alert 'WeatherMapHighCPU' should fire after 5 minutes of high usage"
echo ""
echo "Monitor alerts:"
echo "  kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
echo "  Open: http://localhost:9090/alerts"
