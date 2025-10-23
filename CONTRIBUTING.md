# Contributing to macmagik-docker-k8s-bootstrap

Thank you for your interest in contributing! This project aims to provide the best local Kubernetes development experience on macOS with Docker Desktop.

## 🎯 Project Goals

- **Zero-friction setup** - One command should get you from nothing to a working environment
- **Production-ready monitoring** - Include enterprise-grade observability tools
- **Trusted certificates** - No browser warnings or `curl -k` needed
- **Comprehensive examples** - Show real-world usage patterns
- **Robust error handling** - Scripts should handle edge cases and conflicts gracefully

## 🚀 Getting Started

### Development Environment Setup

1. **Fork and clone:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/macmagik-docker-k8s-bootstrap.git
   cd macmagik-docker-k8s-bootstrap
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x *.sh scripts/*.sh
   ```

3. **Test the current setup:**
   ```bash
   ./setup-ingress.sh
   # Verify all services work
   ./cleanup-ingress.sh
   ```

### Prerequisites for Development

- macOS (Intel or Apple Silicon)
- Docker Desktop with Kubernetes enabled
- Helm 3.x
- kubectl
- Basic shell scripting knowledge

## 🛠️ Development Workflow

### Testing Changes

**Always test the complete flow:**

```bash
# Clean environment
./cleanup-ingress.sh

# Test your changes
./setup-ingress.sh

# Verify all services
curl -k https://echo.kubernetes.docker.internal/
curl -k https://prometheus.kubernetes.docker.internal/
curl -k https://grafana.kubernetes.docker.internal/
curl -k https://jaeger.kubernetes.docker.internal/

# Test example applications
kubectl apply -f examples/multi-service/
curl -k https://frontend.kubernetes.docker.internal/

# Clean up
./cleanup-ingress.sh
```

### Script Development Guidelines

1. **Error Handling:**
   ```bash
   # Always exit on error
   set -e
   
   # Use proper error checking
   if ! command -v kubectl &> /dev/null; then
       log_error "kubectl is not installed"
       exit 1
   fi
   ```

2. **Logging:**
   ```bash
   # Use consistent logging functions
   log_info "Starting process..."
   log_success "Process completed"
   log_warning "Non-critical issue"
   log_error "Critical error"
   ```

3. **Idempotency:**
   ```bash
   # Scripts should be safe to run multiple times
   kubectl apply -f resource.yaml  # Not kubectl create
   helm upgrade --install ...      # Not helm install
   ```

4. **Resource Cleanup:**
   ```bash
   # Always clean up temporary files
   trap 'rm -f temp-cert.crt kubernetes.key' EXIT
   ```

## 📋 Types of Contributions

### 🐛 Bug Fixes

- Certificate trust issues
- Service accessibility problems
- Resource conflict handling
- Script compatibility issues

### ✨ Features

- New monitoring components
- Additional example applications
- Enhanced error recovery
- Platform support (with approval)

### 📚 Documentation

- README improvements
- Inline code comments
- Troubleshooting guides
- Architecture documentation

### 🧪 Testing

- Edge case validation
- Different macOS versions
- Various Docker Desktop configurations
- Example application improvements

## 💡 Contribution Ideas

### High Priority
- [ ] Add Loki + Promtail for log aggregation
- [ ] Create development vs production monitoring profiles
- [ ] Add network policy examples
- [ ] Improve Windows/Linux compatibility (if feasible)
- [ ] Add automated testing framework

### Medium Priority
- [ ] Additional example applications (FastAPI, Django, etc.)
- [ ] ArgoCD integration for GitOps
- [ ] Service mesh examples (Istio/Linkerd)
- [ ] Database examples (PostgreSQL, Redis)

### Low Priority
- [ ] Custom Grafana dashboards
- [ ] Advanced Jaeger configuration
- [ ] Performance benchmarking tools
- [ ] Development environment profiles

## 🔍 Code Review Guidelines

### For Reviewers

- Test the complete setup/cleanup cycle
- Verify all URLs are accessible
- Check for security best practices
- Ensure proper error handling
- Validate documentation accuracy

### For Contributors

- Include comprehensive commit messages
- Test on a clean environment
- Update documentation for new features
- Add inline comments for complex logic
- Follow existing code style

## 📝 Pull Request Process

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/amazing-feature
   ```

2. **Make your changes with tests:**
   ```bash
   # Implement your feature
   # Test thoroughly
   ./cleanup-ingress.sh && ./setup-ingress.sh
   ```

3. **Update documentation:**
   - Update README.md if needed
   - Add inline comments
   - Update TROUBLESHOOTING.md for new issues

4. **Commit with clear messages:**
   ```bash
   git commit -m "feat: add support for custom domain configuration
   
   - Allow users to specify custom domains
   - Update certificate generation for multiple domains
   - Add validation for domain format
   - Update documentation with examples"
   ```

5. **Push and create PR:**
   ```bash
   git push origin feature/amazing-feature
   ```

## 🚫 What We Don't Accept

- **Platform-specific changes** that break macOS compatibility
- **Complex dependencies** that make setup difficult
- **Security vulnerabilities** or unsafe practices
- **Breaking changes** without migration path
- **Untested code** that doesn't pass the complete setup cycle

## 🐛 Bug Reports

### Good Bug Report Template

```markdown
**Bug Description:**
Brief description of the issue

**Environment:**
- macOS version: 
- Docker Desktop version:
- Kubernetes version:
- Helm version:

**Steps to Reproduce:**
1. Run `./setup-ingress.sh`
2. Access https://service.kubernetes.docker.internal/
3. See error

**Expected Behavior:**
Service should be accessible with trusted certificate

**Actual Behavior:**
Certificate warning or connection error

**Logs:**
```
[Include relevant logs]
```

**Additional Context:**
Any other relevant information
```

## 💬 Getting Help

- **GitHub Issues:** For bugs and feature requests
- **GitHub Discussions:** For questions and general discussion
- **Code Review:** Request review from maintainers

## 🏆 Recognition

Contributors will be:
- Listed in the README acknowledgments
- Mentioned in release notes for significant contributions
- Invited to join the maintainer team for sustained contributions

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for helping make local Kubernetes development better for everyone!** 🚀