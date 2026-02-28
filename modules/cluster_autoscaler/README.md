# Cluster Autoscaler Module

## Overview

This module deploys **Cluster Autoscaler** and describes integration with **Horizontal Pod Autoscaler (HPA)** to provide comprehensive autoscaling for the EKS cluster at both node and pod levels.

### Two-Level Autoscaling Strategy

| Level | Component | Triggers | Action |
|-------|-----------|----------|--------|
| **Pod Level** | Horizontal Pod Autoscaler (HPA) | CPU > 75% | Scale replicas 1-5 |
| **Node Level** | Cluster Autoscaler | Unschedulable pods | Add nodes to ASG |

---

## Cluster Autoscaler

### Purpose

Automatically scales Kubernetes nodes based on resource demand. When pods cannot be scheduled due to insufficient CPU/memory, Cluster Autoscaler adds nodes to the Auto Scaling Group. When nodes are underutilized for 10+ minutes, it removes them.

### Configuration

**Location:** `/modules/cluster_autoscaler/main.tf`

```terraform
command = [
  "./cluster-autoscaler",
  "--v=4",
  "--stderrthreshold=info",
  "--cloud-provider=aws",
  "--skip-nodes-with-local-storage=false",
  "--expander=least-waste",
  "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/poc-plt-eks",
  "--balance-similar-node-groups",
  "--skip-nodes-with-system-pods=false",
  "--scale-down-enabled=true",
  "--scale-down-delay-after-add=10m",
]
```

### Key Parameters

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `--cloud-provider` | `aws` | Use AWS APIs for node management |
| `--node-group-auto-discovery` | ASG tags | Auto-discover ASG by cluster name + enabled tag |
| `--expander` | `least-waste` | Choose node type that wastes minimum resources |
| `--balance-similar-node-groups` | enabled | Distribute nodes evenly across similar groups |
| `--scale-down-enabled` | `true` | Allow scale-down when nodes are idle |
| `--scale-down-delay-after-add` | `10m` | Wait 10 min after add before attempting scale-down |

### IRSA (IAM Roles for Service Accounts)

- **ServiceAccount:** `cluster-autoscaler` in `kube-system` namespace
- **IAM Role:** `cluster-autoscaler-role`
- **Trust Policy:** Allows ServiceAccount to assume the IAM role via OIDC provider
- **Permissions:** EC2 describe, autoscaling group operations

```bash
# Verify IRSA annotation
kubectl get serviceaccount cluster-autoscaler -n kube-system -o yaml | grep role-arn
# Output: eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/cluster-autoscaler-role
```

---

## Horizontal Pod Autoscaler (HPA)

### Purpose

Automatically scales pod replicas based on CPU utilization. When average CPU across pods exceeds 75%, HPA adds replicas (up to max 5). When demand drops, it scales down replicas (minimum 2).

### Configuration

**Location:** `/modules/deploy/nginx/hpa.tf` and `variables.tf`

```yaml
# Current HPA Configuration
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-demo-hpa
  namespace: nginx
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-demo
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 75
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Pods
        value: 4
        periodSeconds: 15
    scaleDown:
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
```

### Pod Resource Requests (Critical for HPA)

HPA calculates CPU percentage based on **resource requests**. If requests are too high, pods consume less than 75% even under load.

**Current Configuration:**
```yaml
resources:
  requests:
    cpu: 50m         # 75% of this = 37.5m (easy to trigger)
    memory: 128Mi
  limits:
    cpu: 200m        # Maximum per pod
    memory: 256Mi
```

**Why requests matter:**
- HPA Target: 75% of **requested** CPU (not limit)
- With `requests: 100m`, pod needs 75m to trigger HPA (hard to reach)
- With `requests: 50m`, pod needs 37.5m to trigger HPA (easy to reach)

---

## Testing Autoscaling

### Prerequisites

1. Verify Metrics Server is running:
```bash
kubectl get deployment metrics-metrics-server -n kube-system
```

2. Check HPA status:
```bash
kubectl get hpa -n nginx
kubectl describe hpa nginx-demo-hpa -n nginx
```

3. Confirm pod limits are appropriate:
```bash
kubectl get deployment nginx-demo -n nginx -o yaml | grep -A 8 "resources:"
```

### Test Procedure

#### 1. Check Initial State

```bash
# HPA should show current CPU% and target
kubectl get hpa -n nginx
# Output: TARGETS: cpu: X%/75%

# Should be 1-2 running NGINX pods
kubectl get pods -n nginx | grep nginx-demo

# Node count
kubectl get nodes
```

#### 2. Generate Load with wrk

wrk is a high-performance HTTP load testing tool. Generates significant concurrent load:

```bash
# -t 10: 10 threads
# -c 100: 100 concurrent connections
# -d 600s: 600 second duration (10 minutes)
kubectl run -n nginx load-gen \
  --image=williamyeh/wrk:latest \
  --restart=Never \
  -- -t 10 -c 100 -d 600s http://nginx-demo-lb.nginx.svc.cluster.local/ &
```

#### 3. Monitor Load Generation

Verify load is actually being generated by checking processes inside load-gen pod:

```bash
# Check if load-gen pod is running multiple wrk processes
kubectl exec -n nginx load-gen -- ps aux

# Example output (multiple worker processes = good load):
PID   USER     TIME  COMMAND
  1   root     0:00  wrk -t 10 -c 100 -d 600s http://nginx-demo-lb.nginx.svc.cluster.local/
  8   root     0:00  wrk
 15   root     0:00  wrk
 22   root     0:00  wrk
 ...
```

#### 4. Watch HPA Scale-Up (30-60 seconds)

```bash
# Continuous monitoring
watch 'kubectl get hpa -n nginx && echo "---" && kubectl get pods -n nginx | grep nginx-demo'

# Or use -w flag
kubectl get hpa -n nginx -w

# Expected progression:
# TARGETS: cpu: 100%/75% → REPLICAS: 1
# TARGETS: cpu: 200%/75% → REPLICAS: 2-3 (adds 4 at a time due to scaleUp policy)
# TARGETS: cpu: 402%/75% → REPLICAS: 5 (reaches maxReplicas)
```

#### 5. Monitor Pod Count Increase

```bash
watch 'kubectl get hpa -n nginx && echo "---" && kubectl top pods -n nginx'

# Expected: 1 → 3 → 5 (within 1-2 minutes)
```

#### 6. Verify Cluster Autoscaler (if needed)

If NGINX pods are pending (waiting for nodes):

```bash
# Check for pending pods
kubectl get pods -n nginx | grep Pending

# View Cluster Autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler --tail=50 | grep -i "scale\|insufficient"

# Expected output:
# "Increasing node group size from 1 to 2"
# "New nodes found: ip-10-0-2-246"
```

#### 7. Watch Scale-Down (5-10 minutes after load stops)

```bash
# Kill load generation
kubectl delete pod -n nginx load-gen

# Watch HPA scale down (has stabilization delay)
kubectl get hpa -n nginx -w

# Expected after 5 minutes:
# REPLICAS: 5 → 3 (scale down by 100%)
# REPLICAS: 3 → 1 (continues scaling down)
```

#### 8. Monitor Cluster Autoscaler Scale-Down (10+ minutes)

```bash
# Watch nodes decrease
kubectl get nodes -w

# View scale-down logs
kubectl logs -n kube-system deployment/cluster-autoscaler \
  --since=5m | grep -i "scale-down"

# Expected:
# "node-1 was unneeded for 10 min, removing"
# "Removing node node-1..."
```

### Real-Time Monitoring Dashboard

### Success Criteria

✅ **HPA Scale-Up:**
- Triggers within 30-60 seconds when CPU > 75%
- Replicas increase from 1 → 5
- All pods reach Running state

✅ **HPA Scale-Down:**
- Replica count decreases after 5+ minutes of low CPU
- Scales down gradually (policy: 100% down every 15 sec)

✅ **Cluster Autoscaler Scale-Up:**
- Adds nodes if pods are Pending (insufficient CPU)
- New nodes appear within 1-2 minutes

✅ **Cluster Autoscaler Scale-Down:**
- Removes empty/underutilized nodes
- Waits 10 minutes after any scaling event
- No pod disruption

---

## Troubleshooting

### HPA not scaling

```bash
# Check if metrics are available
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods?namespace=nginx

# Check HPA status
kubectl describe hpa nginx-demo-hpa -n nginx | tail -30

# Common issues:
# - Metrics Server not running: kubectl get deploy -n kube-system metrics-metrics-server
# - Pod requests too high: Need CPU > 75% of requests
# - Load generator not working: kubectl logs -n nginx load-gen
```

### Cluster Autoscaler not scaling

```bash
# Check logs
kubectl logs -n kube-system deployment/cluster-autoscaler -f

# Verify IRSA
kubectl get serviceaccount cluster-autoscaler -n kube-system -o yaml

# Check ASG tags
aws autoscaling describe-auto-scaling-groups --region eu-west-3 \
  --query 'AutoScalingGroups[0].Tags'

# Should include: k8s.io/cluster-autoscaler/enabled=true
```

### Pods stuck in Pending

```bash
# Get event details
kubectl describe pod <pod-name> -n nginx

# Check node capacity
kubectl top nodes

# Check cluster autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler | grep "insufficient"
```

---

### Required Variables

The module uses Kubernetes provider to deploy raw resources (ServiceAccount, Deployment):
- `cluster_name` - EKS cluster name (used in ASG tag discovery)
- `cluster_autoscaler_role` - IAM role name created in EKS module
- `kube_host` - Kubernetes API endpoint
- `kube_ca` - Cluster CA certificate
- `kube_token` - API token OR exec auth (depends on provider config)

---

## References

- [Kubernetes Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [AWS Cluster Autoscaler](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md)
- [Metrics Server GitHub](https://github.com/kubernetes-sigs/metrics-server)

