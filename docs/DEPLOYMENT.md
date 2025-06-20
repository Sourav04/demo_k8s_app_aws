# Deployment Guide

This guide walks you through deploying the complete k3s demo project on AWS.

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0
3. **kubectl** >= 1.25
4. **Helm** >= 3.0
5. **Docker** >= 20.0
6. **Go** >= 1.21 (for Terratest)

## Step 1: Environment Setup

### 1.1 Configure AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

### 1.2 Generate SSH Key Pair

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/k3s-demo
```

### 1.3 Set up GitHub Secrets

Add the following secrets to your GitHub repository:

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `SSH_PUBLIC_KEY`: Your SSH public key content
- `SLACK_WEBHOOK`: Slack webhook URL (optional)

## Step 2: Infrastructure Deployment

### 2.1 Initialize Terraform

```bash
cd terraform
terraform init
```

### 2.2 Plan Infrastructure

```bash
terraform plan -var="ssh_public_key=$(cat ~/.ssh/k3s-demo.pub)"
```

### 2.3 Deploy Infrastructure

```bash
terraform apply -var="ssh_public_key=$(cat ~/.ssh/k3s-demo.pub)"
```

### 2.4 Get Cluster Information

```bash
terraform output
```

## Step 3: Application Deployment

### 3.1 Build and Push Docker Image

```bash
# Build the image
docker build -t your-registry/python-app:latest ./app

# Push to registry
docker push your-registry/python-app:latest
```

### 3.2 Deploy via ArgoCD (Manual)

```bash
# Apply ArgoCD applications manually
kubectl apply -f argocd/app-of-apps.yaml
kubectl apply -f argocd/applications/
```

### 3.3 Verify Deployment

```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Check application pods
kubectl get pods -n python-app

# Check monitoring stack
kubectl get pods -n monitoring
```

## Step 4: Access the Application

### 4.1 Get Load Balancer URL

```bash
# Get the AWS load balancer DNS
kubectl get svc -n python-app
# or
terraform output load_balancer_dns
```

Access your application directly at: `http://<load-balancer-dns>`

### 4.2 Access ArgoCD UI

```bash
# Port forward ArgoCD from AWS cluster to your local machine
kubectl port-forward svc/argocd-server 8080:443 -n argocd

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Access ArgoCD at: https://localhost:8080
- Username: admin
- Password: (from command above)

### 4.3 Access Grafana

```bash
# Port forward Grafana from AWS cluster to your local machine
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
```

Access Grafana at: http://localhost:3000
- Username: admin
- Password: admin123

### 4.4 Access Prometheus

```bash
# Port forward Prometheus from AWS cluster to your local machine
kubectl port-forward svc/prometheus-operated 9090:9090 -n monitoring
```

Access Prometheus at: http://localhost:9090

## Step 5: Monitoring and Verification

### 5.1 Check Application Health

```bash
# Check application endpoints using the AWS load balancer URL
curl http://<load-balancer-dns>/health
curl http://<load-balancer-dns>/metrics
```

### 5.2 Monitor Logs

```bash
# Application logs
kubectl logs -f deployment/python-app -n python-app

# Redis logs
kubectl logs -f deployment/python-app-redis -n python-app
```

### 5.3 Check Metrics

```bash
# Port forward Prometheus (as shown in Step 4.4)
kubectl port-forward svc/prometheus-operated 9090:9090 -n monitoring
```

Then access Prometheus at: http://localhost:9090

## Step 6: Testing

### 6.1 Run Terratest

```bash
cd test/terraform
go test -v -timeout 30m
```

### 6.2 Load Testing

```bash
# Install hey (load testing tool)
go install github.com/rakyll/hey@latest

# Run load test against the AWS load balancer
hey -n 1000 -c 10 http://<load-balancer-dns>/
```

## Troubleshooting

### Common Issues

1. **Terraform State Lock**
   ```bash
   terraform force-unlock <lock-id>
   ```

2. **k3s Node Not Ready**
   ```bash
   # SSH to master node
   ssh -i ~/.ssh/k3s-demo ubuntu@<master-ip>
   
   # Check k3s status
   sudo systemctl status k3s
   sudo journalctl -u k3s -f
   ```

3. **Application Not Starting**
   ```bash
   # Check pod events
   kubectl describe pod <pod-name> -n python-app
   
   # Check logs
   kubectl logs <pod-name> -n python-app
   ```

4. **Redis Connection Issues**
   ```bash
   # Check Redis service
   kubectl get svc -n python-app
   
   # Test Redis connectivity
   kubectl exec -it <python-app-pod> -n python-app -- redis-cli -h python-app-redis ping
   ```

5. **Port Forwarding Issues**
   ```bash
   # Check if services are running
   kubectl get svc -n monitoring
   kubectl get svc -n argocd
   
   # Check if pods are ready
   kubectl get pods -n monitoring
   kubectl get pods -n argocd
   ```

### Useful Commands

```bash
# Get cluster info
kubectl cluster-info

# List all resources
kubectl get all --all-namespaces

# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -n python-app

# Scale application
kubectl scale deployment python-app --replicas=5 -n python-app

# Get AWS load balancer URL
terraform output load_balancer_dns
```

## Cleanup

### Destroy Infrastructure

```bash
cd terraform
terraform destroy -var="ssh_public_key=$(cat ~/.ssh/k3s-demo.pub)"
```

### Remove Applications

```bash
kubectl delete -f argocd/applications/
kubectl delete -f argocd/app-of-apps.yaml
```

## Security Considerations

1. **Network Security**: All traffic is routed through the load balancer
2. **Access Control**: Use IAM roles and policies for AWS access
3. **Secrets Management**: Store sensitive data in Kubernetes secrets
4. **Monitoring**: Prometheus and Grafana provide comprehensive monitoring
5. **Backup**: Regular backups of Terraform state and Kubernetes resources

## Performance Optimization

1. **Auto-scaling**: HPA is configured for CPU and memory
2. **Resource Limits**: Proper resource requests and limits set
3. **Caching**: Redis provides session and data caching
4. **Load Balancing**: Application load balancer distributes traffic
5. **Monitoring**: Real-time metrics and alerting

## Next Steps

1. **Custom Domain**: Configure custom domain with SSL certificates
2. **CI/CD Pipeline**: Set up automated deployments via GitHub Actions
3. **Monitoring Alerts**: Configure alerting rules in Prometheus
4. **Backup Strategy**: Implement automated backup solutions
5. **Security Scanning**: Add container and code security scanning 