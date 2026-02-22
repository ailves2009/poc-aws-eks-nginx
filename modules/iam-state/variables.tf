# /modules/iamstate/variables.tf

variable "cicd_role_name" {
  description = "Имя IAM роли для Assume Role"
  type        = string
}

variable "cicd_account_arn" {
  description = "ARN CICD аккаунта, который может Assume Role"
  type        = string
}

variable "tags" {
  description = "Теги для IAM роли"
  type        = map(string)
  default     = {}
}

variable "account" {
  description = "Target AWS account ID where the IAM role will be created"
  type        = string
}

variable "region" {
  description = "AWS region where the resources will be created"
  type        = string
}

variable "client" {
  description = "Client identifier for resource naming"
  type        = string
}

variable "env" {
  description = "Environment identifier (e.g., dev, prod)"
  type        = string
  default     = "dev"
}
