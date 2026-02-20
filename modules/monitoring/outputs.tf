// /modules/monitoring/outputs.tf

output "sns_topic_arn" {
  description = "ARN of the SNS topic used for CPU alarms"
  value       = aws_sns_topic.cpu_alarms.arn
}
