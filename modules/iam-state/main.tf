# /modules/iamstate/main.tf

resource "aws_iam_role" "deploy_assume_role" {
  name               = var.cicd_role_name
  assume_role_policy = data.aws_iam_policy_document.deploy_assume_policy.json

  tags = var.tags
}

data "aws_iam_policy_document" "deploy_assume_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [var.cicd_account_arn]
    }
    actions = ["sts:AssumeRole"]
  }
}

// deploy-core-policy
resource "aws_iam_policy" "deploy_core_policy" {
  name        = "${var.cicd_role_name}-core-policy"
  description = "Core permissions for CI/CD role"

  policy = data.aws_iam_policy_document.deploy_core_permissions.json
}
data "aws_iam_policy_document" "deploy_core_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "eks:CreateNodegroup",
      "eks:DescribeNodegroup",
      "eks:DeleteNodegroup",
      "eks:DescribeCluster"
    ]
    resources = [
      "arn:aws:eks:${var.region}:${var.account}:cluster/${var.env}-${var.client}-eks"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:UpdateAssumeRolePolicy"
    ]
    resources = [
      "arn:aws:iam::${var.account}:role/eks-irsa-app-role",
      "arn:aws:iam::${var.account}:role/rds-app-access-role",
      "arn:aws:sts::${var.account}:role/cicd-role",
      "arn:aws:iam::${var.account}:role/aws-load-balancer-controller-role"

    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:UpdateAlias"
    ]
    resources = [
      "arn:aws:kms:${var.region}:${var.account}:alias/eks/${var.env}-${var.client}-eks"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:DescribeImages",
      "ecr:CreateRepository",
      "ecr:GetAuthorizationToken",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchCheckLayerAvailability"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:CreateHostedZone",
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:DeleteHostedZone",
      "route53:GetChange",
      "route53:ListTagsForResource",
      "route53:ChangeTagsForResource"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "deploy_assume_core_policy_attachment" {
  role       = aws_iam_role.deploy_assume_role.name
  policy_arn = aws_iam_policy.deploy_core_policy.arn
}

// deploy-infra-policy
resource "aws_iam_policy" "deploy_infra_policy" {
  name        = "${var.cicd_role_name}-infra-policy"
  description = "Infra permissions for CI/CD role"

  policy = data.aws_iam_policy_document.deploy_infra_permissions.json
}

data "aws_iam_policy_document" "deploy_infra_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "kms:TagResource",
      "kms:ScheduleKeyDeletion",
      "kms:ListResourceTags",
      "kms:GetKeyRotationStatus",
      "kms:GetKeyPolicy",
      "kms:EnableKeyRotation",
      "kms:DescribeKey",
      "kms:CreateKey",
      "kms:CreateAlias",
      "kms:ListAliases",
      "kms:DeleteAlias",
      "kms:PutKeyPolicy",

      "iam:TagRole",
      "iam:PassRole",
      "iam:ListRolePolicies",
      "iam:ListPolicyVersions",
      "iam:ListInstanceProfilesForRole",
      "iam:ListAttachedRolePolicies",
      "iam:GetRole",
      "iam:GetPolicyVersion",
      "iam:GetPolicy",
      "iam:DeleteRole",
      "iam:DeletePolicy",
      "iam:CreateRole",
      "iam:CreatePolicy",
      "iam:AttachRolePolicy",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:CreateServiceLinkedRole",

      "iam:CreateOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider",
      "iam:UntagOpenIDConnectProvider",
      "iam:GetOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint",
      "iam:ListOpenIDConnectProviders",

      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:TagPolicy",
      "iam:UntagRole",
      "iam:UntagPolicy",
      "iam:UntagRole",
      "iam:GetGroup",
      "iam:GetGroupPolicy",

      "eks:*",

      "ec2:*", # !!!!
      "ec2:CreateVpc",
      "ec2:DescribeVpcs",
      "ec2:DeleteVpc",
      "ec2:CreateTags",
      "ec2:DescribeTags",
      "ec2:DescribeVpcAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:DescribeAvailabilityZones",
      "ec2:CreateSubnet",
      "ec2:DescribeSubnets",
      "ec2:DeleteSubnet",
      "ec2:CreateRouteTable",
      "ec2:DescribeRouteTables",
      "ec2:DeleteRouteTable",
      "ec2:AssociateRouteTable",
      "ec2:DisassociateRouteTable",
      "ec2:CreateRoute",
      "ec2:ReplaceRoute",
      "ec2:DeleteRoute",
      "ec2:CreateInternetGateway",
      "ec2:DescribeInternetGateways",
      "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",
      "ec2:CreateNatGateway",
      "ec2:DescribeNatGateways",
      "ec2:DeleteNatGateway",
      "ec2:AllocateAddress",
      "ec2:ReleaseAddress",
      "ec2:DescribeAddresses",
      "ec2:DescribeSecurityGroups",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:DescribeAddressesAttribute",
      "ec2:DescribeSecurityGroupRules",
      "ec2:CreateLaunchTemplate",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:RunInstances",
      "ec2:CreateLaunchTemplate",
      "ec2:DeleteLaunchTemplate",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DisassociateAddress",
      "ec2:AssociateAddress",

      #for apigateway
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpcEndpointServices",
      "ec2:CreateVpcEndpointServiceConfiguration",
      "ec2:DeleteVpcEndpointServiceConfigurations",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeTargetGroups",

      "logs:CreateLogGroup",
      "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy",
      "logs:DeleteLogGroup",
      "logs:TagResource",
      "logs:ListTagsForResource",
      "logs:CreateLogDelivery",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutResourcePolicy",
      "logs:*",

      "secretsmanager:CreateSecret",
      "secretsmanager:PutSecretValue",
      "secretsmanager:DeleteSecret",
      "secretsmanager:TagResource",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
      "secretsmanager:GetResourcePolicy",

      "acm-pca:PutPolicy",
      "acm-pca:GetPolicy",
      "acm-pca:DeletePolicy",
      "acm:RequestCertificate",
      "acm:DescribeCertificate",
      "acm:DeleteCertificate",
      "acm:AddTagsToCertificate",
      "acm:ListCertificates",
      "acm:ListTagsForCertificate",
      "acm-pca:CreateCertificateAuthority",
      "acm-pca:TagCertificateAuthority",
      "acm-pca:DescribeCertificateAuthority",
      "acm-pca:GetCertificate",
      "acm-pca:GetCertificateAuthority",
      "acm-pca:GetCertificateAuthorityCertificate",
      "acm-pca:GetCertificateAuthorityCsr",
      "acm-pca:ListTags",
      "acm:ImportCertificate",
      "acm-pca:UpdateCertificateAuthority",
      "acm-pca:DeleteCertificateAuthority",
      "acm-pca:ListCertificateAuthorities",
      "acm-pca:ImportCertificateAuthorityCertificate",
      "acm-pca:IssueCertificate",
      "acm-pca:RevokeCertificate",
      "acm-pca:UntagCertificateAuthority",
      "acm-pca:ListTagsForResource",
      "acm-pca:CreatePermission",
      "acm-pca:DeletePermission",
      "acm-pca:ListPermissions",

      "elasticloadbalancing:*",

      "cloudwatch:PutMetricAlarm",
      "cloudwatch:PutDashboard",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:GetDashboard",
      "cloudwatch:ListTagsForResource",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DeleteDashboards",
      "cloudwatch:TagResource"
    ]

    resources = ["*"] # tbd конкретные ресурсы
  }
}

resource "aws_iam_role_policy_attachment" "deploy_assume_infra_policy_attachment" {
  role       = aws_iam_role.deploy_assume_role.name
  policy_arn = aws_iam_policy.deploy_infra_policy.arn
}
