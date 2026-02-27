Module `cluster_autoscaler`

Usage: call this module from an environment (via Terragrunt) and pass EKS outputs and the IAM role name created for cluster-autoscaler. The module will install the Helm chart
`autoscaler/cluster-autoscaler`, create the ServiceAccount (via Helm) and annotate it with
the IAM role ARN (IRSA).

Required variables:
- `cluster_name` - EKS cluster name used in ASG tag discovery
- `cluster_autoscaler_role` - IAM role name (must exist)
- Kubernetes provider inputs: `kube_host`, `kube_ca`, `kube_token`

Example (Terragrunt): call with dependency on EKS outputs and the role name variable.
