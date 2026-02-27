# /modules/eks_kubectl/variables.tf

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cw_observability_role" {
  description = "IAM Role name for CloudWatch Observability"
  type        = string
}

variable "ebs_csi_driver_role" {
  description = "IAM Role name for EBS CSI Driver"
  type        = string
}

variable "cluster_autoscaler_role" {
  description = "ARN IAM роли для Cluster Autoscaler"
  type        = string
}

variable "eks_irsa_app_role" {
  description = "Name of the IAM role for APP IRSA"
  type        = string
}

