# /modules/sqs/monitoring.tf

# CloudWatch Monitoring for SQS
locals {
  queue_arns = [
    "arn:aws:sqs:${var.region}:${var.account}:${var.queue_name}",
    "arn:aws:sqs:${var.region}:${var.account}:${var.dlq_name}"
  ]

  queue_names = [for arn in local.queue_arns : reverse(split(":", arn))[0]]
}

# Create CloudWatch alarms for each SQS queue
resource "aws_cloudwatch_metric_alarm" "sqs_main_message_age_alarm" {
  alarm_name          = "${var.queue_name}-message-age-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 3600 # 1 hour in seconds, adjust as needed
  alarm_description   = "Alarm when the oldest message in the queue exceeds 1 hour"
  alarm_actions       = [aws_sns_topic.sqs_alarms.arn]

  dimensions = {
    QueueName = var.queue_name
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_dlq_message_age_alarm" {
  alarm_name          = "${var.dlq_name}-message-age-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 3600 # 1 hour in seconds, adjust as needed
  alarm_description   = "Alarm when the oldest message in the queue exceeds 1 hour"
  alarm_actions       = [aws_sns_topic.sqs_alarms.arn]

  dimensions = {
    QueueName = var.dlq_name
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_main_messages_high" {
  alarm_name          = "${var.queue_name}-messages-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "Main SQS queue has more than 100 visible messages (possible backlog)"
  dimensions = {
    QueueName = var.queue_name
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_messages_high" {
  alarm_name          = "${var.dlq_name}-messages-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "Main SQS queue has more than 100 visible messages (possible backlog)"
  dimensions = {
    QueueName = var.dlq_name
  }
}

resource "aws_cloudwatch_metric_alarm" "main_messages_delayed" {
  alarm_name          = "${var.queue_name}-messages-delayed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesDelayed"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 10
  alarm_description   = "Main SQS queue has more than 10 delayed messages"
  dimensions = {
    QueueName = var.queue_name
  }
  alarm_actions = [aws_sns_topic.sqs_alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages_delayed" {
  alarm_name          = "${var.dlq_name}-messages-delayed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesDelayed"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "DLQ has more than 1 delayed message"
  dimensions = {
    QueueName = var.dlq_name
  }
  alarm_actions = [aws_sns_topic.sqs_alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "sqs_main_messages_not_visible" {
  alarm_name          = "${var.queue_name}-messages-not-visible"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesNotVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "Main SQS queue has more than 50 messages in flight (not visible)"
  dimensions = {
    QueueName = var.queue_name
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_dlq_messages_not_visible" {
  alarm_name          = "${var.dlq_name}-messages-not-visible"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesNotVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "Main SQS queue has more than 50 messages in flight (not visible)"
  dimensions = {
    QueueName = var.dlq_name
  }
}

resource "aws_cloudwatch_dashboard" "sqs_dashboard" {
  dashboard_name = "sqs-queues-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.queue_name],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.dlq_name],
            ["AWS/SQS", "ApproximateNumberOfMessagesDelayed", "QueueName", var.queue_name],
            ["AWS/SQS", "ApproximateNumberOfMessagesNotVisible", "QueueName", var.queue_name]
          ]
          period = 300
          stat   = "Average"
          title  = "SQS Queue Metrics"
          region = "${var.region}"
        }
      }
    ]
  })
}
