# AWS EKS Kubernetes Platform

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

### Tooling Constraints

- Infrastructure as Code:
  - **Terraform / Terragrunt**
  - **Helm** for Kubernetes applications
- Managed Kubernetes:
  - **Amazon EKS**

---

## Resulting Architecture and Design Principles

The implementation follows a layered approach aligned with production-ready best practices.

---

## 1. Base Infrastructure and IaC

**Goal:** reproducibility, change control, and secure defaults.

- Declarative IaC only:
  - Terraform / OpenTofu
- Remote state management:
  - S3 backend
  - DynamoDB state locking
- Modular structure:
  - VPC / networking
  - EKS cluster
  - Node groups / autoscaling
  - Kubernetes addons
- Clear environment separation:
  - `dev`, `stage`, `prod`
  - Implemented via Terraform workspaces or Terragrunt
- Version pinning:
  - Terraform providers
  - Kubernetes version
  - AMI / node images
- Minimal IAM permissions:
  - Principle of least privilege applied everywhere

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

---

## 3. Kubernetes Control Plane

**Goal:** stability and operational manageability.

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

---

## 4. Autoscaling

**Goal:** scalable infrastructure without manual intervention.

### Node Autoscaling

- Cluster Autoscaler or Karpenter
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
- Minimum replicas greater than 1

---

## 5. Ingress and Public Access

**Goal:** controlled and secure traffic entry.

- Ingress Controller:
  - AWS Load Balancer Controller (ALB)
- HTTPS:
  - ACM-managed certificates
  - TLS termination at the ALB
- Correctly configured health checks
- Rate limiting where applicable
- Clear separation between:
  - internal services
  - public services

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
