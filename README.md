# Kubernetes Sample Project with k3s on AWS

This project demonstrates a complete Kubernetes setup with a Python Flask application, infrastructure as code using Terraform, CI/CD with GitHub Actions and ArgoCD, and monitoring with Prometheus.

## Project Components

- **Python Flask App**: Simple web application with visitor counter
- **Terraform Infrastructure**: AWS k3s cluster on t3.micro instances
- **GitHub Actions CI/CD**: Automated testing and deployment with Terratest
- **ArgoCD**: GitOps deployment management
- **Helm Charts**: Application packaging and deployment
- **Prometheus Stack**: Monitoring and alerting

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │    │   Terraform     │    │   ArgoCD        │
│                 │    │   Infrastructure │    │   GitOps        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  GitHub Actions │    │   AWS k3s       │    │   Helm Charts   │
│  CI/CD Pipeline │    │   Cluster       │    │   Application   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Terratest     │    │   Python App    │    │   Prometheus    │
│   Testing       │    │   (Flask)       │    │   Monitoring    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- kubectl
- helm
- Docker
- Go (for Terratest)

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd k3_demo
   ```

2. **Set up AWS credentials**
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-west-2"
   ```

3. **Deploy infrastructure**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

4. **Install ArgoCD**
   ```bash
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

5. **Deploy the application**
   ```bash
   kubectl apply -f argocd/app-of-apps.yaml
   ```

## Project Structure

```
k3_demo/
├── app/                    # Python Flask application
│   ├── Dockerfile
│   ├── requirements.txt
│   └── src/
├── terraform/              # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
├── helm/                   # Helm charts
│   ├── python-app/
│   └── monitoring/
├── argocd/                 # ArgoCD configurations
│   ├── app-of-apps.yaml
│   └── applications/
├── .github/                # GitHub Actions workflows
│   └── workflows/
├── test/                   # Terratest tests
│   └── terraform/
└── docs/                   # Documentation
```

## Features

### Python Application
- Flask-based web application
- Redis-backed visitor counter
- Health check endpoints
- Prometheus metrics

### Infrastructure
- k3s cluster on AWS EC2 t3.micro instances
- Auto-scaling node groups
- Load balancer configuration
- VPC and security groups

### CI/CD Pipeline
- Automated testing with Terratest
- Docker image building and pushing
- Helm chart validation
- Infrastructure testing

### Monitoring
- Prometheus metrics collection
- Grafana dashboards
- Alert manager configuration
- Custom metrics for the application

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details 