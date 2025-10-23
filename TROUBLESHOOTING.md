# Troubleshooting Guide

This guide covers common issues and their solutions when using macmagik-docker-k8s-bootstrap.

## 🚀 Quick Fixes

### First Steps for Any Issue

```bash
# Try the recovery script first
./recovery.sh

# Then retry setup
./setup-ingress.sh
```

This solves 80% of common issues related to resource conflicts and stuck resources.

---

## 🔐 Certificate Issues

### Certificate Not Trusted in Browser

**Symptoms:**
- Browser shows "Your connection is not private"
- Certificate warnings when accessing services
- `curl` requires `-k` flag

**Solutions:**

1. **Check if certificate exists in keychain:**
   ```bash
   security find-certificate -c "*.kubernetes.docker.internal" /Library/Keychains/System.keychain
   ```

2. **Re-add certificate manually:**
   ```bash
   # Extract certificate from Kubernetes secret
   kubectl get secret default-tls -n ingress-nginx -o jsonpath='{.data.tls\.crt}' | base64 -d > temp-cert.crt
   
   # Add to system keychain
   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain temp-cert.crt
   
   # Clean up
   rm temp-cert.crt
   ```

3. **Restart browser completely** after adding certificate

4. **Check certificate validity:**
   ```bash
   openssl x509 -in temp-cert.crt -text -noout
   ```

### Certificate Installation Fails

**Error:** `security: SecTrustSettingsSetTrustSettings: One or more parameters passed to a function were not valid.`

**Solution:**
```bash
# Use different trust settings
sudo security add-trusted-cert -d -r trustAsRoot -k /Library/Keychains/System.keychain kubernetes-ca.crt
```

---

## 🌐 DNS and Network Issues

### Service Not Accessible

**Symptoms:**
- `curl: (6) Could not resolve host`
- Browser can't find the site
- DNS resolution fails

**Solutions:**

1. **Check /etc/hosts entries:**
   ```bash
   grep kubernetes.docker.internal /etc/hosts
   ```
   Should show entries like:
   ```
   127.0.0.1 kubernetes.docker.internal
   127.0.0.1 echo.kubernetes.docker.internal
   127.0.0.1 prometheus.kubernetes.docker.internal
   ```

2. **Manually add missing entries:**
   ```bash
   echo "127.0.0.1 your-service.kubernetes.docker.internal" | sudo tee -a /etc/hosts
   ```

3. **Flush DNS cache:**
   ```bash
   sudo dscacheutil -flushcache
   sudo killall -HUP mDNSResponder
   ```

### Port Conflicts

**Error:** `bind: address already in use`

**Solutions:**

1. **Check what's using the ports:**
   ```bash
   sudo lsof -i :80 -i :443
   ```

2. **Stop conflicting services:**
   ```bash
   # Common conflicts
   sudo brew services stop nginx
   sudo pkill -f "python.*8080"
   ```

3. **Check Docker Desktop port allocation:**
   ```bash
   kubectl get service -n ingress-nginx ingress-nginx-controller
   ```

---

## 📦 Kubernetes Resource Issues

### Pods Stuck in Terminating

**Symptoms:**
- Pods show `Terminating` status for extended time
- `kubectl delete pod` hangs
- Namespace stuck in `Terminating`

**Solutions:**

1. **Use recovery script:**
   ```bash
   ./recovery.sh
   ```

2. **Force delete pods:**
   ```bash
   kubectl delete pod <pod-name> --grace-period=0 --force
   ```

3. **Remove finalizers:**
   ```bash
   kubectl patch pod <pod-name> -p '{"metadata":{"finalizers":null}}'
   ```

4. **Force delete namespace:**
   ```bash
   kubectl delete namespace <namespace> --grace-period=0 --force
   ```

### "Object has been modified" Errors

**Error:** `error when patching: Operation cannot be fulfilled on secrets "default-tls": the object has been modified`

**Solution:**
```bash
# Delete and recreate the problematic resource
kubectl delete secret default-tls -n <namespace> --ignore-not-found=true

# Run setup again
./setup-ingress.sh
```

### Helm Release Conflicts

**Error:** `release: already exists`

**Solutions:**

1. **List existing releases:**
   ```bash
   helm list -A
   ```

2. **Uninstall conflicting release:**
   ```bash
   helm uninstall <release-name> -n <namespace>
   ```

3. **Force upgrade:**
   ```bash
   helm upgrade --install <release-name> <chart> --force
   ```

---

## 📊 Monitoring Stack Issues

### Prometheus Not Accessible

**Symptoms:**
- `502 Bad Gateway` when accessing Prometheus URL
- Prometheus pods not running

**Solutions:**

1. **Check pod status:**
   ```bash
   kubectl get pods -n monitoring
   kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0
   ```

2. **Check storage issues:**
   ```bash
   kubectl get pv,pvc -n monitoring
   ```

3. **Restart Prometheus stack:**
   ```bash
   helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring
   ```

### Grafana Login Issues

**Problem:** Can't login to Grafana with admin/admin123

**Solutions:**

1. **Get actual password:**
   ```bash
   kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d
   ```

2. **Reset password:**
   ```bash
   kubectl patch secret prometheus-grafana -n monitoring -p '{"data":{"admin-password":"'$(echo -n "admin123" | base64)'"}}'
   kubectl rollout restart deployment/prometheus-grafana -n monitoring
   ```

### Jaeger Service Unavailable

**Symptoms:**
- `503 Service Temporarily Unavailable` for Jaeger
- Jaeger UI not loading

**Solutions:**

1. **Check Jaeger pods:**
   ```bash
   kubectl get pods -n observability
   kubectl logs -n observability <jaeger-pod-name>
   ```

2. **Check service configuration:**
   ```bash
   kubectl get svc -n observability
   kubectl describe ingress jaeger-ingress -n observability
   ```

3. **Verify service name in ingress:**
   ```bash
   # Ensure ingress points to correct service
   kubectl patch ingress jaeger-ingress -n observability --type='json' -p='[{"op": "replace", "path": "/spec/rules/0/http/paths/0/backend/service/name", "value": "jaeger-prod-query"}]'
   ```

---

## 🐳 Docker Desktop Issues

### Kubernetes Not Starting

**Symptoms:**
- `kubectl cluster-info` fails
- "connection refused" errors
- Docker Desktop shows Kubernetes as red

**Solutions:**

1. **Reset Kubernetes cluster:**
   - Docker Desktop → Preferences → Kubernetes → Reset Kubernetes Cluster

2. **Restart Docker Desktop:**
   ```bash
   pkill -f "Docker Desktop"
   open /Applications/Docker.app
   ```

3. **Check resources:**
   - Ensure Docker Desktop has enough CPU/Memory allocated
   - Minimum: 4GB RAM, 2 CPUs

### Storage Issues

**Error:** `no space left on device`

**Solutions:**

1. **Clean Docker:**
   ```bash
   docker system prune -a --volumes
   ```

2. **Check disk space:**
   ```bash
   df -h
   docker system df
   ```

3. **Increase Docker Desktop disk allocation:**
   - Docker Desktop → Preferences → Resources → Advanced

---

## 🔧 Installation Issues

### Helm Not Found

**Error:** `helm: command not found`

**Solution:**
```bash
# Install Helm via Homebrew
brew install helm

# Or direct download
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### kubectl Not Configured

**Error:** `error: You must be logged in to the server`

**Solutions:**

1. **Check kubectl context:**
   ```bash
   kubectl config current-context
   ```

2. **Set Docker Desktop context:**
   ```bash
   kubectl config use-context docker-desktop
   ```

3. **Verify cluster connection:**
   ```bash
   kubectl cluster-info
   ```

### Permission Denied Errors

**Error:** `Permission denied` when modifying system files

**Solutions:**

1. **For /etc/hosts modification:**
   ```bash
   # The script should prompt for sudo password
   # If not, manually add entries:
   sudo echo "127.0.0.1 service.kubernetes.docker.internal" >> /etc/hosts
   ```

2. **For keychain operations:**
   ```bash
   # Ensure you have admin privileges
   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain cert.crt
   ```

---

## 🚨 Emergency Recovery

### Complete Environment Reset

If everything is broken and you need to start fresh:

```bash
# 1. Complete cleanup
./cleanup-ingress.sh

# 2. Manual cleanup if needed
docker system prune -a --volumes
kubectl delete namespace ingress-nginx monitoring observability --force --grace-period=0

# 3. Reset Docker Desktop Kubernetes
# Docker Desktop → Preferences → Kubernetes → Reset Kubernetes Cluster

# 4. Fresh installation
./setup-ingress.sh
```

### Backup Before Major Changes

```bash
# Export current configuration
kubectl get all,ingress,secrets -A -o yaml > kubernetes-backup.yaml

# Backup certificate
kubectl get secret default-tls -n ingress-nginx -o yaml > tls-backup.yaml
```

---

## 📞 Getting Help

### Before Asking for Help

1. **Run diagnostics:**
   ```bash
   # Collect system information
   echo "=== System Info ==="
   sw_vers
   echo "=== Docker Version ==="
   docker --version
   echo "=== Kubernetes Version ==="
   kubectl version --client
   echo "=== Helm Version ==="
   helm version
   echo "=== Cluster Info ==="
   kubectl cluster-info
   echo "=== Pods Status ==="
   kubectl get pods -A
   ```

2. **Check logs:**
   ```bash
   # Ingress controller logs
   kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --tail=50
   
   # Monitoring logs
   kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus --tail=50
   kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=50
   ```

3. **Verify basic connectivity:**
   ```bash
   curl -k https://echo.kubernetes.docker.internal/
   nslookup echo.kubernetes.docker.internal
   ```

### Where to Get Help

- **GitHub Issues:** For bugs and problems
- **GitHub Discussions:** For questions and usage help
- **README.md:** For setup and usage instructions
- **CONTRIBUTING.md:** For development questions

### Information to Include

When reporting issues, always include:

- macOS version (Intel/Apple Silicon)
- Docker Desktop version
- Kubernetes version
- Complete error messages
- Steps to reproduce
- What you expected to happen
- Diagnostic output from above commands

---

**Remember:** Most issues can be resolved with `./recovery.sh` followed by `./setup-ingress.sh`. Don't hesitate to try this first! 🚀