#!/bin/bash

CLUSTER_NAME=${1:-kind}

# Idempotent Kind cluster creation
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Creating Kind cluster: ${CLUSTER_NAME}..."
    kind create cluster --name "${CLUSTER_NAME}" --config=kind-config.yaml
else
    echo "Kind cluster ${CLUSTER_NAME} already exists, skipping creation."
    kubectl cluster-info --context "kind-${CLUSTER_NAME}"
fi

# Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Helm repos
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Idempotent VPA installation
echo "Upgrading/Installing VPA..."
helm upgrade --install vpa autoscaler/vertical-pod-autoscaler --namespace kube-system

# Idempotent Prometheus installation
echo "Upgrading/Installing Prometheus Operator..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace
