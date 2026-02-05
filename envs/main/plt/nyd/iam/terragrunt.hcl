# /envs/main/plt/tst/iam/terragrunt.hcl

terraform {
  source = "../../../../../modules/iam"
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
    bucket         = "tst-plt-terraform-state"
    key            = "iam/terraform.tfstate"
    region         = "eu-west-3"
    use_lockfile   = true
    encrypt        = true
  }
}
EOF
}


inputs = {
  cicd_role_name    = "deploy-role"
  cicd_account_arn  = "arn:aws:iam::470201305353:user/terraform"

  s3_jetsons_logs   = "tst-plt-logs"
}
