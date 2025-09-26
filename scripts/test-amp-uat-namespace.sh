#!/bin/bash

# Test script to validate amp-uat namespace configuration
# This script tests that the amp-uat namespace has Istio sidecar injection disabled

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

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    print_status "Running test: $test_name"
    
    if eval "$test_command"; then
        print_success "✓ $test_name"
        ((TESTS_PASSED++))
    else
        print_error "✗ $test_name"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

print_status "Starting amp-uat namespace tests..."
echo ""

# Test 1: Check if namespace exists
run_test "Namespace amp-uat exists" "kubectl get namespace amp-uat > /dev/null 2>&1"

# Test 2: Check if istio-injection label is set to disabled
run_test "istio-injection label is disabled" "kubectl get namespace amp-uat -o jsonpath='{.metadata.labels.istio-injection}' | grep -q 'disabled'"

# Test 3: Check if kubesphere workspace label exists
run_test "KubeSphere workspace label exists" "kubectl get namespace amp-uat -o jsonpath='{.metadata.labels.kubesphere\.io/workspace}' | grep -q 'system-workspace'"

# Test 4: Check if kubesphere managed label exists
run_test "KubeSphere managed label exists" "kubectl get namespace amp-uat -o jsonpath='{.metadata.labels.kubesphere\.io/managed}' | grep -q 'true'"

# Test 5: Check namespace annotations
run_test "Namespace description annotation exists" "kubectl get namespace amp-uat -o jsonpath='{.metadata.annotations.kubesphere\.io/description}' | grep -q 'AMP UAT namespace'"

# Test 6: Deploy test pod and verify no sidecar injection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_POD_MANIFEST="${SCRIPT_DIR}/../test/manifests/test-amp-uat-namespace.yaml"

if [[ -f "$TEST_POD_MANIFEST" ]]; then
    print_status "Deploying test pod to verify sidecar injection is disabled..."
    
    # Clean up any existing test pod
    kubectl delete -f "$TEST_POD_MANIFEST" --ignore-not-found=true > /dev/null 2>&1
    
    # Deploy test pod
    if kubectl apply -f "$TEST_POD_MANIFEST" > /dev/null 2>&1; then
        # Wait for pod to be ready
        kubectl wait --for=condition=Ready pod/test-no-sidecar -n amp-uat --timeout=60s > /dev/null 2>&1 || true
        
        # Test 7: Check that pod has only one container (no sidecar)
        run_test "Test pod has no Istio sidecar" "[ \$(kubectl get pod test-no-sidecar -n amp-uat -o jsonpath='{.spec.containers[*].name}' | wc -w) -eq 1 ]"
        
        # Test 8: Verify no istio-proxy container
        run_test "No istio-proxy container present" "! kubectl get pod test-no-sidecar -n amp-uat -o jsonpath='{.spec.containers[*].name}' | grep -q 'istio-proxy'"
        
        # Clean up test pod
        kubectl delete -f "$TEST_POD_MANIFEST" --ignore-not-found=true > /dev/null 2>&1
        print_status "Test pod cleaned up"
    else
        print_error "Failed to deploy test pod"
        ((TESTS_FAILED++))
    fi
else
    print_warning "Test pod manifest not found, skipping pod deployment tests"
fi

echo ""
print_status "Test Summary:"
print_success "Tests passed: $TESTS_PASSED"
if [[ $TESTS_FAILED -gt 0 ]]; then
    print_error "Tests failed: $TESTS_FAILED"
    exit 1
else
    print_success "All tests passed!"
    print_success "amp-uat namespace is correctly configured with Istio sidecar injection disabled"
fi