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

variable "one_nat_gateway_per_az" {
  description = "Create one NAT Gateway per Availability Zone"
  type        = bool
  default     = false
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
