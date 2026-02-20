// /modules/monitoring/main.tf

resource "aws_sns_topic" "cpu_alarms" {
  name = var.sns_topic_name
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu_alarm" {
  for_each = toset(var.asg_names)

  alarm_name          = "high-cpu-usage-asg-${each.value}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors EC2 CPU utilization for ASG ${each.value}"
  dimensions = {
    AutoScalingGroupName = each.value
  }
  alarm_actions = [aws_sns_topic.cpu_alarms.arn]
}
# /modules/monitoring/main.tf
