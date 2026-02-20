# modules/key-name/variables.tf

variable "generate_key" {
  description = "Whether to generate a new key pair"
  type        = bool
  default     = false
}

variable "key_name" {
  description = "Name of the SSH key pair to use for EKS nodes. If generate_key is true, this will be the name of the generated key pair"
  type        = string
  default     = ""
}

variable "private_key_path" {
  description = "Path to save the private key file if generate_key is true and write_private_key_file is true"
  type        = string
  default     = ""
}

variable "write_private_key_file" {
  description = "Whether to write the generated private key to a local file"
  type        = bool
  default     = false
}

variable "private_key_permissions" {
  description = "File permissions to set on the private key file if written to disk"
  type        = string
  default     = "0600"
}

variable "public_key" {
  description = "Public key to use if generate_key is false"
  type        = string
  default     = ""
}
