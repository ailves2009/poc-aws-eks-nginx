# modules/iam/rds_monitoring.tf
# IAM policies for RDS CloudWatch monitoring and SNS notifications

# Policy for CICD role to manage RDS monitoring resources
resource "aws_iam_role_policy" "cicd_rds_monitoring_policy" {
  name = "${var.cicd_role_name}-rds-monitoring-policy"
  role = "deploy-role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "SNSManagement",
        Effect = "Allow",
        Action = [
          "sns:CreateTopic",
          "sns:DeleteTopic",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:ListTopics",
          "sns:Subscribe",
          "sns:Unsubscribe",
          "sns:ListSubscriptions",
          "sns:ListSubscriptionsByTopic",
          "sns:GetSubscriptionAttributes",
          "sns:SetSubscriptionAttributes",
          "sns:Publish",
          "sns:TagResource",
          "sns:UntagResource",
          "sns:ListTagsForResource"
        ],
        Resource = [
          "arn:aws:sns:*:${var.account}:*rds*",
          "arn:aws:sns:*:${var.account}:${var.client}-*"
        ]
      },
      {
        Sid    = "CloudWatchAlarmsManagement",
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:EnableAlarmActions",
          "cloudwatch:DisableAlarmActions",
          "cloudwatch:SetAlarmState",
          "cloudwatch:TagResource",
          "cloudwatch:UntagResource",
          "cloudwatch:ListTagsForResource"
        ],
        Resource = [
          "arn:aws:cloudwatch:*:${var.account}:alarm:*rds*",
          "arn:aws:cloudwatch:*:${var.account}:alarm:${var.client}-*"
        ]
      },
      {
        Sid    = "CloudWatchMetricsAccess",
        Effect = "Allow",
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "cloudwatch:PutMetricData"
        ],
        Resource = "*"
      },
      {
        Sid    = "RDSMonitoringAccess",
        Effect = "Allow",
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBSubnetGroups",
          "rds:DescribeDBParameterGroups",
          "rds:DescribeDBClusterParameterGroups",
          "rds:DescribeDBSnapshots",
          "rds:DescribeDBClusterSnapshots",
          "rds:DescribeEvents",
          "rds:DescribeEventCategories",
          "rds:DescribeEventSubscriptions",
          "rds:ListTagsForResource",
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource"
        ],
        Resource = "*"
      },
      {
        Sid    = "IAMPassRoleForRDSMonitoring",
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = [
          "arn:aws:iam::${var.account}:role/rds-monitoring-role"
        ],
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "monitoring.rds.amazonaws.com"
          }
        }
      }
    ]
  })
}
