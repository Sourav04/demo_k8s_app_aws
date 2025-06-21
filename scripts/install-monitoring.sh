#!/bin/bash

# Script to install Prometheus Operator and enable ServiceMonitor functionality
# This script should be run after the cluster is ready

set -e

echo "Installing Prometheus Operator..."

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install Prometheus Operator using Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus Operator
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.probeSelectorNilUsesHelmValues=false \
  --wait --timeout=600s

echo "Prometheus Operator installed successfully!"

# Wait for CRDs to be available
echo "Waiting for ServiceMonitor CRD to be available..."
kubectl wait --for=condition=established --timeout=300s crd/servicemonitors.monitoring.coreos.com

echo "ServiceMonitor CRD is now available!"
echo "You can now enable ServiceMonitor in your Helm chart by setting:"
echo "  monitoring.serviceMonitor.enabled=true" 