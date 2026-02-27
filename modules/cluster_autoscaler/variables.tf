variable "cluster_name" {
  description = "EKS cluster name used in node-group-auto-discovery tag"
  type        = string
}

variable "cluster_autoscaler_role" {
  description = "IAM role name created for Cluster Autoscaler (used for IRSA annotation)"
  type        = string
}

variable "kube_host" {
  description = "Kubernetes API server endpoint (optional)."
  type        = string
  default     = ""
}

variable "kube_ca" {
  description = "Cluster CA certificate (optional, plain PEM string)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "kube_token" {
  description = "Bearer token for Kubernetes API authentication (optional)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
/*
variable "service_account_name" {
  description = "ServiceAccount name to create via Helm"
  type        = string
  default     = "cluster-autoscaler-sa"
}

variable "chart_version" {
  description = "Optional Helm chart version for cluster-autoscaler"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region for the cluster-autoscaler to query Auto Scaling / EC2 APIs"
  type        = string
  default     = "eu-west-3"
}

variable "aws_region" {
  description = "AWS region for the cluster-autoscaler to query Auto Scaling / EC2 APIs"
  type        = string
  default     = "eu-west-3"
}

variable "cluster_autoscaler_toggle" {
  description = "Enable or disable installation of cluster-autoscaler"
  type        = bool
  default     = true
}

variable "autoscaling_group_name" {
  description = "(Optional) Autoscaling Group name to pin cluster-autoscaler to (used with sets example)"
  type        = string
  default     = ""
}

variable "auto_scale_options" {
  description = "Map containing min/max size for the autoscaling group (used by example set blocks)"
  type        = map(number)
  default     = {
    max = 3
    min = 1
  }
}
*/
