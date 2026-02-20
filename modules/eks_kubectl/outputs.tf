# /modules/eks_kubectl/outputs.tf

output "aws_load_balancer_controller_service_account" {
  description = "Name of the AWS Load Balancer Controller Service Account"
  value       = kubernetes_service_account_v1.aws_load_balancer_controller.metadata[0].name
}

output "aws_load_balancer_controller_namespace" {
  description = "Namespace of the AWS Load Balancer Controller Service Account"
  value       = kubernetes_service_account_v1.aws_load_balancer_controller.metadata[0].namespace
}

output "ebs_csi_driver_service_account" {
  description = "Name of the AWS ebs_csi_driver Service Account"
  value       = kubernetes_service_account_v1.ebs_csi_driver.metadata[0].name
}

output "ebs_csi_driver_namespace" {
  description = "Namespace of the AWS ebs_csi_driver Service Account"
  value       = kubernetes_service_account_v1.ebs_csi_driver.metadata[0].namespace
}

