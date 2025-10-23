#!/bin/bash

# =============================================================================
# Quick Recovery Script for Resource Conflicts
# =============================================================================
# 
# This script handles common installation conflicts and stuck resources that
# can occur during Kubernetes deployments, particularly:
# 
# Common Issues Resolved:
# - TLS secret conflicts ("object has been modified" errors)
# - Stuck namespaces in "Terminating" state
# - Finalizers preventing resource deletion
# - Helm release conflicts
# - Persistent volume cleanup
# 
# When to Use:
# - Setup script fails with resource conflict errors
# - Pods or namespaces stuck in terminating state
# - "AlreadyExists" or "object modified" errors
# - Before retrying a failed installation
# 
# Usage:
#   ./recovery.sh
#   ./setup-ingress.sh  # Retry setup after recovery
# 
# =============================================================================

# Exit immediately if any command fails
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[RECOVERY]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[RECOVERY]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[RECOVERY]${NC} $1"
}

log_info "Starting quick recovery for stuck resources..."

# Force remove all TLS secrets
log_info "Removing TLS secrets from all namespaces..."
kubectl delete secret default-tls --all-namespaces --force --grace-period=0 || true

# Force remove stuck namespaces
log_info "Cleaning up stuck namespaces..."
for ns in ingress-nginx monitoring observability; do
    if kubectl get namespace $ns >/dev/null 2>&1; then
        log_info "Cleaning up namespace: $ns"
        kubectl delete namespace $ns --force --grace-period=0 --timeout=30s || true
        kubectl patch namespace $ns -p '{"metadata":{"finalizers":[]}}' --type=merge || true
    fi
done

# Clean up any stuck ingress resources
log_info "Cleaning up ingress resources..."
kubectl delete ingress --all --force --grace-period=0 || true

# Clean up test deployments
log_info "Cleaning up test applications..."
kubectl delete deployment echo --force --grace-period=0 || true
kubectl delete service echo --force --grace-period=0 || true

# Remove helm releases if stuck
log_info "Cleaning up helm releases..."
helm uninstall ingress-nginx -n ingress-nginx || true
helm uninstall prometheus -n monitoring || true

# Clean up persistent volumes
log_info "Cleaning up persistent volumes..."
kubectl delete pv --all --force --grace-period=0 || true

# Clean up any remaining finalizers
log_info "Removing finalizers from stuck resources..."
kubectl get all --all-namespaces -o json | jq -r '.items[] | select(.metadata.finalizers != null) | "\(.kind)/\(.metadata.name) -n \(.metadata.namespace)"' | while read -r resource; do
    kubectl patch "$resource" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
done

log_success "Recovery completed!"
log_info "You can now run the setup script again:"
log_info "  ./setup-ingress.sh"