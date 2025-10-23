# Multi-Service Architecture Example

This directory contains a complete example of a multi-service architecture running on Kubernetes with trusted TLS certificates.

## 📋 Services Overview

| Service  | URL | Description |
|----------|-----|-------------|
| Frontend | https://frontend.kubernetes.docker.internal/ | React-style SPA with service navigation |
| API      | https://api.kubernetes.docker.internal/ | Node.js API with health endpoints |
| Admin    | https://admin.kubernetes.docker.internal/ | Secure admin dashboard |

## 🚀 Quick Deploy

After running the main setup script, deploy all services with:

```bash
# Deploy all services
kubectl apply -f examples/multi-service/

# Check deployment status
kubectl get pods,services,ingress
```

## 🏗️ Architecture

```
Internet
    ↓
NGINX Ingress Controller (Port 443)
    ↓
┌─────────────────────────────────┐
│        TLS Termination          │
│    (Wildcard Certificate)       │
└─────────────────────────────────┘
    ↓
┌─────────────┬─────────────┬─────────────┐
│  Frontend   │     API     │    Admin    │
│   Service   │   Service   │   Service   │
│    :80      │    :3000    │     :80     │
└─────────────┴─────────────┴─────────────┘
```

## 🔧 Service Details

### Frontend Service
- **Technology**: Static HTML/CSS/JS (simulating React SPA)
- **Features**: Service navigation, responsive design
- **Port**: 80

### API Service  
- **Technology**: Node.js Express server
- **Endpoints**: 
  - `GET /` - API status
  - `GET /health` - Health check
  - `GET /users` - Sample data
- **Port**: 3000

### Admin Service
- **Technology**: Static HTML with admin interface
- **Features**: System metrics, service monitoring
- **Port**: 80
- **Security**: Secure admin dashboard styling

## 🌐 DNS Configuration

These hostnames are configured in `/etc/hosts` by the setup script:

```
127.0.0.1 frontend.kubernetes.docker.internal
127.0.0.1 api.kubernetes.docker.internal  
127.0.0.1 admin.kubernetes.docker.internal
```

## 🔐 TLS Configuration

All services use the same wildcard certificate (`*.kubernetes.docker.internal`) configured as the default SSL certificate in NGINX Ingress Controller. This provides:

- ✅ Trusted certificates (no browser warnings)
- ✅ Automatic HTTPS redirect
- ✅ Consistent security across all services
- ✅ No per-service certificate management

## 🧪 Testing

Test each service individually:

```bash
# Test Frontend
curl -k https://frontend.kubernetes.docker.internal/

# Test API
curl -k https://api.kubernetes.docker.internal/health

# Test Admin  
curl -k https://admin.kubernetes.docker.internal/
```

Or visit in browser:
- 🖥️ [Frontend](https://frontend.kubernetes.docker.internal/)
- 📡 [API](https://api.kubernetes.docker.internal/)
- ⚙️ [Admin](https://admin.kubernetes.docker.internal/)

## 🧹 Cleanup

Remove all services:

```bash
kubectl delete -f examples/multi-service/
```

## 💡 Customization

### Adding New Services

1. Create a new deployment and service YAML
2. Add the hostname to `ingress.yaml`  
3. Add the hostname to `/etc/hosts` (or modify the setup script)
4. Deploy: `kubectl apply -f your-service.yaml`

### Custom Domains

To use different domains:

1. Generate new certificates with your domains
2. Update the ingress TLS configuration
3. Update DNS configuration (hosts file or DNS server)

## 🔍 Troubleshooting

### Service Not Accessible
```bash
# Check pod status
kubectl get pods

# Check service endpoints
kubectl get endpoints

# Check ingress configuration
kubectl describe ingress multi-service-ingress
```

### Certificate Issues
```bash
# Verify certificate is loaded
kubectl get secret default-tls -o yaml

# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

This example demonstrates a production-ready multi-service architecture with proper TLS termination, service discovery, and monitoring capabilities.