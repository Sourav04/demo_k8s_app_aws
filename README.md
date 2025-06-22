# 🚀 Kubernetes Demo Project - Complete CI/CD Pipeline

> **A real-world example of modern cloud-native application deployment with GitOps, Infrastructure as Code, and automated CI/CD pipelines.**

This project demonstrates a production-ready Kubernetes setup with a Python Flask application, automated infrastructure provisioning using Terraform, modern CI/CD with GitHub Actions and ArgoCD, and comprehensive monitoring. Perfect for learning cloud-native development or as a template for your next project!

## 🌟 Live Demo

**Application**: [demok8sapp.xyz:8080](http://demok8sapp.xyz:8080)

> 💡 **Note**: The demo environment may be temporarily offline to save costs, but can be brought up on demand. The infrastructure is fully automated and can be deployed in minutes!

## 🎯 This project showcases:


- **Modern CI/CD**: Separate workflows for infrastructure and application deployment
- **GitOps**: ArgoCD for declarative application management
- **Infrastructure as Code**: Terraform for reproducible AWS infrastructure
- **Multi-stage Docker builds**: Optimized container images
- **Version tracking**: Complete traceability from code to deployment
- **Monitoring**: Prometheus metrics and health checks
- **Security**: Non-root containers, security scanning, and best practices



## 🛠️ Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Application** | Python Flask | Web application with visitor counter |
| **Container** | Multi-stage Docker | Optimized, secure container images |
| **Orchestration** | k3s on AWS | Lightweight Kubernetes cluster |
| **Infrastructure** | Terraform | Infrastructure as Code |
| **CI/CD** | GitHub Actions | Automated testing and deployment |
| **GitOps** | ArgoCD | Declarative application management |
| **Package Manager** | Helm | Kubernetes application packaging |
| **Monitoring** | Prometheus + Grafana | Metrics and observability |
| **Database** | Redis | Session storage and caching |

## 🚀 Quick Start

### Prerequisites

Make sure you have these tools installed:
- [AWS CLI](https://aws.amazon.com/cli/) (configured with credentials)
- [Terraform](https://www.terraform.io/) (>= 1.0)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Docker](https://www.docker.com/)
- [Helm](https://helm.sh/)

### 1. Clone and Explore

```bash
git clone <your-repo-url>
cd k3_demo
```

### 2. Set Up AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

### 3. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 4. Access Your Cluster

```bash
# Get kubeconfig (output from terraform)
kubectl get nodes
```

### 5. Deploy Application

The application will be automatically deployed via ArgoCD when you push changes to the repository!

## 📁 Project Structure

```
k3_demo/
├── 📁 app/                          # Python Flask application
│   ├── 📄 requirements.txt          # Python dependencies
│   └── 📁 src/
│       ├── 📄 app.py               # Main Flask application
│       └── 📁 templates/
│           └── 📄 index.html       # Web UI with version info
├── 📁 terraform/                    # Infrastructure as Code
│   ├── 📄 main.tf                  # Main Terraform configuration
│   ├── 📄 variables.tf             # Input variables
│   ├── 📄 outputs.tf               # Output values
│   └── 📁 templates/               # Terraform templates
├── 📁 helm/                         # Helm charts
│   └── 📁 python-app/              # Application Helm chart
├── 📁 argocd/                       # ArgoCD configurations
│   └── 📄 application.yaml         # ArgoCD application manifest
├── 📁 .github/                      # GitHub Actions workflows
│   └── 📁 workflows/
│       ├── 📄 infrastructure-provisioning.yml  # Terraform deployment
│       └── 📄 app-deployment.yml               # Application deployment
├── 📄 Dockerfile                    # Multi-stage Docker build
├── 📄 Makefile                      # Build automation
└── 📄 README.md                     # This file
```

## 🔄 CI/CD Pipeline

### Infrastructure Provisioning Workflow
**Trigger**: Changes to `terraform/` directory
- ✅ Terraform plan and apply
- ✅ k3s cluster setup on AWS
- ✅ ArgoCD installation
- ✅ Security scanning
- ✅ Slack notifications

### Application Deployment Workflow
**Trigger**: Changes to `app/`, `helm/`, or `argocd/` directories
- ✅ Unit testing and linting
- ✅ Security vulnerability scanning
- ✅ Multi-stage Docker build
- ✅ Version tagging and metadata
- ✅ ArgoCD deployment
- ✅ Health checks and monitoring

## 🐳 Docker Multi-Stage Build

Our Dockerfile uses a multi-stage approach for optimal security and size:

```dockerfile
# Stage 1: Builder (with gcc for compilation)
FROM python:3.11-slim as builder
# Install dependencies and build packages

# Stage 2: Runtime (clean, minimal)
FROM python:3.11-slim as runtime
# Copy only runtime packages, run as non-root user
```

**Benefits:**
- 🎯 **Smaller images** (no build tools in final image)
- 🔒 **Better security** (non-root user, minimal packages)
- ⚡ **Faster builds** (better layer caching)
- 📦 **Version tracking** (build args for traceability)

## 🔍 Monitoring & Observability

### Application Metrics
- **Visitor counter**: Real-time visitor tracking
- **Health checks**: `/health` endpoint with Redis status
- **Version info**: `/version` endpoint for deployment tracking
- **Prometheus metrics**: Custom metrics for monitoring

### Infrastructure Monitoring
- **Cluster health**: Node status and resource usage
- **Application status**: Pod health and readiness
- **ArgoCD sync**: GitOps deployment status
- **Cost tracking**: AWS resource monitoring

## 🎨 Features

### Web Application
- 🌐 **Modern UI**: Responsive design with version information
- 📊 **Real-time counter**: Redis-backed visitor tracking
- 🔄 **Auto-refresh**: Live updates every 30 seconds
- 📱 **Mobile-friendly**: Works on all devices
- 🎯 **Version display**: Shows build info and Git commit

### Infrastructure
- ☁️ **AWS integration**: EC2, VPC, Load Balancers
- 🚀 **k3s cluster**: Lightweight Kubernetes
- 🔒 **Security groups**: Network security
- 📈 **Auto-scaling**: Resource optimization
- 💰 **Cost-effective**: t3.small instances

### CI/CD Features
- 🤖 **Automated testing**: Unit tests and linting
- 🔍 **Security scanning**: Trivy vulnerability scanning
- 🐳 **Multi-stage builds**: Optimized Docker images
- 🏷️ **Version tagging**: Semantic versioning
- 📱 **Slack notifications**: Deployment status updates

## 🛡️ Security Features

- **Non-root containers**: Applications run as unprivileged users
- **Security scanning**: Automated vulnerability detection
- **Network policies**: Kubernetes network security
- **Secrets management**: Secure credential handling
- **RBAC**: Role-based access control

## 🧪 Testing

### Local Development
```bash
# Run tests
cd app
python -m pytest tests/ -v

# Build and test Docker image
docker build -t myapp .
docker run -p 5000:5000 myapp

# Test version endpoint
curl http://localhost:5000/version
```

### Infrastructure Testing
```bash
# Terraform validation
cd terraform
terraform validate
terraform plan

# Test cluster connectivity
kubectl get nodes
kubectl get pods -A
```

## 🚨 Troubleshooting

### Common Issues

**Port 5000 already in use:**
```bash
# Find and kill the process
lsof -ti:5000 | xargs kill -9
```

**Docker build fails:**
```bash
# Clean Docker cache
docker system prune -a
```

**Terraform apply fails:**
```bash
# Check AWS credentials
aws sts get-caller-identity
```

**ArgoCD sync issues:**
```bash
# Check ArgoCD status
kubectl get applications -n argocd
kubectl describe application python-app -n argocd
```



## 📞 Support

- 📧 **Email**: [sourav.dixit04@gmail.com]
- 🐛 **Issues**: [GitHub Issues](https://github.com/your-repo/issues)


---


*This project demonstrates modern DevOps practices and is perfect for learning or as a starting point for your own applications.*
