#!/bin/bash

# =============================================================================
# Jaeger Distributed Tracing Installation
# =============================================================================
# 
# This script installs Jaeger for distributed tracing in microservices
# architectures, providing:
# 
# Components Installed:
# - Jaeger Operator: Manages Jaeger deployments in Kubernetes
# - Jaeger All-in-One: Complete tracing solution with UI
# - Collector: Receives and processes trace data
# - Query Service: Provides API and UI for trace retrieval
# 
# Features:
# - In-memory storage (suitable for development)
# - Configurable trace retention (50,000 traces)
# - Resource limits for stable operation
# - Ingress configuration with trusted TLS certificates
# - Ready for OpenTelemetry integration
# 
# Access URL (after installation):
# - Jaeger UI: https://jaeger.kubernetes.docker.internal/
# 
# Trace Collection Endpoints:
# - HTTP: http://jaeger-prod-collector.observability.svc.cluster.local:14268/api/traces
# - gRPC: jaeger-prod-collector.observability.svc.cluster.local:14250
# - Agent: jaeger-prod-agent.observability.svc.cluster.local:6831
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


install_jaeger() {
    log_info "Installing Jaeger distributed tracing..."
    
    # Create observability namespace
    kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
    
    # Copy TLS certificate to observability namespace
    kubectl get secret default-tls -n ingress-nginx -o yaml | \
        sed 's/namespace: ingress-nginx/namespace: observability/' | \
        kubectl apply -f -
    
    # Install Jaeger Operator CRDs first
    log_info "Installing Jaeger Operator CRDs..."
    kubectl apply -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/v1.51.0/deploy/crds/jaegertracing.io_jaegers_crd.yaml || log_warning "CRDs may already exist"
    
    # Install Jaeger Operator
    log_info "Installing Jaeger Operator..."
    kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.51.0/jaeger-operator.yaml -n observability || log_warning "Some Jaeger operator resources already exist"
    
    # Wait for operator to be ready
    log_info "Waiting for Jaeger Operator to be ready..."
    sleep 20
    kubectl wait --for=condition=Available deployment/jaeger-operator -n observability --timeout=300s || {
        log_warning "Jaeger operator taking longer than expected, checking status..."
        kubectl get pods -n observability
    }
    
    # Verify CRDs are ready before creating Jaeger instance
    log_info "Verifying Jaeger CRDs are available..."
    kubectl get crd jaegers.jaegertracing.io > /dev/null || {
        log_error "Jaeger CRDs not found. Installation failed."
        return 1
    }
    
    # Create Jaeger instance with validation disabled initially
    log_info "Creating production Jaeger deployment..."
    kubectl apply -f scripts/jaeger-instance.yaml --validate=false || {
        log_error "Failed to create Jaeger instance"
        return 1
    }
    
    # Wait for Jaeger to be ready
    log_info "Waiting for Jaeger to be ready..."
    sleep 30
    
    # Check if Jaeger pods are running
    if ! kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=jaeger -n observability --timeout=300s; then
        log_warning "Jaeger pods may still be starting. Checking status..."
        kubectl get pods -n observability
        kubectl describe jaeger jaeger-prod -n observability | tail -20
    fi
    
    # Create Jaeger Ingress
    log_info "Creating Jaeger ingress..."
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jaeger-ingress
  namespace: observability
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - jaeger.kubernetes.docker.internal
    secretName: default-tls
  rules:
  - host: jaeger.kubernetes.docker.internal
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: jaeger-prod-query
            port:
              number: 16686
EOF
    
    # Update /etc/hosts
    log_info "Updating /etc/hosts for Jaeger..."
    sudo sed -i '' "/127.0.0.1 jaeger.kubernetes.docker.internal/d" /etc/hosts 2>/dev/null || true
    echo "127.0.0.1 jaeger.kubernetes.docker.internal" | sudo tee -a /etc/hosts > /dev/null
    
    log_success "Jaeger installed successfully!"
    log_info "Access URL: https://jaeger.kubernetes.docker.internal/"
    log_info "Collector endpoint: http://jaeger-prod-collector.observability.svc.cluster.local:14268/api/traces"
    log_info "Agent endpoint: jaeger-prod-agent.observability.svc.cluster.local:6831"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_jaeger
fi