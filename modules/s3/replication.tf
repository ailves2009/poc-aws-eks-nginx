
// modules/s3/replication.tf

# Produce policy statement objects for replication so caller (s3-binding) can merge them
locals {
  replication_policy_statements = var.replication_enabled && length(var.source_replication_role_arn) > 0 ? [
    {
      Sid    = "AllowReplicationFromSourceRole"
      Effect = "Allow"
      Principal = {
        AWS = var.source_replication_role_arn
      }
      Action = [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags",
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging",
        "s3:ObjectOwnerOverrideToBucketOwner"
      ]
      Resource = "arn:aws:s3:::${var.bucket_name}/*"
    },
    {
      Sid    = "AllowS3ServiceToWriteObjects"
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action = [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ]
      Resource = "arn:aws:s3:::${var.bucket_name}/*"
    }
  ] : []
}

output "replication_policy_statements" {
  description = "List of policy statement objects to allow cross-account S3 replication (empty list if disabled)"
  value       = local.replication_policy_statements
}

