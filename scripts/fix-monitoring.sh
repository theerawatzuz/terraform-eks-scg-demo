#!/bin/bash

# Emergency fix script for monitoring stack after node drain

set -e

echo "=========================================="
echo "Fixing Monitoring Stack"
echo "=========================================="
echo ""

# 1. Uncordon the drained node
echo "1️⃣ Uncordoning drained node..."
kubectl uncordon ip-10-0-10-103.ap-southeast-1.compute.internal 2>/dev/null || echo "Node already uncordoned or not found"
echo ""

# 2. Delete problematic nodes
echo "2️⃣ Deleting problematic nodes..."
kubectl delete node ip-10-0-10-103.ap-southeast-1.compute.internal --ignore-not-found=true
kubectl delete node ip-10-0-10-133.ap-southeast-1.compute.internal --ignore-not-found=true
echo ""

# 3. Check current monitoring pods status
echo "3️⃣ Current monitoring pods status:"
kubectl get pods -n monitoring -o wide
echo ""

# 4. Force restart Prometheus
echo "4️⃣ Restarting Prometheus..."
kubectl delete pod -n monitoring -l app.kubernetes.io/name=prometheus --force --grace-period=0 2>/dev/null || echo "No Prometheus pods to delete"
echo ""

# 5. Force restart Grafana
echo "5️⃣ Restarting Grafana..."
kubectl delete pod -n monitoring -l app.kubernetes.io/name=grafana --force --grace-period=0 2>/dev/null || echo "No Grafana pods to delete"
echo ""

# 6. Wait for pods to come back
echo "6️⃣ Waiting for pods to restart (30 seconds)..."
sleep 30
echo ""

# 7. Check final status
echo "7️⃣ Final monitoring pods status:"
kubectl get pods -n monitoring -o wide
echo ""

# 8. Check nodes
echo "8️⃣ Current nodes:"
kubectl get nodes
echo ""

# 9. Check if Prometheus is accessible
echo "9️⃣ Checking Prometheus StatefulSet:"
kubectl get statefulset -n monitoring
echo ""

# 10. Show recent events
echo "🔟 Recent events in monitoring namespace:"
kubectl get events -n monitoring --sort-by='.lastTimestamp' | tail -10
echo ""

echo "=========================================="
echo "Fix Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Wait 2-3 minutes for pods to fully start"
echo "2. Check Prometheus: kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
echo "3. Check Grafana: kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
echo ""
echo "If still not working, check pod logs:"
echo "  kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus"
echo "  kubectl logs -n monitoring -l app.kubernetes.io/name=grafana"
