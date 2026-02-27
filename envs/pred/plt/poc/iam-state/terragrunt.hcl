# /envs/pred/plt/poc/iam/terragrunt.hcl

terraform {
  source = "../../../../../modules/iam-state"
}

include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  cicd_role_name      = "cicd-role"
  cicd_account_arn    = "arn:aws:iam::470201305353:user/terraform"
  cluster_name        = "poc-plt-eks"
  s3_terraform_state  = "poc-plt-terraform-state"
}