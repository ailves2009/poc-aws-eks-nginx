# /envs/main/plt/poc/vpc/terragrunt.hcl

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
    bucket       = "poc-plt-terraform-state"
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
  vpc_name           = "dmt-prd-eks"
  vpc_cidr_block     = "10.0.0.0/16"
  
  private_subnet_names = ["Private Subnet One", "Private Subnet Two"]
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false
  
  enable_nat_gateway          = true
  single_nat_gateway          = true
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  cloudwatch_logs_retention_in_days = 365
}

