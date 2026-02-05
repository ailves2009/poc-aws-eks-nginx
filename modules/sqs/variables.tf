# /modules/sqs/variables.tf

variable "queue_name" {
  description = "SQS queue name"
  type        = string
}

variable "dlq_name" {
  description = "DLQ queue name"
  type        = string
}

variable "max_receive_count" {
  description = "Max receive count before moving to DLQ"
  type        = number
  default     = 5
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout"
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "How long to keep messages (in seconds)"
  type        = number
  default     = 604800 # 7 days
}

variable "receive_wait_time_seconds" {
  description = "Long polling wait time"
  type        = number
  default     = 20
}

variable "max_message_size" {
  description = "Maximum message size in bytes"
  type        = number
  default     = 262144 # 256 KB
}

variable "delay_seconds" {
  description = "Default delay for messages (in seconds)"
  type        = number
  default     = 0
}

variable "sqs_managed_sse_enabled" {
  description = "Enable SQS managed server-side encryption (SSE-SQS)"
  type        = bool
  default     = true
}

variable "kms_master_key_id" {
  description = "KMS key ID for SSE-KMS encryption (optional)"
  type        = string
  default     = null
}

variable "account" {
  description = "Target AWS account ID where the IAM role will be created"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "alarm_email" {
  description = "Список email для CloudWatch alarm"
  type        = list(string)
}
