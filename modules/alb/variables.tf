# modules/alb/variables.tf

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "load_balancer_controller_role" {
  description = "IAM Role name for AWS Load Balancer Controller"
  type        = string
}

variable "kube_host" {
  description = "Kubernetes API server endpoint"
  type        = string
}

variable "kube_ca" {
  description = "Cluster CA certificate (plain PEM string)"
  type        = string
  sensitive   = true
}

variable "kube_token" {
  description = "Bearer token for Kubernetes API authentication"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be deployed"
  type        = string
}
variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID for DNS record creation"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for Route53 CNAME record (e.g., poc-eks.ailves2009.com)"
  type        = string
  default     = ""
}

variable "ingress_alb_hostname" {
  description = "ALB hostname from Ingress status (e.g., k8s-nginx-nginxalb-xxx.eu-west-3.elb.amazonaws.com)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM Certificate ARN for HTTPS listener"
  type        = string
  default     = ""
}
