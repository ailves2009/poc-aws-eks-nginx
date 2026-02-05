# modules/iam/guardduty.tf
# GuardDuty and security services permissions for CI/CD role

// deploy-security-policy for GuardDuty and related services
resource "aws_iam_policy" "deploy_security_policy" {
  name        = "${var.cicd_role_name}-GuardDuty-policy"
  description = "Security services permissions for CI/CD role (GuardDuty, SNS, EventBridge)"

  policy = data.aws_iam_policy_document.deploy_security_permissions.json
}

data "aws_iam_policy_document" "deploy_security_permissions" {
  statement {
    effect = "Allow"
    actions = [
      # GuardDuty permissions
      "guardduty:CreateDetector",
      "guardduty:GetDetector",
      "guardduty:UpdateDetector",
      "guardduty:DeleteDetector",
      "guardduty:ListDetectors",
      "guardduty:TagResource",
      "guardduty:UntagResource",
      "guardduty:ListTagsForResource",
      "guardduty:CreatePublishingDestination",
      "guardduty:UpdatePublishingDestination",
      "guardduty:DeletePublishingDestination",
      "guardduty:ListPublishingDestinations",
      "guardduty:DescribePublishingDestination",

      # EventBridge permissions for GuardDuty
      "events:PutRule",
      "events:DeleteRule",
      "events:DescribeRule",
      "events:ListRules",
      "events:PutTargets",
      "events:RemoveTargets",
      "events:ListTargetsByRule",
      "events:TagResource",
      "events:UntagResource",
      "events:ListTagsForResource",

      # SNS permissions for GuardDuty
      "sns:CreateTopic",
      "sns:DeleteTopic",
      "sns:GetTopicAttributes",
      "sns:SetTopicAttributes",
      "sns:Subscribe",
      "sns:Unsubscribe",
      "sns:ListTopics",
      "sns:ListSubscriptions",
      "sns:ListSubscriptionsByTopic",
      "sns:GetSubscriptionAttributes",
      "sns:SetSubscriptionAttributes",
      "sns:Publish",
      "sns:TagResource",
      "sns:UntagResource",
      "sns:ListTagsForResource",
      "sns:GetTopicPolicy",
      "sns:SetTopicPolicy",

      # Additional S3 permissions for GuardDuty
      "s3:PutLifecycleConfiguration",
      "s3:GetLifecycleConfiguration"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "deploy_assume_security_policy_attachment" {
  role       = data.aws_iam_role.cicd_role.name
  policy_arn = aws_iam_policy.deploy_security_policy.arn
}

data "aws_iam_role" "cicd_role" {
  name = var.cicd_role_name
}
