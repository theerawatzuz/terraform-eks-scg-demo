#!/bin/bash

# Master script to run all alert tests sequentially
# WARNING: This will take approximately 30-40 minutes to complete

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Weather Map Alert Testing Suite"
echo "=========================================="
echo ""
echo "This will run all alert tests sequentially."
echo "Estimated time: 30-40 minutes"
echo ""
echo "Tests to run:"
echo "  1. Pod Crash (2 min)"
echo "  2. HTTP Errors (4 min)"
echo "  3. API Errors (4 min)"
echo "  4. High CPU (8 min)"
echo "  5. High Memory (9 min)"
echo "  6. HPA Scaling (7 min)"
echo "  7. Pod Down (6 min)"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Create results directory
RESULTS_DIR="$SCRIPT_DIR/results"
mkdir -p "$RESULTS_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="$RESULTS_DIR/test-results-$TIMESTAMP.log"

echo "Results will be saved to: $RESULTS_FILE"
echo ""

# Function to run test and log results
run_test() {
    local test_name=$1
    local test_script=$2
    local wait_time=$3
    
    echo "" | tee -a "$RESULTS_FILE"
    echo "=========================================="  | tee -a "$RESULTS_FILE"
    echo "Running: $test_name" | tee -a "$RESULTS_FILE"
    echo "Time: $(date)" | tee -a "$RESULTS_FILE"
    echo "==========================================" | tee -a "$RESULTS_FILE"
    echo "" | tee -a "$RESULTS_FILE"
    
    if bash "$SCRIPT_DIR/$test_script" 2>&1 | tee -a "$RESULTS_FILE"; then
        echo "✅ $test_name completed successfully" | tee -a "$RESULTS_FILE"
    else
        echo "❌ $test_name failed" | tee -a "$RESULTS_FILE"
    fi
    
    if [ "$wait_time" -gt 0 ]; then
        echo "" | tee -a "$RESULTS_FILE"
        echo "⏳ Waiting $wait_time seconds before next test..." | tee -a "$RESULTS_FILE"
        sleep "$wait_time"
    fi
}

# Test 1: Pod Crash (quick test)
run_test "Pod Crash Test" "test-pod-crash.sh" 120

# Test 2: HTTP Errors
run_test "HTTP Errors Test" "test-http-errors.sh" 60

# Test 3: API Errors
run_test "API Errors Test" "test-api-errors.sh" 60

# Test 4: High CPU
run_test "High CPU Test" "test-high-cpu.sh" 120

# Test 5: High Memory
run_test "High Memory Test" "test-high-memory.sh" 120

# Test 6: HPA Scaling
run_test "HPA Scaling Test" "test-hpa-scaling.sh" 180

# Test 7: Pod Down (run last as it scales down)
run_test "Pod Down Test" "test-pod-down.sh" 0

echo "" | tee -a "$RESULTS_FILE"
echo "=========================================="  | tee -a "$RESULTS_FILE"
echo "All Tests Completed!" | tee -a "$RESULTS_FILE"
echo "Time: $(date)" | tee -a "$RESULTS_FILE"
echo "==========================================" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "📊 Test Summary" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"
echo "Results saved to: $RESULTS_FILE" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "🔍 Check alerts in Prometheus:" | tee -a "$RESULTS_FILE"
echo "  kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090" | tee -a "$RESULTS_FILE"
echo "  Open: http://localhost:9090/alerts" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "🔍 Check AlertManager:" | tee -a "$RESULTS_FILE"
echo "  kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093" | tee -a "$RESULTS_FILE"
echo "  Open: http://localhost:9093" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "📱 Check Discord for alert notifications" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "⚠️  CLEANUP REQUIRED:" | tee -a "$RESULTS_FILE"
echo "  kubectl scale deployment -n weather-map weather-map-backend --replicas=2" | tee -a "$RESULTS_FILE"
echo "  kubectl scale deployment -n weather-map weather-map-frontend --replicas=2" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

# Offer to restore deployments
echo ""
read -p "Restore deployments to normal state now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔄 Restoring deployments..."
    kubectl scale deployment -n weather-map weather-map-backend --replicas=2
    kubectl scale deployment -n weather-map weather-map-frontend --replicas=2
    echo "✅ Deployments restored"
fi

echo ""
echo "Done! 🎉"
