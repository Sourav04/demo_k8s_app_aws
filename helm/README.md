# 🎯 Single Values File - Helm Configuration Guide

This guide explains how to use the single `values.yaml` file to control different environments in Helm.

## 📁 Current Structure

```
helm/python-app/
├── values.yaml          # Single values file with all environments
├── Chart.yaml           # Chart metadata
└── templates/           # Helm templates
```

## 🚀 How to Use Different Environments

### 1. **Basic Usage - Set Environment**

```bash
# Deploy to development environment
helm install my-app ./python-app --set environment=dev

# Deploy to staging environment
helm install my-app ./python-app --set environment=staging

# Deploy to production environment
helm install my-app ./python-app --set environment=prod

# Deploy to test environment
helm install my-app ./python-app --set environment=test
```

### 2. **Override Specific Values**

```bash
# Deploy to production with custom image tag
helm install my-app ./python-app \
  --set environment=prod \
  --set image.tag=v1.2.3

# Deploy to staging with custom replica count
helm install my-app ./python-app \
  --set environment=staging \
  --set replicaCount=5
```

### 3. **Environment-Specific Deployments**

```bash
# Development (1 replica, low resources, no monitoring)
helm install python-app-dev ./python-app \
  --set environment=dev \
  --namespace dev \
  --create-namespace

# Staging (2 replicas, medium resources, basic monitoring)
helm install python-app-staging ./python-app \
  --set environment=staging \
  --namespace staging \
  --create-namespace

# Production (3 replicas, high resources, full monitoring + autoscaling)
helm install python-app-prod ./python-app \
  --set environment=prod \
  --namespace production \
  --create-namespace

# Test (1 replica, low resources, no Redis, no monitoring)
helm install python-app-test ./python-app \
  --set environment=test \
  --namespace test \
  --create-namespace
```

## 🎛️ Environment Configurations

| Environment | Replicas | Resources | Redis | Monitoring | Autoscaling |
|-------------|----------|-----------|-------|------------|-------------|
| **dev** | 1 | Low | ✅ | ❌ | ❌ |
| **staging** | 2 | Medium | ✅ | ✅ | ✅ |
| **prod** | 3 | High | ✅ | ✅ | ✅ |
| **test** | 1 | Low | ❌ | ❌ | ❌ |

## 🔧 Environment-Specific Features

### Development Environment
- **Resources**: 300m CPU, 256Mi memory
- **Redis**: Enabled with minimal resources
- **Monitoring**: Disabled
- **Autoscaling**: Disabled
- **Environment**: `development`
- **Log Level**: `debug`

### Staging Environment
- **Resources**: 500m CPU, 512Mi memory
- **Redis**: Enabled with medium resources
- **Monitoring**: Basic (ServiceMonitor only)
- **Autoscaling**: Enabled (1-5 replicas)
- **Environment**: `staging`
- **Log Level**: `info`

### Production Environment
- **Resources**: 1000m CPU, 1Gi memory
- **Redis**: Enabled with high resources
- **Monitoring**: Full (ServiceMonitor + PrometheusRule)
- **Autoscaling**: Enabled (2-10 replicas)
- **Environment**: `production`
- **Log Level**: `warning`

### Test Environment
- **Resources**: 200m CPU, 256Mi memory
- **Redis**: Disabled (uses mock Redis)
- **Monitoring**: Disabled
- **Autoscaling**: Disabled
- **Environment**: `testing`
- **Log Level**: `debug`

## 🧪 Testing and Validation

### Dry Run (Validate without deploying)
```bash
helm install my-app ./python-app \
  --set environment=prod \
  --dry-run \
  --debug
```

### Template Rendering (See final YAML)
```bash
helm template my-app ./python-app \
  --set environment=prod > rendered-prod.yaml
```

### Lint Chart
```bash
helm lint ./python-app --set environment=prod
```

## 🚀 CI/CD Integration

### GitHub Actions Example
```yaml
- name: Deploy to Development
  run: |
    helm upgrade --install python-app-dev ./python-app \
      --set environment=dev \
      --namespace dev \
      --create-namespace

- name: Deploy to Production
  run: |
    helm upgrade --install python-app-prod ./python-app \
      --set environment=prod \
      --namespace production \
      --create-namespace
```

### ArgoCD Integration
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: python-app-prod
spec:
  source:
    repoURL: https://github.com/your-repo/k3_demo
    targetRevision: HEAD
    path: helm/python-app
    helm:
      parameters:
        - name: environment
          value: prod
```

## 📋 Quick Reference Commands

```bash
# Install with environment
helm install <release-name> ./python-app --set environment=<env>

# Upgrade with environment
helm upgrade <release-name> ./python-app --set environment=<env>

# Uninstall
helm uninstall <release-name>

# List releases
helm list

# Get values
helm get values <release-name>

# Rollback
helm rollback <release-name> <revision>
```

## 🎯 Benefits of Single Values File

1. **Simplified Management**: Only one file to maintain
2. **Environment Consistency**: All configurations in one place
3. **Easy Comparison**: See differences between environments at a glance
4. **Version Control**: Single file to track changes
5. **Reduced Complexity**: No need to manage multiple files

## 🔍 How It Works

The single values file uses a nested structure where each configuration section has an `environments` subsection:

```yaml
resources:
  # Default resources
  limits:
    cpu: 500m
    memory: 512Mi
  
  # Environment-specific overrides
  environments:
    dev:
      limits:
        cpu: 300m
        memory: 256Mi
    prod:
      limits:
        cpu: 1000m
        memory: 1Gi
```

Helm templates use helper functions to merge default values with environment-specific overrides, ensuring consistent behavior across all environments. 