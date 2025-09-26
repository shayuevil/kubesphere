# Disabling Istio Sidecar Injection for amp-uat Namespace

This document describes how to disable Istio sidecar proxy injection for the `amp-uat` namespace in KubeSphere.

## Overview

The `amp-uat` namespace has been configured to disable automatic Istio sidecar injection by adding the `istio-injection: disabled` label. This prevents Istio from automatically injecting Envoy sidecar proxies into pods deployed in this namespace.

## Files Modified/Added

### 1. Helm Template
- **File**: `config/ks-core/templates/amp-uat-namespace.yaml`
- **Purpose**: Helm template for the amp-uat namespace with istio-injection disabled
- **Usage**: Deployed as part of the KubeSphere core installation

### 2. Standalone Manifest
- **File**: `config/manifests/amp-uat-namespace.yaml`
- **Purpose**: Standalone Kubernetes manifest for direct kubectl application
- **Usage**: Can be applied independently of the Helm chart

### 3. Deployment Script
- **File**: `scripts/deploy-amp-uat-namespace.sh`
- **Purpose**: Automated deployment script with validation and pod restart guidance
- **Usage**: Run this script to deploy and verify the namespace configuration

### 4. Values Configuration
- **File**: `config/ks-core/values.yaml`
- **Purpose**: Added `ampUat` configuration section to enable/disable the namespace deployment

## Deployment Methods

### Method 1: Using Helm (Recommended for KubeSphere installations)

If you're deploying KubeSphere using Helm, the amp-uat namespace will be created automatically if enabled in values:

```yaml
ampUat:
  enabled: true
  workspace: "system-workspace"
  creator: "system"
```

Deploy with:
```bash
helm upgrade --install ks-core config/ks-core -n kubesphere-system
```

### Method 2: Using kubectl (Standalone)

Apply the namespace manifest directly:

```bash
kubectl apply -f config/manifests/amp-uat-namespace.yaml
```

### Method 3: Using the Deployment Script (Recommended)

The deployment script provides additional validation and guidance:

```bash
./scripts/deploy-amp-uat-namespace.sh
```

This script will:
- Validate kubectl connectivity
- Apply the namespace configuration
- Verify the istio-injection label is set correctly
- Check for existing pods and provide restart guidance if needed

## Namespace Configuration

The `amp-uat` namespace is configured with the following metadata:

```yaml
metadata:
  name: amp-uat
  labels:
    istio-injection: disabled           # Disables Istio sidecar injection
    kubesphere.io/workspace: system-workspace
    kubesphere.io/managed: "true"
  annotations:
    kubesphere.io/description: "AMP UAT namespace with Istio sidecar injection disabled"
    kubesphere.io/creator: system
```

## Handling Existing Pods

If there are existing pods in the `amp-uat` namespace when the label is applied, they may still have Istio sidecar containers. To remove existing sidecars:

### Option 1: Restart All Pods
```bash
kubectl delete pods --all -n amp-uat
```

### Option 2: Restart Specific Deployments
```bash
kubectl rollout restart deployment <deployment-name> -n amp-uat
kubectl rollout restart statefulset <statefulset-name> -n amp-uat
```

### Option 3: Scale Down and Up
```bash
kubectl scale deployment <deployment-name> --replicas=0 -n amp-uat
kubectl scale deployment <deployment-name> --replicas=<original-count> -n amp-uat
```

## Verification

### 1. Check Namespace Labels
```bash
kubectl get namespace amp-uat --show-labels
```

Verify that `istio-injection=disabled` is present in the labels.

### 2. Check Pod Sidecar Status
```bash
kubectl get pods -n amp-uat -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'
```

Pods without Istio sidecars should not have an `istio-proxy` container.

### 3. Test New Pod Deployment
Deploy a test pod to verify sidecar injection is disabled:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: amp-uat
spec:
  containers:
  - name: test
    image: nginx:alpine
    ports:
    - containerPort: 80
```

Apply and check that only the main container is present:
```bash
kubectl apply -f test-pod.yaml
kubectl get pod test-pod -n amp-uat -o jsonpath='{.spec.containers[*].name}'
```

## Troubleshooting

### Issue: Namespace still shows istio-injection=enabled
**Solution**: Ensure you've applied the correct manifest and the label is properly set:
```bash
kubectl label namespace amp-uat istio-injection=disabled --overwrite
```

### Issue: Existing pods still have sidecars
**Solution**: Restart the affected pods as described in the "Handling Existing Pods" section.

### Issue: New pods still get sidecar injection
**Possible causes**:
1. Istio is configured for global injection
2. Pod-level annotations are overriding namespace settings
3. Admission webhook configuration issues

**Solution**: Check Istio configuration and pod annotations:
```bash
kubectl get pod <pod-name> -n amp-uat -o yaml | grep -A 10 -B 10 sidecar
```

## Security Considerations

- Disabling Istio sidecar injection removes automatic mTLS, traffic management, and observability features for pods in this namespace
- Ensure that security policies and network policies are appropriately configured for the amp-uat namespace
- Consider implementing alternative security measures if Istio's features are required

## References

- [Istio Sidecar Injection Documentation](https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/)
- [KubeSphere Namespace Management](https://kubesphere.io/docs/)
- [Kubernetes Namespace Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)