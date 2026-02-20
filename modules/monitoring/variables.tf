# /modules/monitoring/variables.tf

variable "asg_names" {
  description = "List of Auto Scaling Group names to create alarms for"
  type        = list(string)
  default     = []
}

variable "cluster_name" {
  description = "EKS cluster name (optional, used for some alarms/dashboard)"
  type        = string
  default     = ""
}

variable "sns_topic_name" {
  description = "Name for the SNS topic used for CPU alarms"
  type        = string
  default     = "cpu-alarms"
}
