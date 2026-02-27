# /envs/main/plt/poc/monitoring/terragrunt.hcl

terraform {
  source = "../../../../../modules/monitoring"
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
    key            = "monitoring/terraform.tfstate"
    region         = "eu-west-3"
    use_lockfile   = true
    encrypt        = true
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

dependency "eks" {
    config_path = "../eks"
    mock_outputs = {
      eks_managed_node_groups_autoscaling_group_names = "mock_asg"
    }
}

inputs = {
    asg_names = dependency.eks.outputs.eks_managed_node_groups_autoscaling_group_names
}
