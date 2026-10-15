#!/usr/bin/env bash
# install.sh - Prometheus + Grafana + Alertmanager (kube-prometheus-stack) into namespace monitoring.
# Grafana's admin password is random, kept only in the grafana-admin Secret, never printed.
# Read it later with:
#   kubectl get secret grafana-admin -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl get secret grafana-admin -n monitoring >/dev/null 2>&1 ||
  kubectl create secret generic grafana-admin -n monitoring \
    --from-literal=admin-user=admin --from-literal=admin-password="$(openssl rand -hex 16)"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update >/dev/null
helm upgrade --install kps prometheus-community/kube-prometheus-stack --version 92.1.0 \
  -n monitoring -f monitoring/kube-prometheus-stack-values.yaml --wait --timeout 15m
kubectl get pods -n monitoring
