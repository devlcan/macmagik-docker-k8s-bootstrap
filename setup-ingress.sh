#!/bin/bash

# =============================================================================
# macmagik-docker-k8s-bootstrap - Complete Local Kubernetes Development Setup
# =============================================================================
# 
# This script creates a production-ready local Kubernetes development environment
# featuring:
# 
# Core Infrastructure:
# - NGINX Ingress Controller optimized for Docker Desktop
# - Trusted wildcard TLS certificates (*.kubernetes.docker.internal)
# - Automatic macOS keychain integration
# - DNS configuration via /etc/hosts
# 
# Optional Monitoring Stack:
# - Prometheus: Metrics collection and storage
# - Grafana: Visualization dashboards with Kubernetes monitoring
# - AlertManager: Alert routing and management  
# - Jaeger: Distributed tracing for microservices
# 
# Usage:
#   ./setup-ingress.sh              # Install with monitoring
#   ./setup-ingress.sh false        # Install core only (no monitoring)
# 
# Requirements:
# - macOS with Docker Desktop + Kubernetes enabled
# - Helm 3.x installed
# - Admin privileges for certificate installation
# 
# =============================================================================

# Exit immediately if any command fails
set -e

# Configuration
MONITORING=${1:-"true"}  # Set to "false" to skip monitoring setup
VERBOSE=${VERBOSE:-"false"}

# Colors for output\nRED='\\033[0;31m'\nGREEN='\\033[0;32m'\nYELLOW='\\033[1;33m'\nBLUE='\\033[0;34m'\nNC='\\033[0m' # No Color

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

# Exit early if sourced for functions only
if [[ "${1:-}" == "--source-only" ]]; then
    # shellcheck disable=SC2317
    return 0 2>/dev/null || exit 0
fi

# =============================================================================
# LOGGING AND UTILITY FUNCTIONS
# =============================================================================



# Update /etc/hosts with new domain entries
# Args: $1 = hostname to add
update_hosts() {
    local hostname="$1"
    # Remove existing entry if present, then add new one
    sudo sed -i '' "/127.0.0.1 $hostname/d" /etc/hosts 2>/dev/null || true
    echo "127.0.0.1 $hostname" | sudo tee -a /etc/hosts > /dev/null
}

# =============================================================================
# PREREQUISITE VALIDATION
# =============================================================================

# Verify all required tools and environment are available
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if kubectl is installed and configured
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl."
        exit 1
    fi
    
    # Verify kubectl can connect to Kubernetes cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "kubectl cannot connect to Kubernetes cluster. Please ensure Docker Desktop Kubernetes is running."
        exit 1
    fi
    
    # Check if Helm is installed
    if ! command -v helm &> /dev/null; then
        log_error "Helm is not installed. Please install Helm 3.x."
        exit 1
    fi
    
    # Verify we're running on macOS (required for keychain integration)
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS. Other platforms are not supported."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Check prerequisites first
check_prerequisites

# Step 1: Generate self-signed certificate
log_info "Generating self-signed certificate for kubernetes.docker.internal..."
cat <<EOF > openssl-san.cnf
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
C = US
ST = Local
L = Local
O = Local
OU = Local
CN = *.kubernetes.docker.internal

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = kubernetes.docker.internal
DNS.2 = *.kubernetes.docker.internal
EOF

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -config openssl-san.cnf \
  -extensions req_ext

# Step 2: Install NGINX Ingress Controller first
log_info "Installing NGINX Ingress Controller..."
cat <<EOF > nginx-values.yaml
controller:
  service:
    type: LoadBalancer
  hostPort:
    enabled: true
    ports:
      http: 80
      https: 443
  nodeSelector:
    kubernetes.io/os: linux
  extraArgs:
    default-ssl-certificate: ingress-nginx/default-tls
EOF

# Create the ingress-nginx namespace first
log_info "Setting up ingress-nginx namespace..."
kubectl delete namespace ingress-nginx --ignore-not-found=true --timeout=60s || true
# Wait for namespace to be fully deleted
while kubectl get namespace ingress-nginx >/dev/null 2>&1; do
    log_info "Waiting for ingress-nginx namespace to be deleted..."
    sleep 2
done
kubectl create namespace ingress-nginx

# Step 3: Create Kubernetes secret for the certificate BEFORE installing ingress controller
log_info "Creating Kubernetes secret for the certificate..."
kubectl delete secret default-tls -n ingress-nginx --ignore-not-found=true
kubectl create secret tls default-tls --cert=tls.crt --key=tls.key -n ingress-nginx

# Now install the ingress controller with the default certificate configured
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx \
  -f nginx-values.yaml

# Wait for NGINX Ingress Controller to be ready
log_info "Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx --timeout=300s

# Step 4: Trust the certificate on macOS
log_info "Adding certificate to macOS keychain (requires sudo)..."
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain tls.crt

# Step 5: Deploy a test application and Ingress
log_info "Deploying test application and Ingress..."
kubectl create deployment echo --image=ealen/echo-server:latest --dry-run=client -o yaml | kubectl apply -f -
kubectl expose deployment echo --port=80 --target-port=80 --dry-run=client -o yaml | kubectl apply -f -

# Copy the TLS secret to default namespace for the ingress
log_info "Copying TLS secret to default namespace..."
kubectl delete secret default-tls -n default --ignore-not-found=true
kubectl get secret default-tls -n ingress-nginx -o yaml | \
    sed 's/namespace: ingress-nginx/namespace: default/' | \
    kubectl apply -f -

cat <<EOF > echo-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo-ingress
  namespace: default
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - echo.kubernetes.docker.internal
    secretName: default-tls
  rules:
  - host: echo.kubernetes.docker.internal
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: echo
            port:
              number: 80
EOF

kubectl apply -f echo-ingress.yaml

# Step 6: Update /etc/hosts for Docker Desktop
log_info "Updating /etc/hosts for Docker Desktop (requires sudo)..."
# Remove any existing entries
sudo sed -i '' '/\.kubernetes\.docker\.internal/d' /etc/hosts 2>/dev/null || true
# Add entries using 127.0.0.1 for Docker Desktop
echo "127.0.0.1 kubernetes.docker.internal" | sudo tee -a /etc/hosts
echo "127.0.0.1 echo.kubernetes.docker.internal" | sudo tee -a /etc/hosts

# Add example service entries
echo "127.0.0.1 frontend.kubernetes.docker.internal" | sudo tee -a /etc/hosts
echo "127.0.0.1 api.kubernetes.docker.internal" | sudo tee -a /etc/hosts
echo "127.0.0.1 admin.kubernetes.docker.internal" | sudo tee -a /etc/hosts
echo "127.0.0.1 spa.kubernetes.docker.internal" | sudo tee -a /etc/hosts
echo "127.0.0.1 monitoring.kubernetes.docker.internal" | sudo tee -a /etc/hosts

# Step 7: Clean up temporary files
log_info "Cleaning up temporary files..."
rm -f openssl-san.cnf tls.crt tls.key nginx-values.yaml echo-ingress.yaml

# Step 8: Wait for everything to be ready
log_info "Waiting for deployments to be ready..."
kubectl wait --for=condition=Ready pods -l app=echo --timeout=120s

# Step 9: Install monitoring stack (optional)
if [ "$MONITORING" = "true" ]; then
    log_info "Installing monitoring and observability stack..."
    
    # Source the monitoring installation scripts
    source ./scripts/install-prometheus.sh
    source ./scripts/install-jaeger.sh
    
    # Install Prometheus stack
    install_prometheus
    
    # Install Jaeger tracing
    install_jaeger
    
    log_success "Monitoring stack installation completed!"
fi

# Step 10: Final status and instructions
log_success "🎉 Setup completed successfully!"
log_info ""
log_info "✅ Core Services:"
log_info "  • NGINX Ingress Controller with trusted TLS certificates"
log_info "  • Echo test application"
log_info "  • Wildcard certificate (*.kubernetes.docker.internal)"
log_info ""

if [ "$MONITORING" = "true" ]; then
    log_info "✅ Monitoring & Observability:"
    log_info "  • Prometheus: https://prometheus.kubernetes.docker.internal/"
    log_info "  • Grafana: https://grafana.kubernetes.docker.internal/ (admin/admin123)"
    log_info "  • AlertManager: https://alertmanager.kubernetes.docker.internal/"
    log_info "  • Jaeger: https://jaeger.kubernetes.docker.internal/"
    log_info ""
fi

log_info "🌐 Test URLs:"
log_info "  • Echo Service: https://echo.kubernetes.docker.internal/"
log_info "  • Any subdomain: https://[anything].kubernetes.docker.internal/"
log_info ""
log_info "📚 Examples:"
log_info "  • Multi-Service: kubectl apply -f examples/multi-service/"
log_info "  • SPA Application: kubectl apply -f examples/spa-application/"
log_info ""
log_info "🧹 Cleanup:"
log_info "  • Run: ./cleanup-ingress.sh"
log_info ""
log_success "Happy coding! 🚀"