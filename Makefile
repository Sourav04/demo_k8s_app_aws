.PHONY: help build test deploy clean docker-build docker-push terraform-init terraform-plan terraform-apply terraform-destroy helm-install helm-uninstall argocd-install argocd-uninstall

# Default target
help:
	@echo "Available commands:"
	@echo "  build          - Build the Python application"
	@echo "  test           - Run tests (Python and Terratest)"
	@echo "  docker-build   - Build Docker image"
	@echo "  docker-push    - Push Docker image to registry"
	@echo "  terraform-init - Initialize Terraform"
	@echo "  terraform-plan - Plan Terraform changes"
	@echo "  terraform-apply - Apply Terraform changes"
	@echo "  terraform-destroy - Destroy Terraform infrastructure"
	@echo "  helm-install   - Install application via Helm"
	@echo "  helm-uninstall - Uninstall application via Helm"
	@echo "  argocd-install - Install ArgoCD applications"
	@echo "  argocd-uninstall - Uninstall ArgoCD applications"
	@echo "  deploy         - Full deployment pipeline"
	@echo "  clean          - Clean up build artifacts"

# Build the Python application
build:
	@echo "Building Python application..."
	cd app && pip install -r requirements.txt

# Run tests
test:
	@echo "Running Python tests..."
	cd app && python -m pytest tests/ -v
	@echo "Running Terratest..."
	cd test/terraform && go test -v -timeout 30m

# Docker commands
docker-build:
	@echo "Building Docker image..."
	docker build -t python-app:latest ./app

docker-push:
	@echo "Pushing Docker image..."
	docker tag python-app:latest your-registry/python-app:latest
	docker push your-registry/python-app:latest

# Terraform commands
terraform-init:
	@echo "Initializing Terraform..."
	cd terraform && terraform init

terraform-plan:
	@echo "Planning Terraform changes..."
	cd terraform && terraform plan

terraform-apply:
	@echo "Applying Terraform changes..."
	cd terraform && terraform apply -auto-approve

terraform-destroy:
	@echo "Destroying Terraform infrastructure..."
	cd terraform && terraform destroy -auto-approve

# Helm commands
helm-install:
	@echo "Installing application via Helm..."
	helm install python-app ./helm/python-app

helm-uninstall:
	@echo "Uninstalling application via Helm..."
	helm uninstall python-app

# ArgoCD commands
argocd-install:
	@echo "Installing ArgoCD applications..."
	kubectl apply -f argocd/app-of-apps.yaml
	kubectl apply -f argocd/applications/

argocd-uninstall:
	@echo "Uninstalling ArgoCD applications..."
	kubectl delete -f argocd/applications/
	kubectl delete -f argocd/app-of-apps.yaml

# Full deployment pipeline
deploy: build docker-build docker-push terraform-apply argocd-install
	@echo "Deployment completed!"

# Clean up
clean:
	@echo "Cleaning up build artifacts..."
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf app/.pytest_cache
	rm -rf app/coverage.xml
	rm -rf app/htmlcov

# Development helpers
dev-setup:
	@echo "Setting up development environment..."
	python -m pip install --upgrade pip
	pip install -r app/requirements.txt
	pip install pytest pytest-cov flake8 black isort
	cd test/terraform && go mod tidy

lint:
	@echo "Running linting..."
	cd app && flake8 src/ --count --select=E9,F63,F7,F82 --show-source --statistics
	cd app && flake8 src/ --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics
	cd app && black --check src/
	cd app && isort --check-only src/

format:
	@echo "Formatting code..."
	cd app && black src/
	cd app && isort src/

# Monitoring helpers
monitor-logs:
	@echo "Monitoring application logs..."
	kubectl logs -f deployment/python-app -n python-app

monitor-metrics:
	@echo "Accessing Prometheus metrics..."
	kubectl port-forward svc/prometheus-operated 9090:9090 -n monitoring

monitor-grafana:
	@echo "Accessing Grafana dashboard..."
	kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring

# Cluster management
cluster-info:
	@echo "Getting cluster information..."
	kubectl cluster-info
	kubectl get nodes -o wide
	kubectl get pods --all-namespaces

cluster-logs:
	@echo "Getting cluster logs..."
	kubectl logs -f deployment/argocd-server -n argocd

# Backup and restore
backup:
	@echo "Creating backup..."
	mkdir -p backups/$(shell date +%Y%m%d_%H%M%S)
	cd terraform && terraform output -json > ../backups/$(shell date +%Y%m%d_%H%M%S)/terraform-output.json
	kubectl get all --all-namespaces -o yaml > backups/$(shell date +%Y%m%d_%H%M%S)/k8s-backup.yaml

# Security scanning
security-scan:
	@echo "Running security scan..."
	trivy fs --severity HIGH,CRITICAL .
	trivy image --severity HIGH,CRITICAL python-app:latest 