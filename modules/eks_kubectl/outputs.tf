# /modules/eks_kubectl/outputs.tf

output "ebs_csi_driver_service_account" {
  description = "Name of the AWS ebs_csi_driver Service Account"
  value       = try(kubernetes_service_account_v1.ebs_csi_driver[0].metadata[0].name, "")
}

output "ebs_csi_driver_namespace" {
  description = "Namespace of the AWS ebs_csi_driver Service Account"
  value       = try(kubernetes_service_account_v1.ebs_csi_driver[0].metadata[0].namespace, "")
}

output "cw_observability_service_account" {
  description = "Name of the CloudWatch Observability Service Account"
  value       = try(kubernetes_service_account_v1.cw_observability.metadata[0].name, "")
}

output "cw_observability_namespace" {
  description = "Namespace of the CloudWatch Observability Service Account"
  value       = try(kubernetes_service_account_v1.cw_observability.metadata[0].namespace, "")
}
