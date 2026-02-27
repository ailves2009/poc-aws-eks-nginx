# modules/vpn/variables.tf

variable "client" {
  description = "Client name (e.g., dmt)"
  type        = string
}

variable "env" {
  description = "Environment (e.g., prd, stg, dev)"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "enable_openvpn_ec2" {
  description = "Enable OpenVPN EC2 server"
  type        = bool
  default     = false
}

variable "openvpn_instance_type" {
  default = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for OpenVPN server (Ubuntu 24.04 LTS, например)"
  type        = string
}

variable "public_subnet_ids" {
  description = "Subnet ID for OpenVPN server"
  type        = list(string)
}

variable "key_pair_name" {
  description = "SSH key pair name"
  type        = string
}

variable "openvpn_private_ip" {
  description = "Reserved private IP for OpenVPN server"
  type        = string
  default     = "10.0.4.55"
}
/*
variable "openvpn_security_group_id" {
  description = "List of security group IDs for OpenVPN server"
  type        = list(string)
}
*/
variable "sg_name" {
  description = "Security Group name for OpenVPN server"
  type        = string
  default     = "SG"
}

variable "sg_description" {
  description = "Security Group description for OpenVPN server"
  type        = string
  default     = "Security Group for OpenVPN EC2 instance"
}

variable "vpc_id" {
  description = "VPC ID where OpenVPN server will be deployed"
  type        = string
}
variable "sg_openvpn_port" {
  description = "OpenVPN port in security group"
  type        = number
  default     = 1194
}
variable "sg_ssh_port" {
  description = "SSH port in security group"
  type        = number
  default     = 22
}
variable "vpc_cidr_block" {
  description = "List of CIDR blocks for the VPC"
  type        = string
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name for VPN DNS record"
  type        = string
}
