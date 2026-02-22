# /modules/iam/outputs.tf

output "apigw_cloudwatch_logs_role_arn" {
  description = "ARN role for logging API Gateway to CloudWatch"
  value       = aws_iam_role.apigw_cloudwatch_logs.arn
}

output "deploy_role_arn" {
  description = "ARN role for CI/CD"
  value       = data.aws_iam_role.cicd_role.arn
}
