# /modules/vpn/variables.tf

variable "account" {
  description = "AWS account ID"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}
variable "description" {
  description = "Description for the VPN endpoint"
  type        = string
  default     = "Client VPN endpoint"
}

variable "vpn_client_cidr" {
  description = "CIDR block for VPN clients"
  type        = string
}

variable "split_tunnel" {
  description = "Enable split tunnel"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ENI associations"
  type        = list(string)
}

variable "dns_servers" {
  description = "List of DNS servers for VPN clients"
  type        = list(string)
  default     = []
}

variable "authorized_cidr" {
  description = "CIDR to authorize access to"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "client" {
  description = "Client name (e.g., tst)"
  type        = string
}

variable "env" {
  description = "Environment (e.g., prd, stg, dev)"
  type        = string
}

variable "domain_name" {
  description = "Domain name for VPN server certificate"
  type        = string
}

variable "client_cert_validity_days" {
  description = "Validity period for client certificates in days"
  type        = number
  default     = 365
}

variable "private_route_table_ids" {
  description = "List of private route table IDs where VPN routes should be added"
  type        = list(string)
  default     = []
}

variable "aws_managed_vpn_enable_vpn" {
  description = "Enable/disable VPN infrastructure deployment"
  type        = bool
  default     = true
}
