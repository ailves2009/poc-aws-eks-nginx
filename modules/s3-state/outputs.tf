# /modules/s3-state/outputs.tf

output "s3_bucket_arn" {
  description = "S3 State Bucket name"
  value       = aws_s3_bucket.state_s3.arn
}

output "region" {
  value = data.aws_region.current.region
}

output "account" {
  value = data.aws_caller_identity.current.account_id
}
