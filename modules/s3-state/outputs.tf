# /modules/s3-state/outputs.tf

output "s3_detection" {
  description = "S3 State Bucket name"
  value       = aws_s3_bucket.state_s3.id
}

output "region" {
  value = data.aws_region.current.region
}

output "account" {
  value = data.aws_caller_identity.current.account_id
}
