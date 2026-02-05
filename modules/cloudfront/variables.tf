# /modules/cloudfront/variables.tf

variable "name" {
  description = "Name for the CloudFront distribution"
  type        = string
}

variable "s3_detection" {
  description = "Name of the S3 bucket to serve content from"
  type        = string
}

variable "aliases" {
  description = "List of domain names for the distribution"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
  default     = null
}

variable "price_class" {
  description = "Price class for the distribution"
  type        = string
  default     = "PriceClass_100"
  validation {
    condition = contains([
      "PriceClass_All",
      "PriceClass_200",
      "PriceClass_100"
    ], var.price_class)
    error_message = "Price class must be PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "default_root_object" {
  description = "Default root object for the distribution"
  type        = string
  default     = "index.html"
}

variable "create_route53_record" {
  description = "Whether to create Route53 record for custom domain"
  type        = bool
  default     = false
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Domain name for the CloudFront distribution"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "create_oac_policy" {
  description = "Whether to create S3 bucket policy for CloudFront OAC access"
  type        = bool
  default     = true
}
