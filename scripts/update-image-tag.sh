#!/bin/bash

# Script to update image tag in GitOps repository
# This script is called by the CI/CD pipeline after building a new image

set -e

# Configuration
GITOPS_REPO="https://github.com/souravdixit04/k3_demo.git"
GITOPS_BRANCH="main"
VALUES_FILE="helm/python-app/values.yaml"
IMAGE_NAME="souravdixit04/demo_k8s_app_aws"
NEW_TAG="$1"

if [ -z "$NEW_TAG" ]; then
    echo "Error: No image tag provided"
    echo "Usage: $0 <image-tag>"
    exit 1
fi

echo "Updating image tag to: $NEW_TAG"

# Clone the GitOps repository
git clone --depth 1 --branch $GITOPS_BRANCH $GITOPS_REPO gitops-repo
cd gitops-repo

# Update the image tag in values.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|tag: \".*\"|tag: \"$NEW_TAG\"|g" $VALUES_FILE
else
    # Linux
    sed -i "s|tag: \".*\"|tag: \"$NEW_TAG\"|g" $VALUES_FILE
fi

# Verify the change
echo "Updated values.yaml:"
grep -A 2 -B 2 "tag:" $VALUES_FILE

# Commit and push the changes
git config user.name "GitHub Actions"
git config user.email "actions@github.com"
git add $VALUES_FILE
git commit -m "Update image tag to $NEW_TAG [skip ci]"
git push origin $GITOPS_BRANCH

echo "Successfully updated image tag to $NEW_TAG"
echo "ArgoCD will automatically sync the changes" 