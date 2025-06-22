#!/bin/bash

# Script to create cluster-info.json from existing infrastructure
# This is useful when the infrastructure workflow artifacts are not available

set -e

echo "🔍 Creating cluster-info.json from existing infrastructure..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Create terraform directory if it doesn't exist
mkdir -p terraform

# Look for running k3s demo instances
echo "📋 Searching for running k3s demo infrastructure..."

INSTANCES=$(aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=k3s-demo" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
  --output text)

if [ -z "$INSTANCES" ]; then
    echo "❌ No running k3s demo infrastructure found."
    echo "Please ensure the infrastructure is deployed first."
    exit 1
fi

echo "✅ Found running instances:"
echo "$INSTANCES"

# Extract master instance ID (assuming first instance is master)
MASTER_INSTANCE_ID=$(echo "$INSTANCES" | head -1 | cut -f1)
echo "🎯 Using master instance: $MASTER_INSTANCE_ID"

# Look for Load Balancer
echo "🔍 Searching for Load Balancer..."
LB_DNS=$(aws elbv2 describe-load-balancers \
  --names k3s-demo-cluster-api-lb \
  --query 'LoadBalancers[0].DNSName' \
  --output text 2>/dev/null || echo "")

if [ -z "$LB_DNS" ] || [ "$LB_DNS" = "None" ]; then
    echo "❌ Load Balancer 'k3s-demo-cluster-api-lb' not found."
    echo "Please ensure the infrastructure is properly deployed."
    exit 1
fi

echo "✅ Found Load Balancer: $LB_DNS"

# Create cluster-info.json
echo "📝 Creating cluster-info.json..."
cat > terraform/cluster-info.json << EOF
{
  "kubernetes_api_lb": {
    "value": "$LB_DNS"
  },
  "master_instance_id": {
    "value": "$MASTER_INSTANCE_ID"
  }
}
EOF

echo "✅ Successfully created terraform/cluster-info.json"
echo "📋 Cluster Information:"
echo "   Load Balancer: $LB_DNS"
echo "   Master Instance: $MASTER_INSTANCE_ID"

# Test cluster connectivity
echo "🔗 Testing cluster connectivity..."
if command -v kubectl > /dev/null 2>&1; then
    # Get kubeconfig from master node
    echo "📥 Getting kubeconfig from master node..."
    
    aws ssm send-command \
      --instance-ids "$MASTER_INSTANCE_ID" \
      --document-name "AWS-RunShellScript" \
      --parameters 'commands=[
        "sudo cat /etc/rancher/k3s/k3s.yaml"
      ]' \
      --query 'Command.CommandId' \
      --output text > kubeconfig_command_id.txt
    
    KUBECONFIG_COMMAND_ID=$(cat kubeconfig_command_id.txt)
    echo "⏳ Waiting for kubeconfig command to complete..."
    sleep 10
    
    # Get the kubeconfig content
    aws ssm get-command-invocation \
      --command-id "$KUBECONFIG_COMMAND_ID" \
      --instance-id "$MASTER_INSTANCE_ID" \
      --query 'StandardOutputContent' \
      --output text > kubeconfig_original
    
    # Update the kubeconfig with the Load Balancer URL
    sed "s|server: https://127.0.0.1:6443|server: https://$LB_DNS:6443|g" kubeconfig_original > kubeconfig
    
    # Add insecure-skip-tls-verify to cluster section and remove certificate authority
    sed -i '/cluster:/a\    insecure-skip-tls-verify: true' kubeconfig
    sed -i '/certificate-authority-data:/d' kubeconfig
    
    echo "✅ Kubeconfig updated with Load Balancer URL: https://$LB_DNS:6443"
    
    # Test cluster connectivity
    export KUBECONFIG=./kubeconfig
    echo "🔗 Testing cluster connectivity..."
    if kubectl get nodes > /dev/null 2>&1; then
        echo "✅ Cluster connectivity successful!"
        echo "📋 Cluster nodes:"
        kubectl get nodes
    else
        echo "⚠️  Cluster connectivity test failed, but cluster-info.json was created."
        echo "   You may need to wait a few minutes for the cluster to be fully ready."
    fi
else
    echo "⚠️  kubectl not found. Skipping connectivity test."
    echo "   Cluster info created successfully."
fi

echo ""
echo "🎉 Done! You can now run the application deployment workflow."
echo "📁 Files created:"
echo "   - terraform/cluster-info.json"
echo "   - kubeconfig (if kubectl was available)" 