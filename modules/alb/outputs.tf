# modules/alb/outputs.tf

output "aws_load_balancer_controller_service_account" {
  description = "Name of the AWS Load Balancer Controller Service Account"
  value       = kubernetes_service_account_v1.aws_load_balancer_controller.metadata[0].name
}

output "aws_load_balancer_controller_namespace" {
  description = "Namespace of the AWS Load Balancer Controller Service Account"
  value       = kubernetes_service_account_v1.aws_load_balancer_controller.metadata[0].namespace
}

output "kube_host" {
  description = "Kubernetes API server endpoint"
  value       = var.kube_host
}

output "kube_ca" {
  description = "Cluster CA certificate"
  value       = var.kube_ca
  sensitive   = true
}

output "kube_token" {
  description = "Bearer token for Kubernetes API authentication"
  value       = var.kube_token
  sensitive   = true
}

output "nginx_record_fqdn" {
  description = "FQDN of the nginx Route53 CNAME record"
  value       = try(aws_route53_record.nginx_alb[0].fqdn, "")
}
