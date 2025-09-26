#!/bin/bash

# Demo script showing the complete amp-uat namespace setup workflow
# This script demonstrates all the available deployment methods

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}============================================${NC}"
    echo -e "${BLUE} $1 ${NC}"
    echo -e "${BLUE}============================================${NC}\n"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header "amp-uat Namespace Configuration Demo"

print_status "This demo shows how to deploy the amp-uat namespace with Istio sidecar injection disabled."
print_status "Available deployment methods:"
echo ""
echo "1. Using the automated deployment script (Recommended)"
echo "2. Using kubectl directly"
echo "3. Using Helm (as part of KubeSphere installation)"
echo ""

read -p "Press Enter to continue..."

print_header "Method 1: Automated Deployment Script"

print_status "Running the automated deployment script..."
echo ""

if [[ -f "${SCRIPT_DIR}/deploy-amp-uat-namespace.sh" ]]; then
    "${SCRIPT_DIR}/deploy-amp-uat-namespace.sh"
else
    print_error "Deployment script not found!"
    exit 1
fi

echo ""
read -p "Press Enter to continue to testing..."

print_header "Running Tests"

print_status "Running comprehensive tests to validate the configuration..."
echo ""

if [[ -f "${SCRIPT_DIR}/test-amp-uat-namespace.sh" ]]; then
    "${SCRIPT_DIR}/test-amp-uat-namespace.sh"
else
    print_error "Test script not found!"
    exit 1
fi

print_header "Method 2: Direct kubectl Application"

print_status "Showing how to apply the manifest directly with kubectl..."
echo ""

MANIFEST_PATH="${SCRIPT_DIR}/../config/manifests/amp-uat-namespace.yaml"
if [[ -f "$MANIFEST_PATH" ]]; then
    echo "Command: kubectl apply -f $MANIFEST_PATH"
    echo ""
    echo "Manifest content:"
    echo "----------------------------------------"
    cat "$MANIFEST_PATH"
    echo "----------------------------------------"
else
    print_error "Manifest file not found!"
fi

print_header "Method 3: Helm Integration"

print_status "Showing Helm template integration..."
echo ""

echo "The amp-uat namespace can be deployed as part of KubeSphere installation by:"
echo ""
echo "1. Setting ampUat.enabled=true in values.yaml:"
echo "   ampUat:"
echo "     enabled: true"
echo "     workspace: \"system-workspace\""
echo "     creator: \"system\""
echo ""
echo "2. Installing/upgrading with Helm:"
echo "   helm upgrade --install ks-core config/ks-core -n kubesphere-system"
echo ""

print_header "Verification Commands"

print_status "Use these commands to verify the setup:"
echo ""
echo "# Check namespace labels:"
echo "kubectl get namespace amp-uat --show-labels"
echo ""
echo "# Verify istio-injection is disabled:"
echo "kubectl get namespace amp-uat -o jsonpath='{.metadata.labels.istio-injection}'"
echo ""
echo "# Check KubeSphere integration:"
echo "kubectl get namespace amp-uat -o yaml"
echo ""
echo "# Deploy a test pod and verify no sidecar:"
echo "kubectl run test-pod --image=nginx:alpine -n amp-uat"
echo "kubectl get pod test-pod -n amp-uat -o jsonpath='{.spec.containers[*].name}'"
echo "kubectl delete pod test-pod -n amp-uat"
echo ""

print_header "Documentation"

print_status "Complete documentation is available at:"
echo "docs/amp-uat-istio-disable.md"
echo ""
print_status "Manifest directory README:"
echo "config/manifests/README.md"
echo ""

print_header "Demo Complete"

print_status "The amp-uat namespace is now configured with Istio sidecar injection disabled."
print_status "All new pods deployed to this namespace will not have Envoy sidecars injected automatically."
print_warning "Remember to restart existing pods if they need to remove existing sidecars."
echo ""
print_status "Thank you for using the amp-uat namespace configuration!"