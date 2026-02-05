# /modules/vpc/variables.tf

variable "region" {
  description = "value of the AWS region"
  type        = string
}

variable "client" {
  description = "Client name for resource naming"
  type        = string
}

variable "env" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "cloudwatch_logs_retention_in_days" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 365
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

variable "manage_default_network_acl" {
  description = "Manage default network ACL"
  type        = bool
  default     = false
}

variable "vpn_client_cidr" {
  description = "CIDR block for VPN clients"
  type        = string
  default     = "10.X.0.0/16"
}

variable "create_flow_logs" {
  description = "Whether to create VPC Flow Logs"
  type        = bool
  default     = true
}

variable "create_for_all_vpcs" {
  description = "When true, create Flow Logs for all VPCs in the account (in addition to module VPC)"
  type        = bool
  default     = false
}

variable "traffic_type" {
  description = "Traffic type for VPC Flow Logs (ALL, ACCEPT, REJECT)"
  type        = string
  default     = "ALL"
}
