variable "bucket_name" {
  description = "S3 bucket name to apply bindings to"
  type        = string
}

variable "region" {
  description = "AWS region (optional). If empty, data.aws_region will be used."
  type        = string
  default     = ""
}

variable "vpce_whitelisted_principals" {
  description = "List of principal ARNs to whitelist"
  type        = list(string)
  default     = []
}

variable "create_vpc_endpoint" {
  description = "Create VPC gateway endpoint for S3"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC id for endpoint"
  type        = string
  default     = ""
}

variable "route_table_ids" {
  description = "Route table IDs for endpoint"
  type        = list(string)
  default     = []
}

variable "restrict_to_vpc_endpoint" {
  description = "Attach deny policy to restrict access to VPCE"
  type        = bool
  default     = false
}

variable "allow_cloudfront_access" {
  description = "Allow CloudFront distribution access"
  type        = bool
  default     = false
}

variable "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN for OAC access"
  type        = string
  default     = ""
}

variable "cloudfront_deny_non_vpce_except_whitelisted_and_cloudfront" {
  description = "Whether to deny non-VPCE access except whitelist and CloudFront"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to created resources"
  type        = map(string)
  default     = {}
}

variable "additional_policy_statements" {
  description = "Optional additional policy statements (list of maps) to include in the bucket policy. Example: dependency outputs from other modules." 
  type        = list(any)
  default     = []
}
