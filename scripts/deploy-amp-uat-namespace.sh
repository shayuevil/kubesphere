#!/bin/bash

# Deploy AMP UAT namespace with Istio sidecar injection disabled
# This script applies the amp-uat namespace configuration and handles existing pods

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to Kubernetes cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

print_status "Deploying amp-uat namespace with Istio sidecar injection disabled..."

# Apply the namespace configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_PATH="${SCRIPT_DIR}/../config/manifests/amp-uat-namespace.yaml"

if [[ ! -f "$MANIFEST_PATH" ]]; then
    print_error "Namespace manifest not found at: $MANIFEST_PATH"
    exit 1
fi

# Apply the namespace
kubectl apply -f "$MANIFEST_PATH"

# Check if namespace was created successfully
if kubectl get namespace amp-uat &> /dev/null; then
    print_status "amp-uat namespace created/updated successfully"
    
    # Display namespace labels to verify istio-injection=disabled
    print_status "Namespace labels:"
    kubectl get namespace amp-uat -o jsonpath='{.metadata.labels}' | jq .
    
    # Check for existing pods in the namespace
    POD_COUNT=$(kubectl get pods -n amp-uat --no-headers 2>/dev/null | wc -l)
    
    if [[ $POD_COUNT -gt 0 ]]; then
        print_warning "Found $POD_COUNT existing pod(s) in amp-uat namespace."
        print_warning "These pods may still have Istio sidecar containers."
        print_warning "To remove existing sidecars, you may need to restart the pods:"
        echo ""
        echo "  kubectl get pods -n amp-uat"
        echo "  kubectl delete pods --all -n amp-uat  # This will restart all pods"
        echo ""
        print_warning "Alternatively, restart individual deployments/statefulsets:"
        echo "  kubectl rollout restart deployment <deployment-name> -n amp-uat"
        echo "  kubectl rollout restart statefulset <statefulset-name> -n amp-uat"
    else
        print_status "No existing pods found in amp-uat namespace."
        print_status "New pods deployed to this namespace will not have Istio sidecars injected."
    fi
    
else
    print_error "Failed to create amp-uat namespace"
    exit 1
fi

print_status "Deployment completed successfully!"
print_status "Istio sidecar injection is now disabled for the amp-uat namespace."