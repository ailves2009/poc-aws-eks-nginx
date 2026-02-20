# /envs/main/plt/poc/key-name/terragrunt.hcl

terraform {
  source = "../../../../../modules/key-name"
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
    key          = "key-name/terraform.tfstate"
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
  generate_key            = true
  write_private_key_file  = true
  key_name                = "5353-eu-west-3"
  private_key_path        = "/Users/alexanderilves/.ssh/ae/5353-eu-west-3.pem"
}
