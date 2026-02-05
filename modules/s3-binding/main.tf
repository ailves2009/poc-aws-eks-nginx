data "aws_region" "current" {}

locals {
  aws_region = var.region != "" ? var.region : data.aws_region.current.id
  vpce_whitelist_arnlike = [for arn in var.vpce_whitelisted_principals : (
    can(regex("^arn:aws:iam::[0-9]+:role/.+", arn))
    ? format("%s/*", replace(replace(arn, "arn:aws:iam::", "arn:aws:sts::"), "role/", "assumed-role/"))
    : arn
  )]
}

resource "aws_vpc_endpoint" "s3" {
  count             = var.create_vpc_endpoint ? 1 : 0
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${local.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids
  tags              = merge(var.tags, { Name = "s3-gateway-endpoint-${var.bucket_name}" })
}

resource "aws_s3_bucket_policy" "restrict_to_vpce" {
  count  = var.restrict_to_vpc_endpoint && var.create_vpc_endpoint ? 1 : 0
  bucket = var.bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Allow whitelisted principals
      length(var.vpce_whitelisted_principals) > 0 ? [
        {
          Sid       = "AllowWhitelistedPrincipals"
          Effect    = "Allow"
          Principal = { AWS = var.vpce_whitelisted_principals }
          Action    = "s3:*"
          Resource = [
            "arn:aws:s3:::${var.bucket_name}",
            "arn:aws:s3:::${var.bucket_name}/*"
          ]
        }
      ] : [],

        # Additional policy statements provided by other modules (e.g. CloudFront OAC)
        length(var.additional_policy_statements) > 0 ? var.additional_policy_statements : [],

        # Allow CloudFront OAC access (legacy/fallback)
        var.allow_cloudfront_access && var.cloudfront_distribution_arn != "" ? [
          {
            Sid       = "AllowCloudFrontServicePrincipal"
            Effect    = "Allow"
            Principal = { Service = "cloudfront.amazonaws.com" }
            Action    = "s3:GetObject"
            Resource  = "arn:aws:s3:::${var.bucket_name}/*"
            Condition = { StringEquals = { "AWS:SourceArn" = var.cloudfront_distribution_arn } }
          }
        ] : [],

      # Deny non-VPCE except whitelist and CloudFront
      var.allow_cloudfront_access && var.cloudfront_deny_non_vpce_except_whitelisted_and_cloudfront ? [
        {
          Sid       = "DenyNonVPCEExceptWhitelistedAndCloudFront"
          Effect    = "Deny"
          Principal = "*"
          Action    = "s3:*"
          Resource = [
            "arn:aws:s3:::${var.bucket_name}",
            "arn:aws:s3:::${var.bucket_name}/*"
          ]
          Condition = merge(
            var.create_vpc_endpoint ? { StringNotEquals = { "aws:sourceVpce" = try([aws_vpc_endpoint.s3[0].id], []) } } : {},
            length(local.vpce_whitelist_arnlike) > 0 ? { ArnNotLike = { "aws:PrincipalArn" = local.vpce_whitelist_arnlike } } : {},
            var.allow_cloudfront_access && var.cloudfront_distribution_arn != "" ? { StringNotEqualsIfExists = { "AWS:SourceArn" = [var.cloudfront_distribution_arn] } } : {}
          )
        }
      ] : []
    )
  })
}
