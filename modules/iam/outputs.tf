# /modules/iam/outputs.tf

output "deploy_role_arn" {
  description = "ARN deploy-role"
  value       = data.aws_iam_role.cicd_role.arn
}

output "cloudwatch_logs_role_arn" {
  description = "ARN роли для логирования API Gateway в CloudWatch"
  value       = aws_iam_role.apigw_cloudwatch_logs.arn
}

output "apigw_s3_role_arn" {
  description = "Полный список зависимостей для API Gateway"
  value       = aws_iam_role.apigw_cloudwatch_logs.arn
}
