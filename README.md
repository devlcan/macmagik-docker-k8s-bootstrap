# 🚀 macmagik-docker-k8s-bootstrap

**One-command setup for a complete local Kubernetes development environment with trusted TLS certificates and comprehensive monitoring stack.**

[![macOS](https://img.shields.io/badge/macOS-Intel%20%26%20Apple%20Silicon-blue?logo=apple)](https://www.apple.com/macos/)
[![Docker Desktop](https://img.shields.io/badge/Docker%20Desktop-Required-blue?logo=docker)](https://www.docker.com/products/docker-desktop/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.24+-blue?logo=kubernetes)](https://kubernetes.io/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

> **Stop fighting certificates, start building amazing things!** ✨  
> No more `curl -k`, no more certificate warnings - just pure local development bliss.

## 🎯 What This Gives You

### 🔐 **Trusted TLS Everywhere**
- **Wildcard certificates** for `*.kubernetes.docker.internal`
- **Green lock in browsers** - no security warnings
- **macOS keychain integration** - system-wide trust
- **Works with any subdomain** you create

### 📊 **Production-Grade Monitoring**
- **Prometheus** - Metrics collection with 30-day retention
- **Grafana** - Beautiful dashboards with pre-built Kubernetes monitoring
- **Jaeger** - Distributed tracing for microservices
- **AlertManager** - Intelligent alerting and notifications

### ⚡ **Developer Experience**
- **One-command setup** - From zero to production-ready in 2 minutes
- **Automatic cleanup** - Complete removal when you're done
- **Example applications** - Multi-service architectures ready to deploy
- **Recovery tools** - Handle conflicts and stuck resources

---

## 🚀 Quick Start

### Prerequisites
```bash
# Required tools (install via Homebrew)
brew install helm kubectl

# Required environment
✅ macOS (Intel or Apple Silicon)
✅ Docker Desktop with Kubernetes enabled
✅ Admin privileges for certificate installation
```

### One-Command Installation
```bash
# Clone and setup everything
git clone https://github.com/YOUR_USERNAME/macmagik-docker-k8s-bootstrap.git
cd macmagik-docker-k8s-bootstrap
chmod +x *.sh scripts/*.sh
./setup-ingress.sh
```

**That's it!** 🎉 In under 2 minutes you'll have:
- ✅ NGINX Ingress Controller with trusted certificates
- ✅ Complete monitoring stack (Prometheus, Grafana, Jaeger)
- ✅ Example applications ready to use
- ✅ All URLs accessible with green lock 🔒

### 🔍 Verify Your Setup
```bash
# Run comprehensive verification (recommended)
./verify-setup.sh
```

This verification script tests all 14 components:
- **Core Infrastructure** (4 tests): Ingress controller, certificates, DNS resolution
- **Monitoring Stack** (7 tests): Prometheus, Grafana, AlertManager accessibility
- **Distributed Tracing** (3 tests): Jaeger components and health checks

---

## 🌐 Access Your Services

### 🔧 **Core Infrastructure**
| Service | URL | Purpose | Credentials |
|---------|-----|---------|-------------|
| **Echo Test App** | https://echo.kubernetes.docker.internal/ | Test ingress setup | None |
| **Any Subdomain** | https://[anything].kubernetes.docker.internal/ | Test custom services | None |

### 📊 **Monitoring & Observability**
| Service | URL | Purpose | Credentials |
|---------|-----|---------|-------------|
| **Prometheus** | https://prometheus.kubernetes.docker.internal/ | Metrics collection & queries | None |
| **Grafana** | https://grafana.kubernetes.docker.internal/ | Dashboards & visualization | `admin` / `admin123` |
| **AlertManager** | https://alertmanager.kubernetes.docker.internal/ | Alert management | None |
| **Jaeger** | https://jaeger.kubernetes.docker.internal/ | Distributed tracing | None |

### 🎛️ **Pre-Built Example Applications**
| Application | URL | Purpose | Features |
|-------------|-----|---------|----------|
| **Multi-Service Demo** | https://frontend.kubernetes.docker.internal/ | Microservices architecture | Frontend, API, Admin panels |
| **SPA Application** | https://spa.kubernetes.docker.internal/ | Single Page App | Client-side routing |
| **Monitoring Dashboard** | https://monitoring.kubernetes.docker.internal/ | Unified monitoring | Real-time metrics |

---

## 📖 Usage Guide

### 🏗️ **Deploy Example Applications**

```bash
# Deploy complete multi-service architecture
kubectl apply -f examples/multi-service/
# Access at: https://frontend.kubernetes.docker.internal/
#           https://api.kubernetes.docker.internal/
#           https://admin.kubernetes.docker.internal/

# Deploy single-page application
kubectl apply -f examples/spa-application/
# Access at: https://spa.kubernetes.docker.internal/

# Deploy monitoring dashboard
kubectl apply -f examples/monitoring-dashboard/
# Access at: https://monitoring.kubernetes.docker.internal/
```

### 🛠️ **Create Your Own Service**

1. **Create your application deployment:**
```yaml
# my-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
```

2. **Create ingress with trusted TLS:**
```yaml
# my-app-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - my-app.kubernetes.docker.internal
    secretName: default-tls  # Reuse the wildcard certificate!
  rules:
  - host: my-app.kubernetes.docker.internal
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app
            port:
              number: 80
```

3. **Deploy and access:**
```bash
# Deploy your application
kubectl apply -f my-app.yaml -f my-app-ingress.yaml

# Add to hosts file (automatic if using setup script)
echo "127.0.0.1 my-app.kubernetes.docker.internal" | sudo tee -a /etc/hosts

# Access with trusted certificate!
open https://my-app.kubernetes.docker.internal/
```

### 📊 **Using the Monitoring Stack**

#### **Prometheus - Metrics & Alerting**
```bash
# Access Prometheus UI
open https://prometheus.kubernetes.docker.internal/

# Example queries to try:
# - Container CPU usage: rate(container_cpu_usage_seconds_total[5m])
# - Memory usage: container_memory_usage_bytes
# - Pod status: kube_pod_status_phase
```

#### **Grafana - Dashboards**
```bash
# Access Grafana (admin/admin123)
open https://grafana.kubernetes.docker.internal/

# Pre-installed dashboards:
# - Kubernetes / Compute Resources / Cluster
# - Kubernetes / Compute Resources / Namespace
# - Node Exporter / Nodes
```

#### **Jaeger - Distributed Tracing**
```bash
# Access Jaeger UI
open https://jaeger.kubernetes.docker.internal/

# Send traces to Jaeger from your applications:
# HTTP endpoint: http://jaeger-prod-collector.observability.svc.cluster.local:14268/api/traces
# Agent endpoint: jaeger-prod-agent.observability.svc.cluster.local:6831
```

---

## 🧹 Cleanup & Recovery

### **Complete Cleanup**
```bash
# Remove everything (certificates, services, monitoring)
./cleanup-ingress.sh
```

### **Quick Recovery** (for stuck resources)
```bash
# If setup fails with conflicts or "object modified" errors
./recovery.sh

# Then retry setup
./setup-ingress.sh
```

### **Selective Cleanup**
```bash
# Remove only monitoring stack
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring observability

# Remove only example applications
kubectl delete -f examples/multi-service/
kubectl delete -f examples/spa-application/

# Remove specific ingress
kubectl delete ingress my-app-ingress
```

---

## 🔧 Troubleshooting

> **💡 Quick Diagnosis:** Run `./verify-setup.sh` first to identify issues automatically.

### **Certificate Issues**

**Problem:** Certificate not trusted in browser
```bash
# Check if certificate exists in keychain
security find-certificate -c "*.kubernetes.docker.internal" /Library/Keychains/System.keychain

# Re-add certificate manually
kubectl get secret default-tls -n ingress-nginx -o jsonpath='{.data.tls\.crt}' | base64 -d > temp-cert.crt
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain temp-cert.crt
rm temp-cert.crt
```

### **Service Access Issues**

**Problem:** Service not accessible
```bash
# Check ingress controller status
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Check your service and ingress
kubectl get svc,ingress -A
kubectl describe ingress my-app-ingress

# Check DNS resolution
grep kubernetes.docker.internal /etc/hosts
nslookup my-app.kubernetes.docker.internal
```

### **Monitoring Issues**

**Problem:** Monitoring services not responding
```bash
# Check monitoring pods
kubectl get pods -n monitoring -n observability

# Check specific service logs
kubectl logs -n monitoring prometheus-grafana-xxx
kubectl logs -n observability jaeger-prod-xxx

# Restart monitoring stack
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring
```

### **Resource Conflicts**

**Problem:** "Object has been modified" or "AlreadyExists" errors
```bash
# Use recovery script (handles most conflicts)
./recovery.sh

# Manual cleanup for persistent issues
kubectl patch pv pv-name -p '{"metadata":{"finalizers":null}}'
kubectl delete namespace stuck-namespace --grace-period=0 --force
```

For more detailed troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## 🏗️ Architecture

### **Network Flow**
```
Browser Request (https://app.kubernetes.docker.internal)
        ↓
macOS /etc/hosts (127.0.0.1)
        ↓
Docker Desktop (localhost:443)
        ↓
NGINX Ingress Controller (hostPort)
        ↓
Kubernetes Service
        ↓
Pod (your application)
```

### **Certificate Chain**
```
Root CA (kubernetes-ca.crt)
        ↓
Wildcard Certificate (*.kubernetes.docker.internal)
        ↓
macOS Keychain (system-wide trust)
        ↓
Kubernetes TLS Secret (default-tls)
        ↓
Ingress TLS Termination
```

### **Monitoring Architecture**
```
Applications → Prometheus (metrics) → Grafana (dashboards)
             ↓
Applications → Jaeger Agent → Jaeger Collector → Jaeger Query → Jaeger UI
             ↓
Prometheus → AlertManager (alerts) → Notifications
```

---

## 📁 Project Structure

```
macmagik-docker-k8s-bootstrap/
├── setup-ingress.sh           # Main setup script
├── cleanup-ingress.sh         # Complete cleanup
├── recovery.sh                # Resource conflict recovery
├── verify-setup.sh            # Comprehensive verification
├── scripts/
│   ├── install-prometheus.sh  # Monitoring stack
│   └── install-jaeger.sh      # Distributed tracing
├── examples/
│   ├── multi-service/         # Microservices demo
│   ├── spa-application/       # Single-page app
│   ├── monitoring-dashboard/  # Unified monitoring
│   └── README.md              # Examples documentation
├── CONTRIBUTING.md            # Contribution guidelines
├── TROUBLESHOOTING.md         # Common issues & solutions
├── LICENSE                    # MIT license
└── README.md                  # This file
```

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Quick workflow:**

1. **Fork the repository**
2. **Create a feature branch:** `git checkout -b feature/amazing-feature`
3. **Test your changes:** `./cleanup-ingress.sh && ./setup-ingress.sh && ./verify-setup.sh`
4. **Commit your changes:** `git commit -m 'Add amazing feature'`
5. **Push to the branch:** `git push origin feature/amazing-feature`
6. **Open a Pull Request**

### **Development Setup**
```bash
# Test the complete flow
./cleanup-ingress.sh  # Clean slate
./setup-ingress.sh    # Full setup
./verify-setup.sh     # Verify everything works

# Test example applications
kubectl apply -f examples/multi-service/
curl -k https://frontend.kubernetes.docker.internal/

# Cleanup after testing
./cleanup-ingress.sh
```

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- **Docker Desktop team** for making Kubernetes accessible on macOS
- **NGINX Ingress Controller** maintainers for excellent Docker Desktop support
- **Prometheus Operator** team for simplified monitoring setup
- **Jaeger** team for outstanding distributed tracing
- **Kubernetes community** for incredible documentation and support

---

## ⭐ Star History

If this project saved you time and frustration, please consider giving it a star! ⭐

---

**Made with ❤️ for developers who are tired of fighting local Kubernetes certificates**

*Stop configuring, start building!* 🚀