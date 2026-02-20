# /modules/acm/outputs.tf

output "wildcard_certificate_arn" {
  value = aws_acm_certificate.wildcard.arn
  # arn:aws:acm:eu-west-3:470201305353:certificate/3bd88e8d-fb4a-497d-a065-adc818494dcb
  # *.poc-plt.ailves.xyz
}

output "cloudfront_certificate_arn" {
  description = "ARN of the CloudFront certificate in us-east-1"
  value       = var.create_cloudfront_certificate ? aws_acm_certificate.cloudfront_wildcard[0].arn : null
  # data.poc-plt.ailves.xyz
}

# Monitoring outputs
output "cloudwatch_alarm_arn" {
  description = "ARN of the CloudWatch alarm for certificate expiry"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.certificate_expiry[0].arn : null
  # arn:aws:cloudwatch:eu-west-3:470201305353:alarm:acm-certificate-expiry-poc-plt-ailves-xyz
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for certificate alerts"
  value       = var.create_sns_topic && length(var.alarm_email) > 0 ? aws_sns_topic.certificate_alerts[0].arn : null
  # arn:aws:sns:eu-west-3:470201305353:acm-certificates
}

output "dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = var.enable_monitoring ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.id}#dashboards:name=${aws_cloudwatch_dashboard.certificate_monitoring[0].dashboard_name}" : null
  # https://console.aws.amazon.com/cloudwatch/home?region=eu-west-3#dashboards:name=acm-certificates-poc-plt-ailves-xyz
}

output "aws_cloudwatch_metric_alarm-certificate_critical_expiry" {
  description = "CloudWatch alarm for critical certificate expiry"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.certificate_critical_expiry[0].alarm_actions : null
  # arn:aws:sns:eu-west-3:470201305353:acm-certificates
}
