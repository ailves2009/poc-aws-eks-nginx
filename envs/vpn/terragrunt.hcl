# /envs/main/plt/poc/vpn/terragrunt.hcl

terraform {
  source = "../../../../../modules/vpn"
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
    bucket         = "poc-plt-terraform-state"
    key            = "vpn/terraform.tfstate"
    region         = "eu-west-3"
    use_lockfile   = true
    encrypt        = true
  }
}
EOF
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id                   = "mock-vpc-id"
    private_subnet_ids       = ["mock-subnet-1", "mock-subnet-2"]
    private_route_table_ids  = ["mock-route-table-1"]
  }
}

dependency "acm" {
  config_path = "../acm"

  mock_outputs = {
    certificate_arn  = ["mock-certificate_arn"]
  }
}

dependency "key_pair" {
  config_path = "../key-pair"

  mock_outputs = {
    key_pair_name = "mock-vpn-key"
  }
}

inputs = {
  client                      = "mbta"
  env                         = "plt"
  enable_openvpn_ec2          = true
  ami_id                      = "ami-0f5fcdfbd140e4ab7" # Ubuntu for self-managed VPN
  instance_type               = "t3.small"              # Ubuntu for self-managed VPN

  public_subnet_ids           = dependency.vpc.outputs.public_subnet_ids

  key_pair_name               = dependency.key_pair.outputs.key_pair_name

  vpc_id                      = dependency.vpc.outputs.vpc_id
  vpc_cidr_block              = dependency.vpc.outputs.vpc_cidr_block

  domain_name                 = "vpn.mbta.echotwin.ai"
  hosted_zone_name            = "mbta.echotwin.ai"

  sg_name                     = "poc-eks-openvpn-sg"
  sg_description              = "SG for BMTA EC2 OpenVPN instance"
  sg_openvpn_port             = 443
  sg_ssh_port                  = 22

  tags = {
    Environment = "plt"
    Client      = "mbta"
    Managed     = "terraform"
    Purpose     = "client-vpn"
  }
}