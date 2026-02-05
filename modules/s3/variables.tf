# /modules/s3/variables.tf

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "acl" {
  description = "The canned ACL to apply"
  type        = string
  default     = "private"
}

variable "control_object_ownership" {
  description = "Whether to enable control_object_ownership"
  type        = bool
  default     = true
}

variable "object_ownership" {
  description = "Object ownership setting"
  type        = string
  default     = "ObjectWriter"
}

variable "versioning_enabled" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Whether to force destroy the bucket"
  type        = bool
  default     = false
}

variable "enable_sqs_notification" {
  description = "Enable S3 → SQS event notification"
  type        = bool
  default     = false
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue for notifications"
  type        = string
  default     = ""
}

variable "notification_events" {
  description = "List of S3 events for notification"
  type        = list(string)
  default     = ["s3:ObjectCreated:*"]
}

variable "filter_prefix" {
  description = "Prefix filter for S3 event notification"
  type        = string
  default     = null
}

variable "filter_suffix" {
  description = "Suffix filter for S3 event notification"
  type        = string
  default     = null
}

variable "enable_public_write" {
  description = "Enable public write access to the bucket"
  type        = bool
  default     = false
}

variable "cors_rule" {
  description = "CORS rules for the bucket"
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
  }))
  default = []
}

variable "restrict_public_buckets" {
  description = "Restrict public buckets"
  type        = bool
  default     = false
}

variable "block_public_policy" {
  description = "Block public bucket policies"
  type        = bool
  default     = false
}

variable "block_public_acls" {
  description = "Block public ACLs"
  type        = bool
  default     = false
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs"
  type        = bool
  default     = false
}

variable "policy" {
  description = "Bucket policy"
  type        = string
  default     = ""
}

variable "attach_policy" {
  description = "Attach bucket policy"
  type        = bool
  default     = false
}

variable "source_replication_role_arn" {
  description = "ARN of the IAM role in the source account that S3 will use to perform cross-account replication"
  type        = string
  default     = ""
}

variable "replication_enabled" {
  description = "Toggle to enable/disable creating replication-related bucket policy. Set to true to allow cross-account replication."
  type        = bool
  default     = false
}

variable "allow_source_put" {
  description = "If true, add a bucket policy statement allowing a principal from the source account to PutObject into this bucket."
  type        = bool
  default     = false
}

variable "source_put_principal" {
  description = "The AWS principal (ARN) in the source account allowed to PutObject to this bucket when allow_source_put is true."
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region (optional). If empty, data.aws_region will be used. Useful for multi-region calls to form the service name for the VPC endpoint."
  type        = string
  default     = ""
}

variable "vpce_whitelisted_principals" {
  description = "List of principal ARNs (for example CI/CD role ARNs) which should be excluded from the VPCE deny. Use this to allow automation to manage the bucket even when restrict_to_vpc_endpoint = true."
  type        = list(string)
  default     = ["arn:aws:iam::470201305353:role/deploy-role"]
}

variable "create_vpc_endpoint" {
  description = "Whether to create a VPC Gateway Endpoint for S3 from this module"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC id where the S3 gateway endpoint should be created (required when create_vpc_endpoint = true)"
  type        = string
  default     = ""
}

variable "route_table_ids" {
  description = "List of route table IDs to associate with the S3 gateway endpoint (required when create_vpc_endpoint = true)"
  type        = list(string)
  default     = []
}

variable "restrict_to_vpc_endpoint" {
  description = "If true, attach a bucket policy that DENYs requests that do not originate from the created VPC endpoint (aws:sourceVpce)"
  type        = bool
  default     = false
}

variable "allow_cloudfront_access" {
  description = "Whether to allow CloudFront OAC access to the bucket (in addition to VPC endpoint access)"
  type        = bool
  default     = false
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution for OAC access (required when allow_cloudfront_access = true)"
  type        = string
  default     = ""
}

variable "cloudfront_deny_non_vpce_except_whitelisted_and_cloudfront" {
  description = "Whether to deny non-VPCE access except for whitelisted principals and CloudFront (used in bucket policy)"
  type        = bool
  default     = false
}
