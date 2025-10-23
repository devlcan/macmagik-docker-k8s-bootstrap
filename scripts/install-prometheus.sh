#!/bin/bash

# =============================================================================
# Prometheus Monitoring Stack Installation
# =============================================================================
# 
# This script installs a complete monitoring solution for Kubernetes including:
# 
# Components Installed:
# - Prometheus: Metrics collection, storage, and alerting engine
# - Grafana: Visualization dashboards with pre-built Kubernetes monitoring
# - AlertManager: Alert routing, grouping, and notification management
# - Node Exporter: System metrics collection from cluster nodes
# - Kube State Metrics: Kubernetes object metrics
# 
# Features:
# - 30-day metric retention for historical analysis
# - Pre-configured Kubernetes dashboards
# - Persistent storage for metrics and configurations
# - Ingress configuration with trusted TLS certificates
# - Default admin credentials (admin/admin123)
# 
# Access URLs (after installation):
# - Prometheus: https://prometheus.kubernetes.docker.internal/
# - Grafana: https://grafana.kubernetes.docker.internal/
# - AlertManager: https://alertmanager.kubernetes.docker.internal/
# 
# =============================================================================

# Exit immediately if any command fails
set -e

# Source logging functions from main setup script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Running standalone - source the functions
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=../setup-ingress.sh disable=SC1091
    source "${SCRIPT_DIR}/../setup-ingress.sh" --source-only 2>/dev/null || {
        # Fallback logging if sourcing fails
        log_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
        log_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
        log_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1"; }
        log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }
    }
fi


install_prometheus() {
    log_info "Installing Prometheus monitoring stack..."
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Copy TLS certificate to monitoring namespace
    kubectl get secret default-tls -n ingress-nginx -o yaml | \
        sed 's/namespace: ingress-nginx/namespace: monitoring/' | \
        kubectl apply -f -
    
    # Create Prometheus values file
    cat <<EOF > prometheus-values.yaml
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: hostpath
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
    additionalScrapeConfigs:
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)

grafana:
  enabled: true
  adminPassword: admin123
  persistence:
    enabled: true
    storageClassName: hostpath
    size: 5Gi
  grafana.ini:
    server:
      root_url: https://grafana.kubernetes.docker.internal/
    security:
      allow_embedding: true
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default
  dashboards:
    default:
      kubernetes-cluster:
        gnetId: 7249
        revision: 1
        datasource: Prometheus
      kubernetes-pods:
        gnetId: 6417
        revision: 1
        datasource: Prometheus
      nginx-ingress:
        gnetId: 9614
        revision: 1
        datasource: Prometheus

alertmanager:
  enabled: true
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: hostpath
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 2Gi

kubeStateMetrics:
  enabled: true

nodeExporter:
  enabled: true

prometheusOperator:
  enabled: true
EOF

    # Install kube-prometheus-stack
    log_info "Installing kube-prometheus-stack..."
    helm upgrade --install prometheus kube-prometheus-stack \
        --repo https://prometheus-community.github.io/helm-charts \
        --namespace monitoring \
        --create-namespace \
        -f prometheus-values.yaml \
        --wait --timeout=600s

    # Create Ingress for Prometheus
    cat <<EOF > prometheus-ingress.yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - prometheus.kubernetes.docker.internal
    secretName: default-tls
  rules:
  - host: prometheus.kubernetes.docker.internal
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-kube-prometheus-prometheus
            port:
              number: 9090
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - grafana.kubernetes.docker.internal
    secretName: default-tls
  rules:
  - host: grafana.kubernetes.docker.internal
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-grafana
            port:
              number: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: alertmanager-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - alertmanager.kubernetes.docker.internal
    secretName: default-tls
  rules:
  - host: alertmanager.kubernetes.docker.internal
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-kube-prometheus-alertmanager
            port:
              number: 9093
EOF

    kubectl apply -f prometheus-ingress.yaml
    
    # Update /etc/hosts
    log_info "Updating /etc/hosts for Prometheus services..."
    echo "127.0.0.1 prometheus.kubernetes.docker.internal" | sudo tee -a /etc/hosts
    echo "127.0.0.1 grafana.kubernetes.docker.internal" | sudo tee -a /etc/hosts
    echo "127.0.0.1 alertmanager.kubernetes.docker.internal" | sudo tee -a /etc/hosts
    
    # Wait for pods to be ready
    log_info "Waiting for Prometheus components to be ready..."
    kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s || log_warning "Prometheus pods may still be starting"
    kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s || log_warning "Grafana pods may still be starting"
    
    # Clean up
    rm -f prometheus-values.yaml prometheus-ingress.yaml
    
    log_success "Prometheus stack installed successfully!"
    log_info "Access URLs:"
    log_info "  • Prometheus: https://prometheus.kubernetes.docker.internal/"
    log_info "  • Grafana: https://grafana.kubernetes.docker.internal/ (admin/admin123)"
    log_info "  • AlertManager: https://alertmanager.kubernetes.docker.internal/"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_prometheus
fi