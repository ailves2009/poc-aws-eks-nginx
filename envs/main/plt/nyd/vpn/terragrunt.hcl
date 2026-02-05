# /envs/plt/tst/vpn/terragrunt.hcl

terraform {
  source = "../../../../../modules/vpn/self-managed"
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
    key          = "vpn/terraform.tfstate"
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
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0"
    }
  }
}
EOF
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id                   = "mock-vpc-id"
    private_subnet_ids       = ["mock-subnet-1", "mock-subnet-2"]
    public_subnet_ids       = ["mock-subnet-3", "mock-subnet-4"]
    # private_route_table_ids  = ["mock-route-table-1"]
  }
}

inputs = {
  # domain_name       = "tst-plt.echotwin.xyz" # добавить создание domain_name
  # ami_id                      = "ami-0f5ae67b6f35d7118" # Ubuntu for self-managed VPN


  instance_type               = "t3.micro"              # Ubuntu for self-managed VPN
  key_name                    = "5353-eu-west-3"
  generate_key                = "true"
  write_private_key_file      = "true"
  private_key_path            = "/Users/alexanderilves/.ssh/ae/5353-eu-west-3.pem"


  description             = "tstot Production VPN Endpoint"
  vpc_id                  = dependency.vpc.outputs.vpc_id
  vpc_cidr_block          = dependency.vpc.outputs.vpc_cidr_block

  public_subnet_ids       = dependency.vpc.outputs.public_subnet_ids
  private_route_table_ids = dependency.vpc.outputs.private_route_table_ids  # для добавления маршрута в vpn_client_cidr

  vpn_client_cidr         = "10.53.0.0/16"
  private_ip              = "10.0.4.110"    # OpenVPN reserved private IP"
  split_tunnel            = true
  dns_servers             = ["8.8.8.8", "1.1.1.1"]    # Публичные DNS серверы для тестирования вместо 10.20.0.2
  
  sg_name                     = "vpn_sg"
  sg_description              = "SG for tst EC2 OpenVPN instance"
  sg_openvpn_port             = 443
  sg_ssh_port                 = 22

  tags = {
    Environment = "plt"
    Client      = "tst"
    Managed     = "terraform"
    Purpose     = "openvpn"
    Created     = "vpn/self-managed-vpn.tf"
  }
}
