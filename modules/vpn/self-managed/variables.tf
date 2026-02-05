variable "client" {
  description = "Client name (e.g., tst)"
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

variable "enable_this_ec2" {
  description = "Enable OpenVPN EC2 server"
  type        = bool
  default     = false
}

variable "instance_type" {
  default = "t3.micro"
}

variable "public_subnet_ids" {
  description = "Subnet ID for EC2"
  type        = list(string)
}

variable "key_name" {
  description = "SSH key name"
  type        = string
  default     = "5353-eu-west-3"
}

variable "generate_key" {
  description = "If true, generate an SSH keypair and import public key to AWS"
  type        = bool
  default     = true
}

variable "public_key" {
  description = "If generate_key = false, provide an OpenSSH public key to import into AWS"
  type        = string
  default     = ""
}

variable "write_private_key_file" {
  description = "If true and generate_key = true, write private key to local file during apply"
  type        = bool
  default     = false
}

variable "private_key_path" {
  description = "Local path to write private key when write_private_key_file is true"
  type        = string
  default     = "/Users/alexanderilves/.ssh/ae/5353-eu-west-3.pem"
}

variable "private_key_permissions" {
  description = "File permission for written private key (e.g. '0600')"
  type        = string
  default     = "0600"
}

variable "private_ip" {
  description = "Reserved private IP for this EC2 instance"
  type        = string
  default     = "10.0.4.xx"
}

variable "sg_name" {
  description = "Name of the security group for this EC2 instance"
  type        = string
}

variable "sg_description" {
  description = "Description of the security group for this EC2 instance"
  type        = string
}

variable "sg_ssh_port" {
  description = "SSH port for the security group"
  type        = number
  default     = 22
}

variable "sg_openvpn_port" {
  description = "Open port for the security group"
  type        = number
  default     = 443
}
variable "vpc_id" {
  description = "VPC ID for the security group"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpn_client_cidr" {
  description = "CIDR block for VPN clients"
  type        = string
}

variable "domain_name" {
  description = "Hosted zone name for Route53"
  type        = string
}

variable "private_route_table_ids" {
  description = "List of private route table IDs"
  type        = list(string)
}
