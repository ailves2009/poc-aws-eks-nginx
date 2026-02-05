# /envs/main/plt/tst/vpc/terragrunt.hcl

terraform {
  source = "../../../../../modules/vpc"
}

include {
  path = find_in_parent_folders("root.hcl")
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket       = "tst-plt-terraform-state"
    key          = "vpc/terraform.tfstate"
    region       = "eu-west-3"
    use_lockfile = true
    encrypt      = true
  }
}
EOF
}

generate "providers_version" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}
EOF
}

inputs = {
  # SOC2 Compliance: 365 days retention for audit logs
  cloudwatch_logs_retention_in_days = 365

  # Data events configuration
  enable_s3_data_events     = false  # Set to true if S3 data events needed (can be expensive)
  enable_lambda_data_events = true   # Lambda data events for security monitoring

  vpc_name           = "tst-plt-vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  vpn_client_cidr    = "10.53.0.0/16"
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  manage_default_network_acl = false

  # flowLogs
  create_flow_logs    = true
  create_for_all_vpcs = true
  traffic_type        = "ALL"
}
