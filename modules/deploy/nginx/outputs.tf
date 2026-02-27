# modules/deploy/nginx/outputs.tf

output "result" {
  description = "Result of the nginx deployment module"
  value       = "Nginx deployment completed successfully. Check results of kubectl get svc -n nginx - to get LB external address."
}

output "ingress_alb_hostname" {
  description = "The hostname of the AWS ALB created by the Ingress"
  value       = try(kubernetes_ingress_v1.nginx_alb.status[0].load_balancer[0].ingress[0].hostname, "pending")
}

output "ingress_alb_ip" {
  description = "The IP address of the AWS ALB (if available)"
  value       = try(kubernetes_ingress_v1.nginx_alb.status[0].load_balancer[0].ingress[0].ip, "pending")
}
