// modules/vpc/flowlogs.tf
// Create VPC Flow Logs for the module-created VPC and optionally for all VPCs in the account

// If create_for_all_vpcs is true, collect all VPC IDs using data.aws_vpcs
data "aws_vpcs" "all" {}

locals {
  module_vpc_id = module.vpc.vpc_id

  // list of VPC IDs to include: always include module vpc, and optionally include all account VPCs
  candidate_vpc_ids = var.create_for_all_vpcs ? distinct(concat([local.module_vpc_id], data.aws_vpcs.all.ids)) : [local.module_vpc_id]

  // deduplicate and convert to map for for_each
  vpc_ids = toset(local.candidate_vpc_ids)
  vpc_map = { for id in local.vpc_ids : id => id }

  // when flow logs are disabled, use empty map to skip creations
  flow_vpc_map = var.create_flow_logs ? local.vpc_map : {}
}

# Prepare a stable set for creating flow logs for all VPCs except the module-created one
locals {
  _all_except_module = toset([for id in data.aws_vpcs.all.ids : id if id != module.vpc.vpc_id])
  flow_for_each      = var.create_flow_logs && var.create_for_all_vpcs ? local._all_except_module : toset([])
}

resource "aws_iam_role" "vpc_flow_log_role" {
  count = var.create_flow_logs ? 1 : 0

  name = "${var.client}-${var.env}-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  count = var.create_flow_logs ? 1 : 0

  name = "${var.client}-${var.env}-vpc-flow-log-policy"
  role = aws_iam_role.vpc_flow_log_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

// CloudWatch Log Groups and Flow Logs per VPC (deduplicated)
# Явный лог-групп/flow-log для создаваемой модулем VPC
resource "aws_cloudwatch_log_group" "module_vpc_flow_log" {
  count             = var.create_flow_logs ? 1 : 0
  name              = "/aws/vpc-flow-logs/${module.vpc.vpc_id}"
  retention_in_days = var.cloudwatch_logs_retention_in_days
}

resource "aws_flow_log" "module_vpc" {
  count                = var.create_flow_logs ? 1 : 0
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.module_vpc_flow_log[0].arn
  iam_role_arn         = aws_iam_role.vpc_flow_log_role[0].arn
  vpc_id               = module.vpc.vpc_id
  traffic_type         = var.traffic_type

  tags = merge(var.tags, { Name = "${var.client}-${var.env}-flowlog-${module.vpc.vpc_id}" })
}

# Flow logs для всех VPC из data.aws_vpcs (только если включено)
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  for_each = local.flow_for_each

  name              = "/aws/vpc-flow-logs/${each.key}"
  retention_in_days = var.cloudwatch_logs_retention_in_days
}

resource "aws_flow_log" "vpc" {
  for_each = local.flow_for_each

  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs[each.key].arn
  iam_role_arn         = aws_iam_role.vpc_flow_log_role[0].arn
  vpc_id               = each.key
  traffic_type         = var.traffic_type

  tags = merge(var.tags, { Name = "${var.client}-${var.env}-flowlog-${each.key}" })
}
