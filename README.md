# POC "AWS EKS Kubernetes Platform"

## Project Overview

This project demonstrates how to provision and operate a Kubernetes platform in a **clean AWS account** using **managed Amazon EKS** and modern Infrastructure as Code practices.

The focus of the project is not on a perfectly polished solution, but on a **working, reproducible, and well-structured implementation** that reflects production-oriented thinking.

---

## Task Definition

### Objective

In an empty AWS account, perform the following:

1. Create a **managed Amazon EKS cluster**
2. Implement **node autoscaling**
3. Deploy **NGINX** with **pod autoscaling**
4. Make NGINX **publicly accessible**

### Tooling Stack

- **Infrastructure as Code:**
  - Terraform / Terragrunt for AWS infrastructure
  - Helm for Kubernetes applications
- **Managed Kubernetes:**
  - Amazon EKS (Kubernetes 1.30)
  - OIDC provider for pod IAM (IRSA)
- **Load Balancing & DNS:**
  - AWS Load Balancer Controller (ALB v3.0.0)
  - ACM for HTTPS certificates
  - Route53 for DNS management
- **Autoscaling:**
  - Cluster Autoscaler (node level)
  - Horizontal Pod Autoscaler (pod level, CPU-based)

---

## Implementation Status

### ✅ Completed
- VPC with public/private subnets across 3 AZs
- EKS cluster (1.30) with OIDC provider for IRSA
- Cluster Autoscaler for node-level scaling (2-5 nodes)
- Metrics Server for HPA metrics collection
- AWS Load Balancer Controller v3.0.0
- NGINX deployment with HPA (CPU target: 70%, 2-5 replicas)
- ACM wildcard certificate for `*.poc-eks.ailves2009.com` (ISSUED)
- Route53 CNAME record for DNS resolution
- **End-to-end HTTPS working:** `https://nginx.poc-eks.ailves2009.com` → HTTP/2 200 OK
- Dynamic Kubernetes provider auth (exec plugin, no token expiration)
- GitHub repository with secret history cleaned

### ⏳ Not in Scope (Future Enhancements)
- Observability: Prometheus, Grafana, CloudWatch Logs
- Network Policies / Service Mesh (Cilium, Istio)
- Image security scanning
- Admission controllers (OPA, Kyverno)
- GitOps (ArgoCD, Flux)
- Backup/Disaster recovery (Velero)

---

## 1. Base Infrastructure and IaC

**Goal:** reproducible, version-controlled infrastructure with minimal blast radius.

### Layer Structure

```
modules/                                # Reusable Terraform modules
├── vpc/                               # VPC, subnets, security groups
├── eks/                               # EKS cluster + OIDC provider
├── eks_kubectl/                       # In-cluster resources (RBAC, CRDs)
├── acm/                               # ACM certificate management
├── dns/                               # Route53 records
├── alb/                               # ALB + ALB Controller (Helm)
├── deploy/nginx/                      # NGINX deployment + service + ingress
├── iam/                               # IAM policies and roles
├── key-pair/                          # EC2 key pair (debugging)
└── monitoring/                        # Metrics Server (HPA support)

envs/
└── main/plt/poc/                      # Platform layer, POC environment
    ├── root.hcl                       # Shared variables (domain, region, cluster name)
    ├── vpc/terragrunt.hcl
    ├── eks/terragrunt.hcl
    ├── acm/terragrunt.hcl
    ├── dns/terragrunt.hcl
    ├── alb/terragrunt.hcl
    ├── deploy/terragrunt.hcl
    ├── eks_kubectl/terragrunt.hcl
    └── monitoring/terragrunt.hcl
```

### Remote State Management

| Component | Backend | Locking |
|-----------|---------|----------|
| Terraform state | S3 (encrypted at rest) | DynamoDB |
| IaC roles | Created by `envs/pred/plt/poc/iam-state/` | Manual |
| State bucket | Created by `envs/pred/plt/poc/s3-state/` | Manual |

### IaC Best Practices Implemented

- ✅ **Version pinning:** Terraform providers, EKS Kubernetes version (1.30), Helm chart versions
- ✅ **Modular design:** Each infrastructure component in separate module
- ✅ **Environment consolidation:** Single Terragrunt root per environment (`root.hcl`)
- ✅ **Local variables:** Shared domain, region, cluster name in `root.hcl`
- ✅ **Explicit dependencies:** Terragrunt `dependencies {}` blocks, clear deployment order
- ✅ **Minimal IAM:** IRSA (IAM Roles for Service Accounts) for pod-level AWS API access
- ✅ **Secret-free repository:** `.gitignore` excludes `*.tfvars.local`, `*.key`, `*.pem`, `data/`, `temp/`

---

## 2. Networking and Perimeter Security

**Goal:** the cluster must not be exposed as an open attack surface.

- VPC design:
  - Private subnets for worker nodes
  - Public subnets only for load balancers
- Security Groups:
  - Inbound access only via ALB / NLB
  - No direct SSH access (or via AWS SSM only)
- EKS Control Plane access:
  - Restricted to VPC
  - Or limited CIDR ranges
- Kubernetes Network Policies:
  - Calico or Cilium
- VPC Flow Logs enabled

### Not Implemented in POC

- VPC Flow Logs (can be enabled for audit)
- Network Policies (Cilium/Calico)
- Egress firewalling (all egress allowed via NAT GW)
---

## 3. Kubernetes Control Plane

**Goal:** managed, stable control plane with secure authentication.

- Managed Kubernetes:
  - Amazon EKS to reduce operational risk
- Upgrade strategy:
  - Control plane upgrades
  - Rolling node group upgrades
- Node groups:
  - Spread across at least 2–3 Availability Zones
  - Separate node groups for:
    - system workloads
    - application workloads
- Pod Disruption Budgets for critical system components
- Resource quotas and limits per namespace

### Cluster Configuration

| Parameter | Value | Purpose |
|-----------|-------|----------|
| **Cluster name** | `poc-plt-eks` | Identifier in AWS |
| **Kubernetes version** | 1.30 | Specified in `modules/eks/main.tf` |
| **Endpoint** | Restricted to VPC | Not publicly accessible |
| **OIDC provider** | Enabled | For IRSA (pod IAM roles) |
| **Control plane logging** | CloudWatch enabled | Audit/troubleshooting |
| **Availability Zones** | 3 (eu-west-3a, 3b, 3c) | High availability |


### NAmespaces and SAs

| Namespace     | Purpose.        | Service Accounts               |
|---------------|-----------------|--------------------------------|
| `kube-system` | Cluster add-ons | `cluster-autoscaler`,
                                    `aws-load-balancer-controller`,
                                    `metrics-server`               |
| `nginx`       | App workload    | `default` (NGINX pods)         |
| `default`     | Rarely used | — |

---

## 4. Autoscaling
**Goal:** dynamic scaling based on actual workload demand.

### Node Autoscaling

- Cluster Autoscaler
- Separate node pools:
  - `system`
  - `workloads`
- Scaling based on:
  - Pending pods
  - Resource requests
- Graceful node termination:
  - Drain hooks enabled

### Pod Autoscaling

- Horizontal Pod Autoscaler (HPA):
  - CPU and memory metrics
  - Optional custom metrics
- Resource requests and limits are mandatory
- Minimum replicas greater than 1### Node Autoscaling (Cluster Autoscaler)

**Deployment:** `kube-system/cluster-autoscaler`

| Parameter           | Value                      | Notes                                |
|---------------------|----------------------------|--------------------------------------|
| **Trigger**         | Pending unschedulable pods | Scales up when nodes cannot fit pods |
| **Scale down**      | Unused nodes after 10 min  | Graceful drain of workloads          |
| **Min nodes**.      |                          2 | Minimum for HA                       |
| **Max nodes**       |                          5 | Cost limit                           |
| **Instance type**   | `t3.medium` (spot)         | Cost-effective for POC               |
| **IAM permissions** | EC2 describe + ASG scaling | IRSA role:`eks-cluster-autoscaler-role` |

**Testing:**
```bash
# Watch autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler -f | grep scale

# List nodes
kubectl get nodes
```

### Pod Autoscaling (Horizontal Pod Autoscaler)

**Target:** NGINX Deployment in `nginx` namespace

| Parameter | Value | Notes |
|-----------|-------|-------|
| **Metric** | CPU utilization | From Metrics Server |
| **Target CPU** | 70% | Scale up when > 70% |
| **Min replicas** | 2 | Always run 2+ for HA |
| **Max replicas** | 5 | Cost/scale limit |
| **Scale-up period** | 30 seconds | Fast response |
| **Scale-down period** | 300 seconds | Gradual reduction |

**Metrics Source:** Metrics Server (installed via `monitoring` module)

**Testing:**
```bash
# Check HPA status
kubectl get hpa -n nginx

# Watch pods scaling
kubectl get pods -n nginx -w

# Load test (generate CPU load)
kubectl run -it --rm load-generator --image=busybox /bin/sh
# Then inside:
# > while sleep 0.01; do wget -q -O- http://nginx:80; done
```

### Prerequisites for Both

✅ Pod `resources.requests` must be set (HPA targets % of requests)
```yaml
resources:
  requests:
    cpu: 100m      # HPA calculates 70% of this
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
```
---
### Node Autoscaling (Cluster Autoscaler)

**Deployment:** `kube-system/cluster-autoscaler`

| Parameter | Value | Notes |
|-----------|-------|-------|
| **Trigger** | Pending unschedulable pods | Scales up when nodes cannot fit pods |
| **Scale down** | Unused nodes after 10 min | Graceful drain of workloads |
| **Min nodes** | 2 | Minimum for HA |
| **Max nodes** | 5 | Cost limit |
| **Instance type** | `t3.medium` (spot) | Cost-effective for POC |
| **IAM permissions** | EC2 describe + ASG scaling | IRSA role: `eks-cluster-autoscaler-role` |

**Testing:**
```bash
# Watch autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler -f | grep scale

# List nodes
kubectl get nodes
```

### Pod Autoscaling (Horizontal Pod Autoscaler)

**Target:** NGINX Deployment in `nginx` namespace

| Parameter | Value | Notes |
|-----------|-------|-------|
| **Metric** | CPU utilization | From Metrics Server |
| **Target CPU** | 70% | Scale up when > 70% |
| **Min replicas** | 2 | Always run 2+ for HA |
| **Max replicas** | 5 | Cost/scale limit |
| **Scale-up period** | 30 seconds | Fast response |
| **Scale-down period** | 300 seconds | Gradual reduction |

**Metrics Source:** Metrics Server (installed via `monitoring` module)

**Testing:**
```bash
# Check HPA status
kubectl get hpa -n nginx

# Watch pods scaling
kubectl get pods -n nginx -w

# Load test (generate CPU load)
kubectl run -it --rm load-generator --image=busybox /bin/sh
# Then inside:
# > while sleep 0.01; do wget -q -O- http://nginx:80; done
```

### Prerequisites for Both

✅ Pod `resources.requests` must be set (HPA targets % of requests)
```yaml
resources:
  requests:
    cpu: 100m      # HPA calculates 70% of this
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
```

---



---



## 5. Ingress and Public Access

**Goal:** expose NGINX via HTTPS with automatic ALB provisioning.

### End-to-End Traffic Flow

```
┌─────────────┐
│  Internet   │ HTTPS (port 443)
└──────┬──────┘
       │ (TCP SYN)
       ▼
┌──────────────────────────────────────────────────────┐
│ Route53: nginx.poc-eks.ailves2009.com                │
│ Type: CNAME → ALB hostname (auto-created)            │
└──────────┬───────────────────────────────────────────┘
           │ (DNS resolves to ALB public IP)
           ▼
┌──────────────────────────────────────────────────────┐
│ ALB (Application Load Balancer)                       │
│ - Listen: 80 (HTTP) + 443 (HTTPS with ACM cert)     │
│ - Health checks: /nginx_status                       │
│ - Rule: route all to NGINX service                   │
└──────────┬───────────────────────────────────────────┘
           │ (forward to Service:80 in-cluster)
           ▼
┌──────────────────────────────────────────────────────┐
│ Kubernetes Service: nginx-demo-lb (ClusterIP, :80)  │
│ Selector: app=nginx                                  │
└──────────┬───────────────────────────────────────────┘
           │ (load-balance across pods)
           ▼
┌──────────────────────────────────────────────────────┐
│ NGINX Pods (replica 1, 2, 3...)                      │
│ Image: nginx:1.25-alpine                             │
│ Port: 80 (HTTP inside cluster)                       │
│ HPA: 2-5 replicas (CPU-based)                        │
└──────────────────────────────────────────────────────┘
```

### AWS Load Balancer Controller v3.0.0

**Deployment:** `kube-system/aws-load-balancer-controller` (Helm chart)

| Component | Configuration |
|-----------|---------------|
| **Replicas** | 2 (HA) |
| **IRSA** | Yes, role: `eks-alb-controller-role` |
| **Permissions** | EC2 (describe instances), ELBv2 (manage ALBs) |
| **Watch timeout** | Default 15s |

**Key annotation on Ingress:**
```yaml
metadata:
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
```

### HTTPS with ACM Certificate

**Certificate Details:**
- **Domain:** `*.poc-eks.ailves2009.com` + `poc-eks.ailves2009.com`
- **Issued by:** AWS Certificate Manager
- **Validation method:** DNS (Route53 CNAME challenge)
- **Status:** ✅ ISSUED (not expired)
- **Auto-renewal:** Enabled

**Ingress Annotations for HTTPS:**
```yaml
alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
alb.ingress.kubernetes.io/ssl-redirect: "443"           # Plain string (not JSON!)
alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:eu-west-3:470201305353:certificate/xxxxx
alb.ingress.kubernetes.io/healthcheck-path: /
alb.ingress.kubernetes.io/healthcheck-interval-seconds: "15"
```

**Note on annotation format:** ALB Controller v3.0.0 expects `ssl-redirect` as plain string `"443"`, not JSON array `[{...}]`. Earlier versions had different syntax; this was a key debugging point.

### DNS with Route53

**Hosted Zone:** `poc-eks.ailves2009.com` (created manually)

**Ingress DNS Record:**
```
Name: nginx.poc-eks.ailves2009.com
Type: CNAME
Value: k8s-nginx-nginxalb-3aebd75766-1319654008.eu-west-3.elb.amazonaws.com
TTL: 300
```

The ALB hostname is automatically populated by ALB Controller → Route53 record is updated via Terraform.

### Verification

```bash
# 1. DNS resolution
$ nslookup nginx.poc-eks.ailves2009.com
Non-authoritative answer:
Name:   nginx.poc-eks.ailves2009.com
Address: 52.xyz.abc (ELBv2 public IP)

# 2. HTTPS connectivity
$ curl -I https://nginx.poc-eks.ailves2009.com
HTTP/2 200
server: nginx/1.25.5

# 3. Certificate validation
$ openssl s_client -connect nginx.poc-eks.ailves2009.com:443 -servername nginx.poc-eks.ailves2009.com
...
Subject: CN=*.poc-eks.ailves2009.com
Issuer: Amazon RSA 2048 M03
```

---

## 6. Observability

**Goal:** no production system exists without visibility.

### Logging

- Centralized logging:
  - CloudWatch and/or Loki
- Structured JSON logs
- Defined log retention policies

### Metrics

- Prometheus for metrics collection
- Node, pod, and application metrics
- Clear visibility into HPA behavior

### Alerting

- CPU and memory saturation
- Pod crash loops
- Node `NotReady` state
- Ingress 5xx errors

---

## 7. In-Cluster Security

**Goal:** minimize blast radius.

- RBAC:
  - No `cluster-admin` by default
  - Dedicated roles for CI/CD systems
- Pod security:
  - Non-root containers
  - Read-only root filesystem
  - Dropped Linux capabilities
- Secrets management:
  - Kubernetes Secrets with encryption at rest
  - Or AWS Secrets Manager via External Secrets
- Image security:
  - Private container registry
  - Image scanning
- Admission policies:
  - OPA / Kyverno (optional)

---

## 8. CI/CD and Operational Practices

**Goal:** safe, predictable, and repeatable releases.

- GitOps approach:
  - Argo CD or Flux
- Immutable deployments:
  - Rolling updates
  - Blue/green or canary (when required)
- Health checks:
  - Readiness probes
  - Liveness probes
- Tested rollback procedures
- Versioned manifests and Helm charts

---

## 9. Backup and Disaster Recovery

**Goal:** prepare for failure scenarios.

- Backups:
  - etcd (for self-hosted components if any)
  - Persistent volumes via Velero
- Documented restore procedures
- Multi-AZ setup as a baseline
- Restore tests performed at least every N months

---

## 10. Cost Control

**Goal:** production should not be unnecessarily expensive.

- Proper sizing:
  - Requests ≠ limits ≠ actual usage
- Spot instances for non-critical workloads
- Controlled resource overcommit
- Cost visibility tools:
  - AWS Cost Explorer
  - Kubecost (optional)

---

## 11. Documentation and Runbooks

**Goal:** the platform must be operable by more than its author.

- README documentation:
  - How to deploy
  - How to upgrade
  - How to destroy the environment
- Architecture diagrams:
  - VPC
  - Kubernetes
  - Ingress flow
- Runbooks:
  - Node fails to join the cluster
  - Pods do not scale
  - Ingress is not responding

---

## IAM for Pods (POC)

This cluster supports two approaches for pod IAM access:

### 1. IRSA (IAM Roles for Service Accounts)
- Pods are associated with IAM Roles via Kubernetes ServiceAccount annotations.
- Requires an OIDC provider configured for the EKS cluster.
- Uses AWS STS `AssumeRoleWithWebIdentity`.
- Steps:
  1. Enable OIDC provider for the cluster.
  2. Create IAM Role with trust policy for the ServiceAccount.
  3. Attach necessary IAM Policy to the Role.
  4. Annotate the ServiceAccount with the IAM Role ARN.
  5. Pods using this ServiceAccount automatically get the credentials.

### 2. EKS Pod Identity Agent
- Pods request IAM credentials through a DaemonSet running on each node.
- No OIDC provider required.
- Centralized management via Terraform (`aws_eks_pod_identity_association`) or AWS API.
- Steps:
  1. Enable the `eks-pod-identity-agent` addon (`before_compute = true`).
  2. Create IAM Role with required policies.
  3. Create a ServiceAccount without annotations.
  4. Associate ServiceAccount with IAM Role using `aws_eks_pod_identity_association`.
  5. Pods automatically receive credentials via the agent.

**POC approach:**
Both methods can coexist in the same cluster. Some workloads use IRSA, some use Pod Identity, allowing comparison of usability, deployment workflow, and security.
