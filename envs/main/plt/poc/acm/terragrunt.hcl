# /envs/main/plt/poc/acm/terragrunt.hcl

terraform {
  source = "../../../../../modules/acm"
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
    key            = "acm/terraform.tfstate"
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

inputs = {
  enable_monitoring       = true
  alarm_email             = ["ailves2009@gmail.com"]
  create_sns_topic        = true
  sns_topic_name          = "acm-certificates"
}