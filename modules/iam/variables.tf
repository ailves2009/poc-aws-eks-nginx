# /modules/iam/variables.tf

variable "cicd_role_name" {
  description = "Имя IAM роли для Assume Role"
  type        = string
}

variable "region" {
  description = "AWS region where the IAM role will be created"
  type        = string
}

variable "account" {
  description = "Target AWS account ID where the IAM role will be created"
  type        = string
}

variable "client" {
  description = "Client name"
  type        = string
}

variable "env" {
  description = "Environment name (e.g., dev, stg, prd)"
  type        = string
  default     = ""
}

variable "s3_detection" {
  description = "S3 bucket name for detections"
  type        = string
  default     = "xxx-yyy-detections"
}
