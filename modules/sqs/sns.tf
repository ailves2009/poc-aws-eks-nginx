# /modules/sqs/sns.tf

resource "aws_sns_topic_subscription" "alarms_email" {
  for_each  = toset(var.alarm_email)
  topic_arn = aws_sns_topic.sqs_alarms.arn
  protocol  = "email"
  endpoint  = each.value
}

# Create an SNS topic for alarm notifications
resource "aws_sns_topic" "sqs_alarms" {
  name = "sqs-message-age-alarms"
}
