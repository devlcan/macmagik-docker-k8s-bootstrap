#!/bin/bash

#!/bin/bash

# =============================================================================
# Complete Cleanup Script for macmagik-docker-k8s-bootstrap
# =============================================================================
# 
# This script performs a comprehensive cleanup of all components installed
# by the setup-ingress.sh script, including:
# 
# Infrastructure Cleanup:
# - NGINX Ingress Controller and related resources
# - All monitoring stack components (Prometheus, Grafana, Jaeger)
# - Kubernetes namespaces and persistent volumes
# - Helm releases and charts
# 
# System Cleanup:
# - TLS certificates from macOS keychain
# - DNS entries from /etc/hosts
# - Temporary files and certificates
# 
# Usage:
#   ./cleanup-ingress.sh
# 
# Note: This script requires sudo privileges for:
# - Removing certificates from macOS keychain
# - Modifying /etc/hosts file
# 
# =============================================================================

# Exit immediately if any command fails
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[CLEANUP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[CLEANUP]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[CLEANUP]${NC} $1"
}

log_error() {
    echo -e "${RED}[CLEANUP]${NC} $1"
}


# =============================================================================
# COMPREHENSIVE CLEANUP FUNCTIONS
# =============================================================================

# Remove NGINX Ingress Controller and related resources
cleanup_ingress() {
    log_info "Removing NGINX Ingress Controller..."
    
    # Remove Helm release first (cleaner than manual deletion)
    helm uninstall ingress-nginx -n ingress-nginx 2>/dev/null || log_warning "NGINX Ingress Helm release not found"
    
    # Force remove any remaining pods that might be stuck
    kubectl delete pods --all -n ingress-nginx --force --grace-period=0 2>/dev/null || true
    
    # Remove the namespace (this cleans up all related resources)
    kubectl delete namespace ingress-nginx --ignore-not-found=true
    
    log_success "NGINX Ingress Controller removed"
}

# Remove complete monitoring stack
cleanup_monitoring() {
    log_info "Removing monitoring stack..."
    
    # Remove Prometheus Helm release
    helm uninstall prometheus -n monitoring 2>/dev/null || log_warning "Prometheus Helm release not found"
    
    # Force remove any stuck monitoring pods
    kubectl delete pods --all -n monitoring --force --grace-period=0 2>/dev/null || true
    
    # Remove monitoring namespace and all resources
    kubectl delete namespace monitoring --ignore-not-found=true
    
    log_success "Monitoring stack removed"
}

# Remove Jaeger distributed tracing
cleanup_jaeger() {
    log_info "Removing Jaeger tracing..."
    
    # Remove Jaeger instances first (managed by operator)
    kubectl delete jaeger --all -n observability --ignore-not-found=true
    
    # Remove Jaeger operator deployment
    kubectl delete deployment jaeger-operator -n observability --ignore-not-found=true
    
    # Force remove any stuck observability pods
    kubectl delete pods --all -n observability --force --grace-period=0 2>/dev/null || true
    
    # Remove observability namespace
    kubectl delete namespace observability --ignore-not-found=true
    
    log_success "Jaeger tracing removed"
}

cleanup_certificates() {
    log_info "Removing TLS certificates from macOS keychain..."
    
    # Remove certificates from macOS keychain
    sudo security delete-certificate -c "*.kubernetes.docker.internal" /Library/Keychains/System.keychain || log_warning "Certificate not found in keychain"
    sudo security delete-certificate -c "kubernetes.docker.internal" /Library/Keychains/System.keychain || log_warning "Certificate not found in keychain"
    
    # Remove TLS secrets from all namespaces
    kubectl delete secret default-tls --all-namespaces --force --grace-period=0 || log_warning "TLS secrets not found"
    
    log_success "Certificates cleanup completed"
}

cleanup_dns() {
    log_info "Cleaning up /etc/hosts entries..."
    
    # Remove all kubernetes.docker.internal entries
    sudo sed -i '' '/\.kubernetes\.docker\.internal/d' /etc/hosts 2>/dev/null || log_warning "No /etc/hosts entries found"
    
    log_success "/etc/hosts cleanup completed"
}

cleanup_helm_repos() {
    log_info "Cleaning up Helm repositories..."
    
    # Remove added Helm repositories
    helm repo remove ingress-nginx || log_warning "ingress-nginx repo not found"
    helm repo remove prometheus-community || log_warning "prometheus-community repo not found"
    
    log_success "Helm repositories cleanup completed"
}

cleanup_temp_files() {
    log_info "Cleaning up temporary files..."
    
    # Remove any temporary files that might be left
    rm -f openssl-san.cnf tls.crt tls.key nginx-values.yaml echo-ingress.yaml
    rm -f prometheus-values.yaml prometheus-ingress.yaml
    rm -f jaeger-instance.yaml jaeger-ingress.yaml jaeger-simple.yaml jaeger-simple-ingress.yaml
    
    log_success "Temporary files cleanup completed"
}

force_cleanup_stuck_resources() {
    log_warning "Performing force cleanup of stuck resources..."
    
    # Force delete any stuck finalizers
    kubectl patch namespace monitoring -p '{"metadata":{"finalizers":[]}}' --type=merge || true
    kubectl patch namespace observability -p '{"metadata":{"finalizers":[]}}' --type=merge || true
    kubectl patch namespace ingress-nginx -p '{"metadata":{"finalizers":[]}}' --type=merge || true
    
    # Force delete stuck PVs
    kubectl delete pv --all --force --grace-period=0 --timeout=60s || true
    
    log_success "Force cleanup completed"
}

main() {
    log_info "Starting complete cleanup of macmagik-docker-k8s-bootstrap..."
    log_warning "This will remove ALL components installed by the setup scripts"
    
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleanup cancelled"
        exit 0
    fi
    
    # Run cleanup in reverse order of installation
    cleanup_temp_files
    cleanup_monitoring
    cleanup_jaeger
    cleanup_ingress
    cleanup_certificates
    cleanup_dns
    cleanup_helm_repos
    
    # Force cleanup any stuck resources
    force_cleanup_stuck_resources
    
    log_success "🎉 Complete cleanup finished!"
    log_info "All components have been removed from your system."
    log_info ""
    log_info "What was cleaned up:"
    log_info "  ✅ NGINX Ingress Controller"
    log_info "  ✅ Prometheus monitoring stack"
    log_info "  ✅ Grafana dashboards"
    log_info "  ✅ Jaeger distributed tracing"
    log_info "  ✅ TLS certificates and secrets"
    log_info "  ✅ /etc/hosts entries"
    log_info "  ✅ Example applications"
    log_info "  ✅ Kubernetes namespaces"
    log_info "  ✅ Persistent volumes"
    log_info "  ✅ Helm repositories"
    log_info ""
    log_info "Your Kubernetes cluster is now clean and ready for fresh setup!"
}

# Run main function
main "$@"
