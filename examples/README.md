# Examples

This directory contains practical examples of using k8s-local-dev-magic with different applications and scenarios.

## 🌐 Multi-Service Application

A complete example showing how to set up multiple services with trusted TLS certificates.

### Architecture
```
https://frontend.kubernetes.docker.internal/  → Frontend Service
https://api.kubernetes.docker.internal/       → API Service  
https://admin.kubernetes.docker.internal/     → Admin Service
```

### Setup
```bash
# 1. Run the main setup
./setup-ingress.sh

# 2. Deploy the example services
kubectl apply -f examples/multi-service/

# 3. Add DNS entries
sudo tee -a /etc/hosts << EOF
127.0.0.1 frontend.kubernetes.docker.internal
127.0.0.1 api.kubernetes.docker.internal
127.0.0.1 admin.kubernetes.docker.internal
EOF

# 4. Test the services
open https://frontend.kubernetes.docker.internal/
open https://api.kubernetes.docker.internal/
open https://admin.kubernetes.docker.internal/
```

### Files
- `frontend-deployment.yaml` - Frontend application
- `api-deployment.yaml` - Backend API
- `admin-deployment.yaml` - Admin interface
- `ingress.yaml` - Ingress configuration for all services

## 🛠️ Development Workflow

Example of a typical development workflow using this setup.

### Scenario
You're developing a microservices application with:
- React frontend
- Node.js API
- PostgreSQL database
- Redis cache

### Workflow
1. **Setup Infrastructure**
   ```bash
   ./setup-ingress.sh
   ```

2. **Deploy Base Services**
   ```bash
   kubectl apply -f examples/dev-workflow/infrastructure/
   ```

3. **Deploy Your Applications**
   ```bash
   kubectl apply -f examples/dev-workflow/apps/
   ```

4. **Add DNS Entries**
   ```bash
   sudo tee -a /etc/hosts << EOF
   127.0.0.1 app.kubernetes.docker.internal
   127.0.0.1 api.kubernetes.docker.internal
   127.0.0.1 pgadmin.kubernetes.docker.internal
   EOF
   ```

5. **Develop & Test**
   - Frontend: https://app.kubernetes.docker.internal/
   - API: https://api.kubernetes.docker.internal/
   - Database Admin: https://pgadmin.kubernetes.docker.internal/

## 🎯 Single Page Application (SPA)

Perfect setup for React, Vue, or Angular applications that need API calls without CORS issues.

### Benefits
- No CORS configuration needed
- Same-origin requests
- Realistic production-like environment

### Example: React + Express
```bash
# Deploy the example
kubectl apply -f examples/spa-example/

# Add DNS
echo "127.0.0.1 myapp.kubernetes.docker.internal" | sudo tee -a /etc/hosts

# Access your app
open https://myapp.kubernetes.docker.internal/
```

The React app can make API calls to `/api/*` which routes to the Express backend.

## 🔍 Monitoring & Observability

Example setup with monitoring tools that have web UIs.

### What's Included
- Prometheus - Metrics collection
- Grafana - Visualization
- Jaeger - Distributed tracing

### Setup
```bash
kubectl apply -f examples/monitoring/

# Add DNS entries
sudo tee -a /etc/hosts << EOF
127.0.0.1 prometheus.kubernetes.docker.internal
127.0.0.1 grafana.kubernetes.docker.internal
127.0.0.1 jaeger.kubernetes.docker.internal
EOF
```

### Access
- Prometheus: https://prometheus.kubernetes.docker.internal/
- Grafana: https://grafana.kubernetes.docker.internal/ (admin/admin)
- Jaeger: https://jaeger.kubernetes.docker.internal/

## 📊 Database Administration

Examples for accessing database admin interfaces securely.

### PostgreSQL + pgAdmin
```bash
kubectl apply -f examples/databases/postgresql/

echo "127.0.0.1 pgadmin.kubernetes.docker.internal" | sudo tee -a /etc/hosts

open https://pgadmin.kubernetes.docker.internal/
```

### MongoDB + Mongo Express
```bash
kubectl apply -f examples/databases/mongodb/

echo "127.0.0.1 mongo-admin.kubernetes.docker.internal" | sudo tee -a /etc/hosts

open https://mongo-admin.kubernetes.docker.internal/
```

## 🚀 CI/CD Integration

Example of how to use this setup in CI/CD pipelines for integration testing.

### GitHub Actions Example
```yaml
# .github/workflows/integration-test.yml
name: Integration Tests

on: [push, pull_request]

jobs:
  integration:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Kubernetes
      # Your k8s setup steps
      
    - name: Setup Ingress
      run: ./setup-ingress.sh
      
    - name: Deploy Test Services
      run: kubectl apply -f examples/ci-cd/
      
    - name: Run Integration Tests
      run: |
        # Wait for services
        kubectl wait --for=condition=Ready pods -l app=test-app --timeout=300s
        
        # Run tests against https://test-app.kubernetes.docker.internal/
        npm run test:integration
```

## 🧪 Load Testing

Example setup for load testing your applications with realistic HTTPS endpoints.

### Using k6
```bash
# Deploy your app
kubectl apply -f examples/load-testing/app/

# Deploy k6 load test
kubectl apply -f examples/load-testing/k6/

# View results
kubectl logs -f job/load-test
```

### Using Apache Bench
```bash
# Test API endpoint
ab -n 1000 -c 10 https://api.kubernetes.docker.internal/health

# Test with custom headers
ab -n 100 -c 5 -H "Accept: application/json" https://api.kubernetes.docker.internal/users
```

## 🔐 Security Testing

Examples for security testing with trusted certificates.

### OWASP ZAP
```bash
kubectl apply -f examples/security/zap/

echo "127.0.0.1 zap.kubernetes.docker.internal" | sudo tee -a /etc/hosts

open https://zap.kubernetes.docker.internal/
```

### SSL Labs Testing
Since certificates are properly configured, you can test SSL configuration:
```bash
# Test certificate configuration
openssl s_client -connect kubernetes.docker.internal:443 -servername kubernetes.docker.internal

# Verify certificate chain
curl -vvI https://api.kubernetes.docker.internal/ 2>&1 | grep -E "(subject|issuer|CN=)"
```

## 🎮 Gaming/WebRTC Applications

Examples for applications that require secure contexts (HTTPS) to function properly.

### WebRTC Video Chat
```bash
kubectl apply -f examples/webrtc/

echo "127.0.0.1 videochat.kubernetes.docker.internal" | sudo tee -a /etc/hosts

open https://videochat.kubernetes.docker.internal/
```

WebRTC requires HTTPS for camera/microphone access - this setup provides that automatically!

## 🧽 Cleanup

To clean up any example:
```bash
# Remove specific example
kubectl delete -f examples/multi-service/

# Remove DNS entries
sudo sed -i '' '/frontend\.kubernetes\.docker\.internal/d' /etc/hosts

# Or clean up everything
./cleanup-ingress.sh
```

## 💡 Tips

1. **Use consistent naming**: `appname.kubernetes.docker.internal`
2. **Leverage the wildcard certificate**: No need to create new certificates
3. **Test HTTPS functionality**: Many modern web features require HTTPS
4. **Use realistic URLs**: Helps identify CORS and same-origin issues early
5. **Document your DNS entries**: Keep track in your project README

---

Have an example you'd like to share? [Contribute it!](../CONTRIBUTING.md) 🚀