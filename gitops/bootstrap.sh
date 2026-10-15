#!/usr/bin/env bash
# bootstrap.sh - one-time GitOps setup of a cluster (local kind or EKS):
#   the readcycle namespace, a random database password Secret (never printed, never in Git),
#   Argo CD, and the Application that makes Argo CD deploy helm/readcycle from GitHub.
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl apply -f k8s/namespace.yaml
kubectl get secret readcycle-db -n readcycle >/dev/null 2>&1 ||
  kubectl create secret generic readcycle-db -n readcycle --from-literal=password="$(openssl rand -hex 16)"

helm repo add argo https://argoproj.github.io/argo-helm --force-update >/dev/null
helm upgrade --install argocd argo/argo-cd --version 10.10.0 -n argocd --create-namespace \
  -f gitops/argocd/values.yaml --wait --timeout 10m

kubectl apply -f gitops/argocd/readcycle-app.yaml
echo "Argo CD now deploys helm/readcycle from https://github.com/RatneshVaibhav/readcycle (branch main)"
