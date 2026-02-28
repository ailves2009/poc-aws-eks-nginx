# modules/deploy/nginx/variables.tf

variable "namespace" {
  description = "Kubernetes namespace for nginx deployment"
  type        = string
  default     = ""
}

variable "kube_host" {
  description = "Kubernetes API server endpoint (optional). If empty, provider will load local kubeconfig."
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "EKS cluster name for exec auth"
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

variable "domain_name" {
  description = "Domain name for Route53 record (e.g., bmta.echotwin.ai)"
  type        = string
  default     = ""
}

variable "nginx_hostname" {
  description = "Hostname for nginx Ingress (e.g., nginx.poc-eks.ailves2009.com)"
  type        = string
  default     = "nginx.poc-eks.ailves2009.com"
}

variable "certificate_arn" {
  description = "ACM Certificate ARN for HTTPS listener"
  type        = string
  default     = ""
}

variable "hpa_average_utilization" {
  description = "Average CPU utilization for Horizontal Pod Autoscaler"
  type        = number
  default     = 75
}

variable "hpa_min_replicas" {
  description = "Minimum number of replicas for Horizontal Pod Autoscaler"
  type        = number
  default     = 2
}

variable "hpa_max_replicas" {
  description = "Maximum number of replicas for Horizontal Pod Autoscaler"
  type        = number
  default     = 5
}
