# /modules/eks/outputs.tf

output "namespace" {
  value = var.namespace
}

output "service_account_name" {
  value = [var.service_account_names]
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "eks_endpoint" {
  # value = module.eks.endpoint
  value = data.aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  # value = base64decode(module.eks.cluster_certificate_authority_data)
  value = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
}

output "cluster_token" {
  value     = data.aws_eks_cluster_auth.this.token
  sensitive = true
}

output "eks_irsa_app_role" {
  value = aws_iam_role.irsa.name
}

# AWS Load Balancer Controller outputs
output "load_balancer_controller_role" {
  description = "Name of the AWS Load Balancer Controller IAM Role"
  value       = aws_iam_role.aws_load_balancer_controller.name
}

output "ebs_csi_driver_role" {
  value = try(aws_iam_role.ebs_csi_driver[0].name, "")
}

output "cluster_autoscaler_role" {
  value = aws_iam_role.cluster_autoscaler.name
}

output "cw_observability_role" {
  value = aws_iam_role.cw_observability.name
}

output "endpoint_public_access" {
  value = var.endpoint_public_access
}

output "endpoint_private_access" {
  value = var.endpoint_private_access
}

# OIDC provider for EKS
output "oidc_provider" {
  value = module.eks.oidc_provider
}

output "eks_managed_node_groups_autoscaling_group_names" {
  value = module.eks.eks_managed_node_groups_autoscaling_group_names
}

output "cluster_endpoint" {
  value = data.aws_eks_cluster.this.endpoint
}
