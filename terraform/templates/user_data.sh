#!/bin/bash

# k3s Installation Script
# This script installs and configures k3s on Ubuntu 22.04

set -e

# Variables
CLUSTER_NAME="${cluster_name}"
NODE_TYPE="${node_type}"
K3S_VERSION="v1.28.5+k3s1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "$${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1$${NC}"
}

warn() {
    echo -e "$${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1$${NC}"
}

error() {
    echo -e "$${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1$${NC}"
}

# Update system
log "Updating system packages..."
yum update -y
yum upgrade -y

# Install required packages
log "Installing required packages..."
yum install -y \
    curl \
    wget \
    git \
    unzip \
    ca-certificates \
    gnupg2 \
    htop \
    vim \
    net-tools \
    traceroute \
    bind-utils

# Disable swap
log "Disabling swap..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
log "Loading required kernel modules..."
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Set kernel parameters
log "Setting kernel parameters..."
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# Install Docker
log "Installing Docker..."
yum install -y docker
systemctl enable docker
systemctl start docker

# Configure Docker
mkdir -p /etc/docker
cat <<EOF | tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl restart docker

# Install k3s
log "Installing k3s..."
# Note: TLS certificate will need to be updated later to include Load Balancer DNS
# For now, we'll use basic configuration and update certificate later
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$${K3S_VERSION} INSTALL_K3S_EXEC="--tls-san 0.0.0.0 --bind-address 0.0.0.0 --tls-san localhost --tls-san kubernetes --tls-san kubernetes.default --tls-san kubernetes.default.svc --tls-san kubernetes.default.svc.cluster.local" sh -

# Wait for k3s to be ready
log "Waiting for k3s to be ready..."
sleep 30

# Check if k3s is running
log "Checking k3s status..."
if ! systemctl is-active --quiet k3s; then
    log "k3s service is not running. Checking logs..."
    journalctl -u k3s --no-pager | tail -n 20
    exit 1
fi

log "k3s is running successfully!"

# Configure k3s based on node type
if [ "$NODE_TYPE" = "master" ]; then
    log "Configuring k3s master node..."
    
    # Get the node token for workers
    NODE_TOKEN=$$(cat /var/lib/rancher/k3s/server/node-token)
    
    # Create a file with the token for easy access
    echo "$${NODE_TOKEN}" > /home/ec2-user/node-token
    chown ec2-user:ec2-user /home/ec2-user/node-token
    
    # Install kubectl
    ln -s /usr/local/bin/k3s kubectl
    
    # Install Helm
    log "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    # Install ArgoCD
    if [ "${enable_argocd}" = "true" ]; then
        log "Installing ArgoCD..."
        
        # Create namespace
        kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
        
        # Install ArgoCD with resource limits for small instances
        log "Applying ArgoCD manifests..."
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        # Wait for ArgoCD to be ready
        log "Waiting for ArgoCD to be ready..."
        kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd || {
            log "ArgoCD server deployment failed to become ready. Checking logs..."
            kubectl logs -n argocd deployment/argocd-server --tail=20
            log "Continuing with installation..."
        }
        
        # Scale down ArgoCD for resource efficiency on small instances
        log "Scaling ArgoCD for resource efficiency..."
        kubectl scale deployment argocd-server -n argocd --replicas=1
        kubectl scale deployment argocd-repo-server -n argocd --replicas=1
        kubectl scale deployment argocd-application-controller -n argocd --replicas=1
        
        # Wait for scaled deployments to be ready
        kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
        kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argocd
        kubectl wait --for=condition=available --timeout=300s deployment/argocd-application-controller -n argocd
        
        log "ArgoCD installation completed successfully!"
        
        # Get ArgoCD admin password
        ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "password-not-available-yet")
        echo "ArgoCD admin password: $ARGOCD_PASSWORD" > /home/ec2-user/argocd-password.txt
        chown ec2-user:ec2-user /home/ec2-user/argocd-password.txt
        chmod 600 /home/ec2-user/argocd-password.txt
        
        log "ArgoCD admin password saved to /home/ec2-user/argocd-password.txt"
    else
        log "ArgoCD installation skipped (enable_argocd=false)"
    fi
    
    # Install monitoring stack if enabled
    if [ "${enable_monitoring}" = "true" ]; then
        log "Installing monitoring stack..."
        
        # Add Prometheus Helm repository
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo update
        
        # Install Prometheus stack
        kubectl create namespace monitoring
        helm install prometheus prometheus-community/kube-prometheus-stack \
            --namespace monitoring \
            --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
            --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
            --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false \
            --set grafana.enabled=true \
            --set grafana.adminPassword=admin123 \
            --set grafana.service.type=LoadBalancer
    fi
    
    # Create a script to get cluster info
    cat <<'EOF' > /home/ec2-user/cluster-info.sh
#!/bin/bash
echo "=== k3s Cluster Information ==="
echo "Cluster Name: $${CLUSTER_NAME}"
echo "Master Node IP: $(hostname -I | awk '{print $1}')"
echo "k3s Version: $(k3s --version)"
echo ""
echo "=== Node Information ==="
kubectl get nodes -o wide
echo ""
echo "=== Pod Information ==="
kubectl get pods --all-namespaces
echo ""
echo "=== Services ==="
kubectl get services --all-namespaces
echo ""
echo "=== Node Token (for worker nodes) ==="
cat /home/ec2-user/node-token
echo ""
echo "=== kubeconfig ==="
echo "To get kubeconfig, run: sudo cat /etc/rancher/k3s/k3s.yaml"
echo ""
echo "=== ArgoCD Access ==="
echo "ArgoCD UI: http://$(hostname -I | awk '{print $1}'):8080"
echo "Username: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d)"
EOF
    
    chmod +x /home/ec2-user/cluster-info.sh
    chown ec2-user:ec2-user /home/ec2-user/cluster-info.sh
    
else
    log "Configuring k3s worker node..."
    
    # Wait for master to be ready and get token
    log "Waiting for master node to be available..."
    sleep 60
    
    # Get the master node IP (this would be configured via user data or external means)
    # For demo purposes, we'll assume the master is available
    MASTER_IP=$$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
    
    # Join the cluster
    log "Joining k3s cluster..."
    curl -sfL https://get.k3s.io | K3S_URL=https://$${MASTER_IP}:6443 K3S_TOKEN=$${NODE_TOKEN} sh -
fi

# Create systemd service for k3s
log "Creating systemd service for k3s..."
systemctl enable k3s

# Set up log rotation
log "Setting up log rotation..."
cat <<EOF | tee /etc/logrotate.d/k3s
/var/log/k3s.log {
    rotate 7
    daily
    missingok
    notifempty
    compress
    postrotate
        systemctl reload k3s
    endscript
}
EOF

# Create monitoring script
cat <<'EOF' > /home/ec2-user/monitor.sh
#!/bin/bash
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime)"
echo "Load Average: $(cat /proc/loadavg)"
echo ""
echo "=== Memory Usage ==="
free -h
echo ""
echo "=== Disk Usage ==="
df -h
echo ""
echo "=== Docker Status ==="
systemctl status docker --no-pager
echo ""
echo "=== k3s Status ==="
systemctl status k3s --no-pager
EOF

chmod +x /home/ec2-user/monitor.sh
chown ec2-user:ec2-user /home/ec2-user/monitor.sh

# Set up firewall rules
log "Skipping UFW firewall setup (not available on Amazon Linux)"

# Final system update
log "Performing final system update..."
yum update -y
yum upgrade -y

# Clean up
log "Cleaning up..."
yum autoremove -y
yum clean all

log "k3s installation completed successfully!"
log "Node type: $NODE_TYPE"
log "Cluster name: $CLUSTER_NAME"

if [ "$NODE_TYPE" = "master" ]; then
    log "Master node setup complete!"
    log "Run '/home/ec2-user/cluster-info.sh' to see cluster information"
else
    log "Worker node setup complete!"
fi

# Reboot to ensure all changes take effect
log "Rebooting system in 30 seconds..."
sleep 30
reboot 