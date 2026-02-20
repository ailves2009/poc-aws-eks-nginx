# /modules/eks/variables.tf

variable "account" {
  description = "AWS account ID where the EKS cluster will be deployed"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.33"
}

variable "endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Enable admin permissions for the cluster creator"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
  default     = []
}

variable "control_plane_subnet_ids" {
  description = "List of subnet IDs for EKS control plane (if different from worker node subnet_ids)"
  type        = list(string)
  default     = []
}

variable "node_group_ami_type" {
  description = "AMI type for the managed node groups"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "instance_types" {
  description = "List of EC2 instance types for the managed node groups"
  type        = list(string)
  default     = ["t3.small"]
}

variable "min_size" {
  description = "Minimum number of nodes in the managed node group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes in the managed node group"
  type        = number
  default     = 3
}

variable "desired_size" {
  description = "Desired number of nodes in the managed node group"
  type        = number
  default     = 1
}

variable "use_latest_ami_release_version" {
  description = "Whether to use the latest AMI release version for the EKS managed node groups (overrides node_group_ami_type if true)"
  type        = bool
  default     = false
}

variable "force_update_version" {
  description = "Force version update by overriding upgrade-blocking readiness checks when updating a cluster"
  type        = bool
  default     = false
}
variable "service_account_names" {
  description = "List of service accounts for IRSA"
  type        = list(string)
  default     = ["app-front-sa", "app-back--sa"]
}

variable "namespace" {
  description = "Kubernetes namespace for IRSA"
  type        = string
  default     = "default"
}

variable "create_iam_role" {
  description = "Whether to create IAM role for the cluster"
  type        = bool
  default     = true
}

variable "load_balancer_controller_role" {
  description = "IAM Role for AWS Load Balancer Controller"
  type        = string
  default     = ""
}

variable "ebs_csi_driver_role" {
  description = "IAM Role for EBS CSI driver"
  type        = string
  default     = ""
}

variable "eks_irsa_app_role" {
  description = "Name of the IAM role for APP IRSA"
  type        = string
  default     = ""
}

variable "cw_observability_role" {
  description = "IAM Role for CloudWatch Observability"
  type        = string
  default     = ""
}

variable "cluster_autoscaler_role" {
  description = "IAM Role for Cluster Autoscaler"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the EKS cluster endpoint publicly. Security best practice: Do not use 0.0.0.0/0"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "asg_names" {
  type    = list(string)
  default = []
}

variable "generate_key" {
  description = "If true, generate an SSH keypair and import public key to AWS"
  type        = bool
  default     = true
}

variable "key_name" {
  description = "SSH key name"
  type        = string
  default     = ""
}
