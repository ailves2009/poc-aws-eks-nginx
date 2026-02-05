# /modules/s3-state/inputs.tf

variable "bucket_name" {
  description = "Имя S3 Bucket для хранения состояния Terraform"
  type        = string
}

variable "tags" {
  description = "Теги для ресурсов"
  type        = map(string)
  default     = {}
}

variable "deploy_role_arn" {
  description = "The ARN of the CICD deployment role"
  type        = string
}

variable "versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = false
}
