#!/usr/bin/env bash
# local-cluster.sh - a free local Kubernetes cluster for ReadCycle: kind + metrics-server
# (for the HPA) + ingress-nginx. Idempotent: re-running skips what already exists.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER=readcycle

kind get clusters | grep -qx "$CLUSTER" ||
  kind create cluster --config "$HERE/kind-config.yaml" --wait 180s

# Docker Hub limits anonymous pulls per IP; pull docker.io images through Google's
# public mirror first and fall back to Docker Hub itself.
for node in $(kind get nodes --name "$CLUSTER"); do
  docker exec "$node" mkdir -p /etc/containerd/certs.d/docker.io
  printf 'server = "https://registry-1.docker.io"\n\n[host."https://mirror.gcr.io"]\n  capabilities = ["pull", "resolve"]\n' |
    docker exec -i "$node" cp /dev/stdin /etc/containerd/certs.d/docker.io/hosts.toml
done

# metrics-server: CPU/memory metrics for the HPA and kubectl top (kind kubelets use self-signed certs)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.0/components.yaml
kubectl -n kube-system patch deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' 2>/dev/null || true

# ingress-nginx, kind flavour: listens on the node's ports 80/443 (= 8088/8443 on the laptop)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.15.1/deploy/static/provider/kind/deploy.yaml

kubectl -n kube-system rollout status deployment/metrics-server --timeout=300s
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=300s
kubectl get nodes -o wide
