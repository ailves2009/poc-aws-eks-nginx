# /modules/iam/outputs.tf

output "cloudwatch_logs_role_arn" {
  description = "ARN роли для логирования API Gateway в CloudWatch"
  value       = aws_iam_role.apigw_cloudwatch_logs.arn
}
