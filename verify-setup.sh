#!/bin/bash

# =============================================================================
# Verification Script for macmagik-docker-k8s-bootstrap
# =============================================================================
# 
# This script verifies that all components are properly installed and
# accessible after running setup-ingress.sh. Use this to confirm your
# environment is working correctly.
# 
# Usage:
#   ./verify-setup.sh
# 
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test URL accessibility
test_url() {
    local url="$1"
    local expected_name="$2"
    local timeout=10
    
    log_info "Testing $expected_name: $url"
    
    if response=$(curl -k -s -w "%{http_code}" -m $timeout "$url" 2>/dev/null); then
        status_code="${response: -3}"
        
        if [[ "$status_code" =~ ^[23][0-9][0-9]$ ]]; then
            log_success "✅ $expected_name accessible (HTTP $status_code)"
            return 0
        else
            log_error "❌ $expected_name returned HTTP $status_code"
            return 1
        fi
    else
        log_error "❌ $expected_name not accessible (connection failed)"
        return 1
    fi
}

# Test DNS resolution
test_dns() {
    local hostname="$1"
    local expected_name="$2"
    
    log_info "Testing DNS resolution for $expected_name: $hostname"
    
    if grep -q "$hostname" /etc/hosts 2>/dev/null; then
        log_success "✅ $expected_name DNS resolution working"
        return 0
    else
        log_warning "⚠️  $expected_name not found in /etc/hosts"
        return 1
    fi
}

# Test Kubernetes resources
test_k8s_resources() {
    local namespace="$1"
    local resource_type="$2"
    local expected_name="$3"
    
    log_info "Checking $expected_name in namespace $namespace"
    
    if kubectl get "$resource_type" -n "$namespace" >/dev/null 2>&1; then
        if [[ "$resource_type" == "pods" ]]; then
            running_pods=$(kubectl get pods -n "$namespace" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
            total_pods=$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | wc -l)
            
            if [[ $running_pods -gt 0 ]]; then
                log_success "✅ $expected_name ($running_pods/$total_pods pods running)"
                return 0
            else
                log_error "❌ $expected_name (no pods running)"
                return 1
            fi
        else
            log_success "✅ $expected_name resources found"
            return 0
        fi
    else
        log_error "❌ $expected_name not found"
        return 1
    fi
}

# Test certificate trust
test_certificate() {
    log_info "Checking certificate trust status"
    
    if security find-certificate -c "*.kubernetes.docker.internal" /Library/Keychains/System.keychain >/dev/null 2>&1; then
        log_success "✅ Wildcard certificate found in macOS keychain"
        return 0
    else
        log_error "❌ Certificate not found in keychain"
        return 1
    fi
}

# Main verification function
run_verification() {
    echo "==========================================="
    echo "🔍 macmagik-docker-k8s-bootstrap Verification"
    echo "==========================================="
    echo ""
    
    local test_count=0
    local pass_count=0
    
    # Test function wrapper
    run_test() {
        ((test_count++))
        if "$@"; then
            ((pass_count++))
        fi
        echo ""
    }
    
    # Core Infrastructure Tests
    echo "🔐 Core Infrastructure"
    echo "---------------------"
    run_test test_k8s_resources "ingress-nginx" "pods" "NGINX Ingress Controller"
    run_test test_certificate
    run_test test_dns "echo.kubernetes.docker.internal" "Echo Service DNS"
    run_test test_url "https://echo.kubernetes.docker.internal/" "Echo Service"
    
    # Monitoring Stack Tests
    if kubectl get namespace monitoring >/dev/null 2>&1; then
        echo "📊 Monitoring Stack"
        echo "------------------"
        run_test test_k8s_resources "monitoring" "pods" "Monitoring Stack"
        run_test test_dns "prometheus.kubernetes.docker.internal" "Prometheus DNS"
        run_test test_dns "grafana.kubernetes.docker.internal" "Grafana DNS"
        run_test test_dns "alertmanager.kubernetes.docker.internal" "AlertManager DNS"
        run_test test_url "https://prometheus.kubernetes.docker.internal/" "Prometheus"
        run_test test_url "https://grafana.kubernetes.docker.internal/" "Grafana"
        run_test test_url "https://alertmanager.kubernetes.docker.internal/" "AlertManager"
    else
        log_info "📊 Monitoring stack not installed (skipping monitoring tests)"
        echo ""
    fi
    
    # Jaeger Tests
    if kubectl get namespace observability >/dev/null 2>&1; then
        echo "🔍 Distributed Tracing"
        echo "--------------------"
        run_test test_k8s_resources "observability" "pods" "Jaeger Tracing"
        run_test test_dns "jaeger.kubernetes.docker.internal" "Jaeger DNS"
        run_test test_url "https://jaeger.kubernetes.docker.internal/" "Jaeger UI"
    else
        log_info "🔍 Jaeger tracing not installed (skipping Jaeger tests)"
        echo ""
    fi
    
    # Summary
    echo "========================================"
    echo "📋 Verification Summary"
    echo "========================================"
    
    if [[ $pass_count -eq $test_count ]]; then
        log_success "🎉 All tests passed! ($pass_count/$test_count)"
        echo ""
        echo "✨ Your environment is ready for development!"
        echo ""
        echo "🌐 Quick Access:"
        echo "   • Echo Test: https://echo.kubernetes.docker.internal/"
        
        if kubectl get namespace monitoring >/dev/null 2>&1; then
            echo "   • Prometheus: https://prometheus.kubernetes.docker.internal/"
            echo "   • Grafana: https://grafana.kubernetes.docker.internal/ (admin/admin123)"
            echo "   • AlertManager: https://alertmanager.kubernetes.docker.internal/"
        fi
        
        if kubectl get namespace observability >/dev/null 2>&1; then
            echo "   • Jaeger: https://jaeger.kubernetes.docker.internal/"
        fi
        
        echo ""
        echo "📚 Deploy examples:"
        echo "   kubectl apply -f examples/multi-service/"
        echo "   kubectl apply -f examples/spa-application/"
        
        return 0
    else
        log_error "❌ Some tests failed ($pass_count/$test_count passed)"
        echo ""
        echo "🔧 Troubleshooting:"
        echo "   1. Run: ./recovery.sh"
        echo "   2. Then: ./setup-ingress.sh"
        echo "   3. Check: ./TROUBLESHOOTING.md"
        
        return 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "kubectl cannot connect to cluster. Is Docker Desktop Kubernetes running?"
        exit 1
    fi
    
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_warning "This verification script is designed for macOS"
    fi
    
    log_success "Prerequisites check passed"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    run_verification
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi