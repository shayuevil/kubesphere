# KubeSphere Manifests

This directory contains standalone Kubernetes manifests that can be applied directly with `kubectl`.

## amp-uat Namespace

### File: `amp-uat-namespace.yaml`

This manifest creates the `amp-uat` namespace with Istio sidecar injection disabled.

**Key Features:**
- `istio-injection: disabled` label prevents automatic Envoy sidecar injection
- Integrated with KubeSphere workspace management
- Proper annotations for KubeSphere compatibility

**Quick deployment:**
```bash
kubectl apply -f amp-uat-namespace.yaml
```

**For automated deployment with validation, use:**
```bash
../../scripts/deploy-amp-uat-namespace.sh
```

**For testing and validation:**
```bash
../../scripts/test-amp-uat-namespace.sh
```

See the complete documentation at: `../../docs/amp-uat-istio-disable.md`